import Foundation

@MainActor
final class WordMatchGameViewModel: ObservableObject {
    @Published private(set) var words: [WordMatchPair]
    @Published private(set) var pictures: [WordMatchPair]
    @Published private var pictureIDByWordID: [WordMatchPair.ID: WordMatchPair.ID] = [:]
    @Published private(set) var selectedWordID: WordMatchPair.ID?
    @Published private(set) var selectedPictureID: WordMatchPair.ID?
    @Published var isCelebrationPresented = false

    let allPairs: [WordMatchPair]
    private let roundSize: Int

    private var hasShownCelebration = false

    init(
        pairs: [WordMatchPair] = WordMatchLibrary.defaultPool(),
        roundSize: Int = 5,
        shuffleOnInit: Bool = true
    ) {
        allPairs = pairs
        self.roundSize = max(1, roundSize)

        let initialPairs = Self.buildRound(from: pairs, roundSize: self.roundSize, shuffleSource: shuffleOnInit)
        words = shuffleOnInit ? initialPairs.shuffled() : initialPairs
        pictures = shuffleOnInit ? initialPairs.shuffled() : initialPairs
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
        pictureIDByWordID = [:]
        selectedWordID = nil
        selectedPictureID = nil
        isCelebrationPresented = false
        hasShownCelebration = false

        let nextPairs = Self.buildRound(from: allPairs, roundSize: roundSize, shuffleSource: true)
        words = nextPairs.shuffled()
        pictures = nextPairs.shuffled()
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
}
