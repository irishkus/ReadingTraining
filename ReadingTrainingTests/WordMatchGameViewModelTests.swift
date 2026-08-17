import XCTest
@testable import ReadingTraining

@MainActor
final class WordMatchGameViewModelTests: XCTestCase {
    func testDefaultRoundContainsFivePairs() {
        let viewModel = WordMatchGameViewModel(shuffleOnInit: false)

        XCTAssertEqual(viewModel.words.count, 5)
        XCTAssertEqual(viewModel.pictures.count, 5)
        XCTAssertEqual(viewModel.totalCount, 5)
        XCTAssertTrue(viewModel.isAlphabeticalRound)
        XCTAssertEqual(viewModel.words.map(\.word), viewModel.words.map(\.word).sorted())
    }

    func testCorrectMatchCreatesGreenConnection() {
        let viewModel = WordMatchGameViewModel(shuffleOnInit: false)
        let pair = viewModel.words[0]

        viewModel.selectWord(pair.id)
        viewModel.selectPicture(pair.id)

        XCTAssertEqual(viewModel.connections.count, 1)
        XCTAssertTrue(viewModel.connections[0].isCorrect)
        XCTAssertEqual(viewModel.errorCount, 0)
        XCTAssertEqual(viewModel.cardState(forWordID: pair.id), .correct)
        XCTAssertEqual(viewModel.cardState(forPictureID: pair.id), .correct)
    }

    func testIncorrectMatchCreatesRedConnection() {
        let viewModel = WordMatchGameViewModel(shuffleOnInit: false)
        let word = viewModel.words[0]
        let picture = viewModel.pictures[1]

        viewModel.selectWord(word.id)
        viewModel.selectPicture(picture.id)

        XCTAssertEqual(viewModel.connections.count, 1)
        XCTAssertFalse(viewModel.connections[0].isCorrect)
        XCTAssertEqual(viewModel.errorCount, 1)
        XCTAssertEqual(viewModel.cardState(forWordID: word.id), .incorrect)
        XCTAssertEqual(viewModel.cardState(forPictureID: picture.id), .incorrect)
    }

    func testTappingConnectedCardRemovesLineAndSelectsCardAgain() {
        let viewModel = WordMatchGameViewModel(shuffleOnInit: false)
        let word = viewModel.words[0]
        let picture = viewModel.pictures[1]

        viewModel.selectWord(word.id)
        viewModel.selectPicture(picture.id)
        viewModel.selectWord(word.id)

        XCTAssertTrue(viewModel.connections.isEmpty)
        XCTAssertEqual(viewModel.selectedWordID, word.id)
        XCTAssertNil(viewModel.selectedPictureID)
    }

    func testAllCorrectMatchesShowCelebration() {
        let viewModel = WordMatchGameViewModel(shuffleOnInit: false)

        for pair in viewModel.words {
            viewModel.selectWord(pair.id)
            viewModel.selectPicture(pair.id)
        }

        XCTAssertEqual(viewModel.correctConnectionsCount, viewModel.totalCount)
        XCTAssertTrue(viewModel.isCelebrationPresented)
    }

    func testStartNewRoundClearsConnectionsAndSelection() {
        let viewModel = WordMatchGameViewModel(shuffleOnInit: false)
        let pair = viewModel.words[0]

        viewModel.selectWord(pair.id)
        viewModel.selectPicture(pair.id)
        viewModel.startNewRound()

        XCTAssertTrue(viewModel.connections.isEmpty)
        XCTAssertEqual(viewModel.errorCount, 0)
        XCTAssertNil(viewModel.selectedWordID)
        XCTAssertNil(viewModel.selectedPictureID)
        XCTAssertFalse(viewModel.isCelebrationPresented)
    }

    func testAlphabetRoundSortsWordsAndKeepsSamePairs() {
        let pairs = [
            WordMatchPair(key: "owl", word: "СОВА", illustration: .bundlePNG(name: "owl")),
            WordMatchPair(key: "watermelon", word: "АРБУЗ", illustration: .bundlePNG(name: "watermelon")),
            WordMatchPair(key: "drum", word: "БАРАБАН", illustration: .bundlePNG(name: "drum")),
            WordMatchPair(key: "pear", word: "ГРУША", illustration: .bundlePNG(name: "pear")),
            WordMatchPair(key: "wolf", word: "ВОЛК", illustration: .bundlePNG(name: "wolf"))
        ]

        let viewModel = WordMatchGameViewModel(
            pairs: pairs,
            roundSize: pairs.count,
            shuffleOnInit: false
        )

        viewModel.startAlphabetRound()

        XCTAssertEqual(viewModel.words.map(\.word), ["АРБУЗ", "БАРАБАН", "ВОЛК", "ГРУША", "СОВА"])
        XCTAssertEqual(Set(viewModel.words.map(\.id)), Set(viewModel.pictures.map(\.id)))
        XCTAssertTrue(viewModel.isAlphabeticalRound)
    }

