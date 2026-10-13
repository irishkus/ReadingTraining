import Foundation

@MainActor
final class VowelFinderViewModel: ObservableObject {
    @Published private(set) var currentPair: WordMatchPair
    @Published private(set) var selectedIndices: Set<Int> = []
    @Published private(set) var confirmedVowelIndices: Set<Int> = []
    @Published private(set) var incorrectIndices: Set<Int> = []
    @Published var isCelebrationPresented = false

    private let pairs: [WordMatchPair]
    private let randomIndex: (Int) -> Int

    init(
        pairs: [WordMatchPair] = WordMatchLibrary.wordBuildingPool(),
        randomIndex: @escaping (Int) -> Int = { upperBound in
            ProcessInfo.processInfo.arguments.contains("UITestDeterministicVowels")
                ? 0
                : Int.random(in: 0..<upperBound)
        }
    ) {
        let availablePairs = pairs.isEmpty ? WordMatchLibrary.primerSet : pairs
        self.pairs = availablePairs
        self.randomIndex = randomIndex

        let index = Self.boundedIndex(randomIndex(availablePairs.count), count: availablePairs.count)
        currentPair = availablePairs[index]
    }

    var letters: [String] {
        currentPair.word.map(String.init)
    }

    var vowelIndices: Set<Int> {
        let vowels = Set(RussianLetters.vowels)
        return Set(letters.indices.filter { vowels.contains(letters[$0]) })
    }

    var canCheck: Bool {
        !selectedIndices.isEmpty
    }

    func toggleLetter(at index: Int) {
        guard letters.indices.contains(index), !confirmedVowelIndices.contains(index) else { return }

        if selectedIndices.contains(index) {
            selectedIndices.remove(index)
        } else {
            selectedIndices.insert(index)
        }
        incorrectIndices.remove(index)
    }

    func checkAnswer() {
        guard canCheck else { return }

        confirmedVowelIndices.formUnion(selectedIndices.intersection(vowelIndices))
        incorrectIndices = selectedIndices.subtracting(vowelIndices)

        if confirmedVowelIndices == vowelIndices && incorrectIndices.isEmpty {
            isCelebrationPresented = true
        }
    }

    func showAnotherWord() {
        guard pairs.count > 1 else {
            resetSelection()
            return
        }

        let alternatives = pairs.filter { $0.id != currentPair.id }
        let index = Self.boundedIndex(randomIndex(alternatives.count), count: alternatives.count)
        currentPair = alternatives[index]
        resetSelection()
    }

    func continueAfterCelebration() {
        isCelebrationPresented = false
        showAnotherWord()
    }

    private func resetSelection() {
        selectedIndices = []
        confirmedVowelIndices = []
        incorrectIndices = []
        isCelebrationPresented = false
    }

    private static func boundedIndex(_ index: Int, count: Int) -> Int {
        min(max(index, 0), count - 1)
    }
}
