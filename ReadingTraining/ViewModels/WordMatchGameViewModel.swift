import Foundation

@MainActor
final class WordMatchGameViewModel: ObservableObject {
    enum RoundMode: Equatable {
        case random
        case alphabetical
    }

    @Published private(set) var words: [WordMatchPair]
    @Published private(set) var pictures: [WordMatchPair]
    @Published private var pictureIDByWordID: [WordMatchPair.ID: WordMatchPair.ID] = [:]
    @Published private(set) var selectedWordID: WordMatchPair.ID?
    @Published private(set) var selectedPictureID: WordMatchPair.ID?
    @Published private(set) var roundMode: RoundMode = .random
    @Published var isCelebrationPresented = false

    let allPairs: [WordMatchPair]
    private let roundSize: Int

    private var hasShownCelebration = false
    private static let russianLocale = Locale(identifier: "ru_RU")

    init(
        pairs: [WordMatchPair] = WordMatchLibrary.defaultPool(),
        roundSize: Int = 5,
        shuffleOnInit: Bool = true
    ) {
        allPairs = pairs
        self.roundSize = max(1, roundSize)

        let initialPairs = Self.buildRound(from: pairs, roundSize: self.roundSize, shuffleSource: shuffleOnInit)
        let initialWords = shuffleOnInit ? initialPairs.shuffled() : initialPairs
        words = initialWords
        pictures = shuffleOnInit
            ? Self.shuffledPairs(from: initialPairs, avoiding: initialWords.map(\.id))
            : initialPairs
    }

    var connections: [WordMatchConnection] {
        let wordOrder = Dictionary(uniqueKeysWithValues: words.enumerated().map { ($1.id, $0) })

        return pictureIDByWordID.map { wordID, pictureID in
            WordMatchConnection(
                wordID: wordID,
                pictureID: pictureID,
                isCorrect: wordID == pictureID
            )
        }
        .sorted { lhs, rhs in
            wordOrder[lhs.wordID, default: 0] < wordOrder[rhs.wordID, default: 0]
        }
    }

    var totalCount: Int {
        words.count
    }

    var correctConnectionsCount: Int {
        connections.filter(\.isCorrect).count
    }

    var isAlphabeticalRound: Bool {
        roundMode == .alphabetical
    }

    func selectWord(_ wordID: WordMatchPair.ID) {
        if let selectedPictureID {
            makeConnection(wordID: wordID, pictureID: selectedPictureID)
            return
        }

        if selectedWordID == wordID {
            selectedWordID = nil
            return
        }

        if pictureID(forWordID: wordID) != nil {
            removeConnection(forWordID: wordID)
        }

        selectedWordID = wordID
        selectedPictureID = nil
        isCelebrationPresented = false
    }

    func selectPicture(_ pictureID: WordMatchPair.ID) {
        if let selectedWordID {
            makeConnection(wordID: selectedWordID, pictureID: pictureID)
            return
        }

        if selectedPictureID == pictureID {
            selectedPictureID = nil
            return
        }

        if wordID(forPictureID: pictureID) != nil {
            removeConnection(forPictureID: pictureID)
        }

        selectedPictureID = pictureID
        selectedWordID = nil
        isCelebrationPresented = false
    }

    func startNewRound() {
        resetRoundState()
        roundMode = .random

        let nextPairs = Self.buildRound(from: allPairs, roundSize: roundSize, shuffleSource: true)
        let nextWords = nextPairs.shuffled()
        words = nextWords
        pictures = Self.shuffledPairs(from: nextPairs, avoiding: nextWords.map(\.id))
    }

    func startAlphabetRound() {
        resetRoundState()
        roundMode = .alphabetical

        let nextWords = Self.buildAlphabeticalRound(from: allPairs, roundSize: roundSize)
        words = nextWords
        pictures = Self.shuffledPairs(from: nextWords, avoiding: nextWords.map(\.id))
    }

