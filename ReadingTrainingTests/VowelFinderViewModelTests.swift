import XCTest
@testable import ReadingTraining

@MainActor
final class VowelFinderViewModelTests: XCTestCase {
    private let cat = WordMatchPair(key: "cat-vowels", word: "КОТ", illustration: .bundlePNG(name: "cat"))
    private let hedgehog = WordMatchPair(key: "hedgehog-vowels", word: "ЁЖ", illustration: .bundlePNG(name: "hedgehog"))
    private let letters = WordMatchPair(key: "letters-vowels", word: "БУКВА", illustration: .bundlePNG(name: "book"))

    func testFindsVowelIndicesIncludingYo() {
        let viewModel = VowelFinderViewModel(pairs: [hedgehog], randomIndex: { _ in 0 })

        XCTAssertEqual(viewModel.vowelIndices, [0])
    }

    func testCorrectSelectedVowelBecomesConfirmed() {
        let viewModel = makeViewModel()
        viewModel.toggleLetter(at: 1)

        viewModel.checkAnswer()

        XCTAssertEqual(viewModel.confirmedVowelIndices, [1])
        XCTAssertTrue(viewModel.incorrectIndices.isEmpty)
        XCTAssertTrue(viewModel.isCelebrationPresented)
    }

    func testSelectedConsonantIsMarkedIncorrect() {
        let viewModel = makeViewModel()
        viewModel.toggleLetter(at: 0)

        viewModel.checkAnswer()

        XCTAssertEqual(viewModel.incorrectIndices, [0])
        XCTAssertFalse(viewModel.isCelebrationPresented)
    }

    func testOneOfSeveralVowelsIsConfirmedWithoutCompletingExercise() {
        let viewModel = VowelFinderViewModel(pairs: [letters], randomIndex: { _ in 0 })
        viewModel.toggleLetter(at: 1)

        viewModel.checkAnswer()

        XCTAssertEqual(viewModel.confirmedVowelIndices, [1])
        XCTAssertEqual(viewModel.vowelIndices, [1, 4])
        XCTAssertFalse(viewModel.isCelebrationPresented)
    }

    func testAnotherWordClearsSelection() {
        let viewModel = makeViewModel()
        viewModel.toggleLetter(at: 1)
        viewModel.checkAnswer()

        viewModel.showAnotherWord()

        XCTAssertEqual(viewModel.currentPair.word, "ЁЖ")
        XCTAssertTrue(viewModel.selectedIndices.isEmpty)
        XCTAssertTrue(viewModel.confirmedVowelIndices.isEmpty)
        XCTAssertFalse(viewModel.isCelebrationPresented)
    }

    private func makeViewModel() -> VowelFinderViewModel {
        VowelFinderViewModel(pairs: [cat, hedgehog], randomIndex: { _ in 0 })
    }
}
