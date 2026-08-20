import Foundation

enum ReadAloudCardState: Equatable {
    case idle
    case listening
    case completed
}

@MainActor
final class ReadAloudTrainerViewModel: ObservableObject {
    @Published private(set) var pairs: [WordMatchPair]
    @Published private(set) var activePairID: WordMatchPair.ID?
    @Published private(set) var completedPairIDs: Set<WordMatchPair.ID> = []
    @Published private(set) var isListening = false
    @Published private(set) var statusText: String
    @Published private(set) var recognizedText = ""
    @Published var celebrationPair: WordMatchPair?
    @Published var isRoundCelebrationPresented = false
    @Published private(set) var finalCelebrationPair: WordMatchPair?

    let allPairs: [WordMatchPair]

    private let speechRecognizer: any ReadAloudSpeechRecognizing
    private let roundSize: Int

    private var listeningSessionID = UUID()
    private var timeoutTask: Task<Void, Never>?

    init(
        pairs: [WordMatchPair] = WordMatchLibrary.readingPracticePool(),
        roundSize: Int = 6,
        speechRecognizer: any ReadAloudSpeechRecognizing = ReadAloudSpeechRecognizerFactory.makeRecognizer(),
        shuffleOnInit: Bool = true
    ) {
        allPairs = pairs.isEmpty ? WordMatchLibrary.primerSet : pairs
        self.roundSize = max(1, roundSize)
        self.speechRecognizer = speechRecognizer
        statusText = Self.defaultStatusText
        self.pairs = Self.buildRound(from: allPairs, roundSize: self.roundSize, shuffle: shuffleOnInit)
    }

    var totalCount: Int {
        pairs.count
    }

    var completedCount: Int {
        completedPairIDs.count
    }

    func selectPair(_ pair: WordMatchPair) {
        guard !completedPairIDs.contains(pair.id) else {
            return
        }

        guard celebrationPair == nil, !isRoundCelebrationPresented else {
            return
        }

        celebrationPair = nil

        if activePairID == pair.id, isListening {
            stopListening(
                statusMessage: Self.defaultStatusText,
                clearTranscript: true
            )
            return
        }

        beginListening(for: pair)
    }

    func startNewRound() {
        stopListening(statusMessage: nil, clearTranscript: true)
        completedPairIDs = []
        celebrationPair = nil
        finalCelebrationPair = nil
        isRoundCelebrationPresented = false
        pairs = Self.buildRound(from: allPairs, roundSize: roundSize, shuffle: true)
        statusText = Self.defaultStatusText
    }

    func dismissCelebration() {
        celebrationPair = nil
        statusText = completedCount == totalCount
            ? Self.defaultStatusText
            : "Верно! Выберите следующую коробку."
    }

    func dismissRoundCelebration() {
        isRoundCelebrationPresented = false
        finalCelebrationPair = nil
        statusText = Self.defaultStatusText
    }

    func cardState(for pairID: WordMatchPair.ID) -> ReadAloudCardState {
        if completedPairIDs.contains(pairID) {
            return .completed
        }

        if activePairID == pairID, isListening {
            return .listening
        }

        return .idle
    }

    private func beginListening(for pair: WordMatchPair) {
        stopListening(statusMessage: nil, clearTranscript: true)

        let sessionID = UUID()
        listeningSessionID = sessionID
        statusText = "Готовлю микрофон для слова «\(pair.word)»..."

        Task {
            let authorizationStatus = await speechRecognizer.requestAuthorization()

            guard listeningSessionID == sessionID else {
                return
            }

            switch authorizationStatus {
            case .authorized:
                startSpeechSession(for: pair, sessionID: sessionID)
            case .denied:
                statusText = "Разрешите доступ к микрофону и распознаванию речи в настройках."
            case .restricted:
                statusText = "На этом устройстве сейчас нельзя использовать распознавание речи."
            case .unsupported:
                statusText = "Распознавание русской речи здесь недоступно."
            }
        }
    }

