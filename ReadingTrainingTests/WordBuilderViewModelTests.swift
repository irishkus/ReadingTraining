import XCTest
@testable import ReadingTraining

@MainActor
final class WordBuilderViewModelTests: XCTestCase {
    private let cat = WordMatchPair(key: "cat-test", word: "КОТ", illustration: .bundlePNG(name: "cat"))
    private let fox = WordMatchPair(key: "fox-test", word: "ЛИСА", illustration: .bundlePNG(name: "fox"))

    func testCreatesOneEmptySlotForEveryLetter() {
        let viewModel = makeViewModel()

        XCTAssertEqual(viewModel.currentPair.word, "КОТ")
        XCTAssertEqual(viewModel.letters.count, 3)
        XCTAssertTrue(viewModel.letters.allSatisfy { $0 == nil })
        XCTAssertEqual(viewModel.availableLetters.count, 8)
        XCTAssertTrue(containsLetters(of: "КОТ", in: viewModel.availableLetters))
    }

    func testUsingLetterFillsFirstEmptySlotAndRemovesChoice() {
        let viewModel = makeViewModel()
        let letter = choice("К", in: viewModel)

        viewModel.useLetter(letter)

        XCTAssertEqual(viewModel.letters, ["К", nil, nil])
        XCTAssertEqual(viewModel.availableLetters.count, 8)
        XCTAssertTrue(viewModel.availableLetters.first(where: { $0.id == letter.id })?.isUsed == true)
    }

    func testTappingFilledSlotReturnsLetterToChoices() {
        let viewModel = makeViewModel()
        viewModel.useLetter(choice("К", in: viewModel))

        viewModel.returnLetter(at: 0)

        XCTAssertNil(viewModel.letters[0])
        XCTAssertTrue(viewModel.availableLetters.contains { $0.value == "К" && !$0.isUsed })
    }

    func testCorrectWordPresentsCelebration() {
        let viewModel = makeViewModel()

        enter("КОТ", into: viewModel)
        viewModel.checkAnswer()

        XCTAssertTrue(viewModel.isCelebrationPresented)
        XCTAssertFalse(viewModel.isIncorrect)
    }

    func testWrongWordShowsErrorWithoutCelebration() {
        let viewModel = makeViewModel()

        viewModel.useLetter(choice("К", in: viewModel))
        viewModel.useLetter(choice("О", in: viewModel))
        viewModel.useLetter(choice("А", in: viewModel))
        viewModel.checkAnswer()

        XCTAssertTrue(viewModel.isIncorrect)
        XCTAssertFalse(viewModel.isCelebrationPresented)
    }

    func testAnotherPictureChangesPairAndClearsLetters() {
        let viewModel = makeViewModel()
        viewModel.useLetter(choice("К", in: viewModel))

        viewModel.showAnotherPicture()

        XCTAssertEqual(viewModel.currentPair.word, "ЛИСА")
        XCTAssertEqual(viewModel.letters.count, 4)
        XCTAssertTrue(viewModel.letters.allSatisfy { $0 == nil })
        XCTAssertEqual(viewModel.availableLetters.count, 9)
    }

    private func makeViewModel() -> WordBuilderViewModel {
        WordBuilderViewModel(pairs: [cat, fox], randomIndex: { _ in 0 })
    }

    private func enter(_ word: String, into viewModel: WordBuilderViewModel) {
        for letter in word {
            viewModel.useLetter(choice(String(letter), in: viewModel))
        }
    }

    private func choice(_ value: String, in viewModel: WordBuilderViewModel) -> WordBuilderLetter {
        guard let choice = viewModel.availableLetters.first(where: { $0.value == value && !$0.isUsed }) else {
            XCTFail("Нет буквы \(value) в наборе")
            return WordBuilderLetter(value: value)
        }
        return choice
    }

    private func containsLetters(of word: String, in choices: [WordBuilderLetter]) -> Bool {
        var available = choices.map(\.value)
        for letter in word.map(String.init) {
            guard let index = available.firstIndex(of: letter) else { return false }
            available.remove(at: index)
        }
        return true
    }
}
