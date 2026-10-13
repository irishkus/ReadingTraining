import Foundation

struct WordBuilderLetter: Identifiable, Equatable {
    let id = UUID()
    let value: String
    var isUsed = false

    init(value: String) {
        self.value = value
    }
}

@MainActor
final class WordBuilderViewModel: ObservableObject {
    @Published private(set) var currentPair: WordMatchPair
    @Published private(set) var letters: [String?]
    @Published private(set) var availableLetters: [WordBuilderLetter]
    @Published private(set) var isIncorrect = false
    @Published var isCelebrationPresented = false

    private let pairs: [WordMatchPair]
    private let randomIndex: (Int) -> Int
    private var slotLetterIDs: [WordBuilderLetter.ID?]

    init(
        pairs: [WordMatchPair] = WordMatchLibrary.wordBuildingPool(),
        randomIndex: @escaping (Int) -> Int = { Int.random(in: 0..<$0) }
    ) {
        let availablePairs = pairs.isEmpty ? WordMatchLibrary.primerSet : pairs
        self.pairs = availablePairs
        self.randomIndex = randomIndex

        let initialIndex = min(max(randomIndex(availablePairs.count), 0), availablePairs.count - 1)
        let initialPair = availablePairs[initialIndex]
        currentPair = initialPair
        letters = Array(repeating: nil, count: initialPair.word.count)
        slotLetterIDs = Array(repeating: nil, count: initialPair.word.count)
        availableLetters = Self.makeAvailableLetters(
            for: initialPair.word,
            randomIndex: randomIndex
        )
    }

    var isComplete: Bool {
        letters.allSatisfy { $0 != nil }
    }

    var enteredWord: String {
        letters.compactMap { $0 }.joined()
    }

    func useLetter(_ letter: WordBuilderLetter) {
        guard
            let slotIndex = letters.firstIndex(where: { $0 == nil }),
            let letterIndex = availableLetters.firstIndex(where: { $0.id == letter.id && !$0.isUsed })
        else { return }

        letters[slotIndex] = letter.value
        slotLetterIDs[slotIndex] = letter.id
        availableLetters[letterIndex].isUsed = true
        isIncorrect = false
    }

    func returnLetter(at index: Int) {
        guard
            letters.indices.contains(index),
            letters[index] != nil,
            let letterID = slotLetterIDs[index],
            let letterIndex = availableLetters.firstIndex(where: { $0.id == letterID })
        else { return }

        letters[index] = nil
        slotLetterIDs[index] = nil
        availableLetters[letterIndex].isUsed = false
        isIncorrect = false
    }

    func checkAnswer() {
        guard isComplete else { return }

        if enteredWord == currentPair.word {
            isIncorrect = false
            isCelebrationPresented = true
        } else {
            isIncorrect = true
        }
    }

    func showAnotherPicture() {
        guard pairs.count > 1 else {
            resetLetters()
            return
        }

        let alternatives = pairs.filter { $0.id != currentPair.id }
        let index = min(max(randomIndex(alternatives.count), 0), alternatives.count - 1)
        currentPair = alternatives[index]
        resetLetters()
    }

    func continueAfterCelebration() {
        isCelebrationPresented = false
        showAnotherPicture()
    }

    private func resetLetters() {
        letters = Array(repeating: nil, count: currentPair.word.count)
        slotLetterIDs = Array(repeating: nil, count: currentPair.word.count)
        availableLetters = Self.makeAvailableLetters(
            for: currentPair.word,
            randomIndex: randomIndex
        )
        isIncorrect = false
        isCelebrationPresented = false
    }

    private static func makeAvailableLetters(
        for word: String,
        randomIndex: (Int) -> Int
    ) -> [WordBuilderLetter] {
        let wordLetters = word.map(String.init)
        var distractorCandidates = RussianLetters.alphabet.filter { !wordLetters.contains($0) }
        var values = wordLetters

        for _ in 0..<min(5, distractorCandidates.count) {
            let index = boundedRandomIndex(randomIndex(distractorCandidates.count), upperBound: distractorCandidates.count)
            values.append(distractorCandidates.remove(at: index))
        }

        guard values.count > 1 else {
            return values.map(WordBuilderLetter.init(value:))
        }

        for index in stride(from: values.count - 1, through: 1, by: -1) {
            let swapIndex = boundedRandomIndex(randomIndex(index + 1), upperBound: index + 1)
            values.swapAt(index, swapIndex)
        }

        return values.map(WordBuilderLetter.init(value:))
    }

    private static func boundedRandomIndex(_ index: Int, upperBound: Int) -> Int {
        min(max(index, 0), upperBound - 1)
    }
}