    private func startSpeechSession(for pair: WordMatchPair, sessionID: UUID) {
        guard listeningSessionID == sessionID else {
            return
        }

        activePairID = pair.id
        isListening = true
        recognizedText = ""
        statusText = "Слушаю: прочитайте слово «\(pair.word)»"

        do {
            try speechRecognizer.startListening(expectedWord: pair.word) { [weak self] event in
                self?.handle(event, for: pair, sessionID: sessionID)
            }
            scheduleTimeout(for: pair, sessionID: sessionID)
        } catch {
            stopListening(
                statusMessage: error.localizedDescription,
                clearTranscript: true
            )
        }
    }

    private func handle(
        _ event: ReadAloudSpeechEvent,
        for pair: WordMatchPair,
        sessionID: UUID
    ) {
        guard listeningSessionID == sessionID else {
            return
        }

        switch event {
        case .started:
            return
        case let .transcript(text, isFinal):
            recognizedText = text

            if Self.transcript(text, matches: pair.word) {
                complete(pair)
                return
            }

            if isFinal {
                stopListening(
                    statusMessage: retryMessage(for: text),
                    clearTranscript: false
                )
            }
        case let .failure(message):
            stopListening(statusMessage: message, clearTranscript: false)
        }
    }

    private func complete(_ pair: WordMatchPair) {
        timeoutTask?.cancel()
        timeoutTask = nil

        listeningSessionID = UUID()
        speechRecognizer.stopListening()
        activePairID = nil
        isListening = false
        recognizedText = ""
        completedPairIDs.insert(pair.id)

        if completedPairIDs.count == pairs.count {
            finalCelebrationPair = pair
            isRoundCelebrationPresented = true
            celebrationPair = nil
            statusText = "Все коробки названы правильно!"
            return
        }

        statusText = "Молодец! Слово прочитано правильно."
        celebrationPair = pair
    }

    private func scheduleTimeout(for pair: WordMatchPair, sessionID: UUID) {
        timeoutTask?.cancel()
        timeoutTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 6_500_000_000)
            await self?.handleTimeout(for: pair, sessionID: sessionID)
        }
    }

    private func handleTimeout(for pair: WordMatchPair, sessionID: UUID) {
        guard listeningSessionID == sessionID, activePairID == pair.id, isListening else {
            return
        }

        stopListening(
            statusMessage: Self.defaultStatusText,
            clearTranscript: true
        )
    }

    private func stopListening(statusMessage: String?, clearTranscript: Bool) {
        listeningSessionID = UUID()
        timeoutTask?.cancel()
        timeoutTask = nil
        speechRecognizer.stopListening()
        activePairID = nil
        isListening = false

        if clearTranscript {
            recognizedText = ""
        }

        if let statusMessage {
            statusText = statusMessage
        }
    }

    private func retryMessage(for _: String) -> String {
        Self.defaultStatusText
    }

    private static func buildRound(from pairs: [WordMatchPair], roundSize: Int, shuffle: Bool) -> [WordMatchPair] {
        let source = shuffle ? pairs.shuffled() : pairs
        return Array(source.prefix(min(roundSize, source.count)))
    }

    private static func transcript(_ transcript: String, matches target: String) -> Bool {
        let normalizedTarget = normalizedTokens(from: target).joined(separator: " ")
        let transcriptTokens = normalizedTokens(from: transcript)

        if normalizedTarget.contains(" ") {
            return transcriptTokens.joined(separator: " ").contains(normalizedTarget)
        }

        return transcriptTokens.contains(normalizedTarget)
    }

    private static func normalizedTokens(from text: String) -> [String] {
        let lowercased = text.lowercased().replacingOccurrences(of: "ё", with: "е")
        let normalizedText = lowercased.unicodeScalars.map { scalar -> String in
            CharacterSet.letters.contains(scalar) || CharacterSet.whitespacesAndNewlines.contains(scalar)
                ? String(scalar)
                : " "
        }
        .joined()

        return normalizedText
            .split(whereSeparator: \.isWhitespace)
            .map(String.init)
    }

    private static let defaultStatusText = "Нажмите на коробку и прочитайте слово вслух."
}