    func dismissCelebration() {
        isCelebrationPresented = false
    }

    func cardState(forWordID wordID: WordMatchPair.ID) -> WordMatchCardState {
        if selectedWordID == wordID {
            return .selected
        }

        guard let pictureID = pictureID(forWordID: wordID) else {
            return .idle
        }

        return wordID == pictureID ? .correct : .incorrect
    }

    func cardState(forPictureID pictureID: WordMatchPair.ID) -> WordMatchCardState {
        if selectedPictureID == pictureID {
            return .selected
        }

        guard let wordID = wordID(forPictureID: pictureID) else {
            return .idle
        }

        return wordID == pictureID ? .correct : .incorrect
    }

    private func makeConnection(wordID: WordMatchPair.ID, pictureID: WordMatchPair.ID) {
        removeConnection(forWordID: wordID)
        removeConnection(forPictureID: pictureID)
        pictureIDByWordID[wordID] = pictureID
        selectedWordID = nil
        selectedPictureID = nil
        isCelebrationPresented = false
        checkForCompletion()
    }

    private func removeConnection(forWordID wordID: WordMatchPair.ID) {
        pictureIDByWordID.removeValue(forKey: wordID)
    }

    private func removeConnection(forPictureID pictureID: WordMatchPair.ID) {
        pictureIDByWordID = pictureIDByWordID.filter { $0.value != pictureID }
    }

    private func pictureID(forWordID wordID: WordMatchPair.ID) -> WordMatchPair.ID? {
        pictureIDByWordID[wordID]
    }

    private func wordID(forPictureID pictureID: WordMatchPair.ID) -> WordMatchPair.ID? {
        pictureIDByWordID.first(where: { $0.value == pictureID })?.key
    }

    private func resetRoundState() {
        pictureIDByWordID = [:]
        selectedWordID = nil
        selectedPictureID = nil
        isCelebrationPresented = false
        hasShownCelebration = false
    }

    private func checkForCompletion() {
        guard !hasShownCelebration else {
            return
        }

        guard totalCount > 0 else {
            return
        }

        guard connections.count == totalCount, correctConnectionsCount == totalCount else {
            return
        }

        hasShownCelebration = true
        isCelebrationPresented = true
    }

    private static func buildRound(
        from pairs: [WordMatchPair],
        roundSize: Int,
        shuffleSource: Bool
    ) -> [WordMatchPair] {
        guard !pairs.isEmpty else {
            return []
        }

        let source = shuffleSource ? pairs.shuffled() : pairs
        return Array(source.prefix(min(roundSize, source.count)))
    }

    private static func buildAlphabeticalRound(
        from pairs: [WordMatchPair],
        roundSize: Int
    ) -> [WordMatchPair] {
        guard !pairs.isEmpty else {
            return []
        }

        let sortedPairs = pairs.sorted { lhs, rhs in
            let comparison = lhs.word.compare(
                rhs.word,
                options: [.caseInsensitive],
                range: nil,
                locale: russianLocale
            )

            if comparison == .orderedSame {
                return lhs.id.uuidString < rhs.id.uuidString
            }

            return comparison == .orderedAscending
        }

        let limitedSize = min(roundSize, sortedPairs.count)
        guard sortedPairs.count > limitedSize else {
            return Array(sortedPairs.prefix(limitedSize))
        }

        let startIndex = Int.random(in: 0...(sortedPairs.count - limitedSize))
        let endIndex = startIndex + limitedSize
        return Array(sortedPairs[startIndex..<endIndex])
    }

    private static func shuffledPairs(
        from pairs: [WordMatchPair],
        avoiding referenceOrder: [WordMatchPair.ID]
    ) -> [WordMatchPair] {
        guard pairs.count > 1 else {
            return pairs
        }

        for _ in 0..<12 {
            let shuffled = pairs.shuffled()
            if shuffled.map(\.id) != referenceOrder {
                return shuffled
            }
        }

        return Array(pairs.reversed())
    }
}