    func testAlphabetRoundResetsConnectionsAndSelection() {
        let viewModel = WordMatchGameViewModel(shuffleOnInit: false)
        let pair = viewModel.words[0]

        viewModel.selectWord(pair.id)
        viewModel.selectPicture(pair.id)
        viewModel.startAlphabetRound()

        XCTAssertTrue(viewModel.connections.isEmpty)
        XCTAssertNil(viewModel.selectedWordID)
        XCTAssertNil(viewModel.selectedPictureID)
        XCTAssertFalse(viewModel.isCelebrationPresented)
        XCTAssertTrue(viewModel.isAlphabeticalRound)
    }

    func testToggleAlphabeticalRoundSwitchesModes() {
        let viewModel = WordMatchGameViewModel(shuffleOnInit: false)

        XCTAssertTrue(viewModel.isAlphabeticalRound)

        viewModel.toggleAlphabeticalRound()
        XCTAssertFalse(viewModel.isAlphabeticalRound)

        viewModel.toggleAlphabeticalRound()
        XCTAssertTrue(viewModel.isAlphabeticalRound)
    }

    func testStartRandomRoundDisablesAlphabeticalMode() {
        let viewModel = WordMatchGameViewModel(shuffleOnInit: false)

        viewModel.startRandomRound()

        XCTAssertFalse(viewModel.isAlphabeticalRound)
    }

    func testNewRoundKeepsAlphabeticalModeActive() {
        let viewModel = WordMatchGameViewModel(shuffleOnInit: false)

        viewModel.startAlphabetRound()
        let firstAlphabeticalWords = viewModel.words.map(\.word)

        viewModel.startNewRound()

        XCTAssertTrue(viewModel.isAlphabeticalRound)
        XCTAssertEqual(viewModel.words.map(\.word), viewModel.words.map(\.word).sorted())
        XCTAssertEqual(viewModel.words.count, firstAlphabeticalWords.count)
    }

    func testNewRoundAfterCelebrationKeepsAlphabeticalModeActive() {
        let viewModel = WordMatchGameViewModel(shuffleOnInit: false)

        viewModel.startAlphabetRound()

        for pair in viewModel.words {
            viewModel.selectWord(pair.id)
            viewModel.selectPicture(pair.id)
        }

        XCTAssertTrue(viewModel.isCelebrationPresented)
        XCTAssertTrue(viewModel.isAlphabeticalRound)

        viewModel.startNewRound()

        XCTAssertFalse(viewModel.isCelebrationPresented)
        XCTAssertTrue(viewModel.isAlphabeticalRound)
        XCTAssertEqual(viewModel.words.map(\.word), viewModel.words.map(\.word).sorted())
    }

    func testSelectingConnectedPictureRemovesLineAndSelectsPictureAgain() {
        let viewModel = WordMatchGameViewModel(shuffleOnInit: false)
        let word = viewModel.words[0]
        let picture = viewModel.pictures[1]

        viewModel.selectWord(word.id)
        viewModel.selectPicture(picture.id)
        viewModel.selectPicture(picture.id)

        XCTAssertTrue(viewModel.connections.isEmpty)
        XCTAssertEqual(viewModel.errorCount, 1)
        XCTAssertNil(viewModel.selectedWordID)
        XCTAssertEqual(viewModel.selectedPictureID, picture.id)
    }

    func testSeventhErrorStartsNewRoundAndResetsCounter() {
        let viewModel = WordMatchGameViewModel(shuffleOnInit: false)
        let word = viewModel.words[0]
        let picture = viewModel.pictures[1]

        for _ in 1...viewModel.maximumMistakeCount {
            viewModel.selectWord(word.id)
            viewModel.selectPicture(picture.id)
        }

        XCTAssertEqual(viewModel.errorCount, 0)
        XCTAssertTrue(viewModel.connections.isEmpty)
        XCTAssertNil(viewModel.selectedWordID)
        XCTAssertNil(viewModel.selectedPictureID)
        XCTAssertFalse(viewModel.isCelebrationPresented)
    }

    func testSeventhErrorKeepsAlphabeticalModeActive() {
        let viewModel = WordMatchGameViewModel(shuffleOnInit: false)

        viewModel.startAlphabetRound()

        let word = viewModel.words[0]
        let picture = viewModel.pictures.first(where: { $0.id != word.id })!

        for _ in 1...viewModel.maximumMistakeCount {
            viewModel.selectWord(word.id)
            viewModel.selectPicture(picture.id)
        }

        XCTAssertTrue(viewModel.isAlphabeticalRound)
        XCTAssertEqual(viewModel.errorCount, 0)
        XCTAssertEqual(viewModel.words.map(\.word), viewModel.words.map(\.word).sorted())
    }
}
