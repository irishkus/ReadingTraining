import XCTest
@testable import ReadingTraining

@MainActor
final class SyllableTrainerViewModelTests: XCTestCase {
    func testDefaultStateStartsWithConsonantAndVowel() {
        let viewModel = SyllableTrainerViewModel()

        XCTAssertEqual(viewModel.selectedConsonant, "М")
        XCTAssertEqual(viewModel.selectedVowel, "А")
        XCTAssertTrue(viewModel.isConsonantLeading)
        XCTAssertEqual(viewModel.leftKind, .consonant)
        XCTAssertEqual(viewModel.rightKind, .vowel)
        XCTAssertEqual(viewModel.displayedLetter(for: .consonant), "М")
        XCTAssertEqual(viewModel.displayedLetter(for: .vowel), "А")
    }

    func testToggleOrderSwapsLeftAndRightKinds() {
        let viewModel = SyllableTrainerViewModel()

        viewModel.toggleOrder()

        XCTAssertFalse(viewModel.isConsonantLeading)
        XCTAssertEqual(viewModel.leftKind, .vowel)
        XCTAssertEqual(viewModel.rightKind, .consonant)
    }

    func testDisplayedLetterUsesSelectedCaseMode() {
        let viewModel = SyllableTrainerViewModel()
        viewModel.letterCaseMode = .lowercase

        XCTAssertEqual(viewModel.displayedLetter(for: .consonant), "м")
        XCTAssertEqual(viewModel.displayedLetter(for: .vowel), "а")
    }

    func testSelectUpdatesOnlyRequestedKind() {
        let viewModel = SyllableTrainerViewModel()

        viewModel.select("С", for: .consonant)

        XCTAssertEqual(viewModel.selectedConsonant, "С")
        XCTAssertEqual(viewModel.selectedVowel, "А")
    }

    func testRandomizeVowelChoosesDifferentValidVowel() {
        let viewModel = SyllableTrainerViewModel()
        let previousVowel = viewModel.selectedVowel

        viewModel.randomize(.vowel)

        XCTAssertTrue(RussianLetters.vowels.contains(viewModel.selectedVowel))
        XCTAssertNotEqual(viewModel.selectedVowel, previousVowel)
        XCTAssertEqual(viewModel.selectedConsonant, "М")
    }

    func testOpenAndClosePickerManagePickerContext() {
        let viewModel = SyllableTrainerViewModel()

        viewModel.openPicker(for: .consonant)
        XCTAssertEqual(viewModel.activePicker?.kind, .consonant)

        viewModel.closePicker()
        XCTAssertNil(viewModel.activePicker)
    }
}
