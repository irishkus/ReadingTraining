import XCTest
@testable import ReadingTraining

@MainActor
final class WordMatchGameViewModelTests: XCTestCase {
    func testDefaultRoundContainsFivePairs() {
        let viewModel = WordMatchGameViewModel(shuffleOnInit: false)

        XCTAssertEqual(viewModel.words.count, 5)
        XCTAssertEqual(viewModel.pictures.count, 5)
        XCTAssertEqual(viewModel.totalCount, 5)
    }

    func testCorrectMatchCreatesGreenConnection() {
        let viewModel = WordMatchGameViewModel(shuffleOnInit: false)
        let pair = viewModel.words[0]

        viewModel.selectWord(pair.id)
        viewModel.selectPicture(pair.id)

        XCTAssertEqual(viewModel.connections.count, 1)
        XCTAssertTrue(viewModel.connections[0].isCorrect)
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
        XCTAssertNil(viewModel.selectedWordID)
        XCTAssertNil(viewModel.selectedPictureID)
        XCTAssertFalse(viewModel.isCelebrationPresented)
    }
}
