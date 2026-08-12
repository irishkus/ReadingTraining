import XCTest

final class ReadingTrainingUITests: XCTestCase {
    private let russianAlphabeticalOrder = [
        "БУЛКА",
        "БУСЫ",
        "ВЕДРО",
        "КУКЛА",
        "СУМКА"
    ]

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testLaunchShowsDefaultSyllable() throws {
        let app = XCUIApplication()
        app.launch()

        let leftLetter = app.buttons["syllable.leftLetter"]
        let rightLetter = app.buttons["syllable.rightLetter"]

        XCTAssertTrue(leftLetter.waitForExistence(timeout: 2))
        XCTAssertTrue(rightLetter.exists)
        XCTAssertEqual(leftLetter.label, "М")
        XCTAssertEqual(rightLetter.label, "А")
        XCTAssertTrue(app.buttons["action.swap"].exists)
    }

    func testSwapButtonChangesVisibleOrder() throws {
        let app = XCUIApplication()
        app.launch()

        app.buttons["action.swap"].tap()

        XCTAssertEqual(app.buttons["syllable.leftLetter"].label, "А")
        XCTAssertEqual(app.buttons["syllable.rightLetter"].label, "М")
    }

    func testLetterPickerChangesLeftLetter() throws {
        let app = XCUIApplication()
        app.launch()

        app.buttons["syllable.leftLetter"].tap()

        let pickerLetter = app.buttons["picker.letter.С"]
        XCTAssertTrue(pickerLetter.waitForExistence(timeout: 2))

        pickerLetter.tap()

        XCTAssertEqual(app.buttons["syllable.leftLetter"].label, "С")
    }

    func testLowercaseModeAndRandomButtonUpdateVisibleLetter() throws {
        let app = XCUIApplication()
        app.launch()

        app.segmentedControls.buttons["абв"].tap()

        let rightLetter = app.buttons["syllable.rightLetter"]
        XCTAssertEqual(app.buttons["syllable.leftLetter"].label, "м")
        XCTAssertEqual(rightLetter.label, "а")

        let previousLetter = rightLetter.label
        app.buttons["action.random.right"].tap()

        let newLetter = rightLetter.label
        XCTAssertNotEqual(newLetter, previousLetter)
        XCTAssertTrue(["а", "о", "у", "ы", "э", "я", "ё", "ю", "и", "е"].contains(newLetter))
    }

    func testWordsTabShowsGameAndCelebrationAfterCorrectMatches() throws {
        let app = XCUIApplication()
        app.launchArguments.append("UITestSmallWordSet")
        app.launch()

        app.tabBars.buttons["Слова"].tap()

        XCTAssertTrue(app.buttons["words.word.beads"].waitForExistence(timeout: 2))

        let pairs = ["beads", "bucket", "bread", "bag", "doll"]
        for key in pairs {
            app.buttons["words.word.\(key)"].tap()
            app.buttons["words.picture.\(key)"].tap()
        }

        XCTAssertTrue(app.staticTexts["words.celebration.title"].waitForExistence(timeout: 2))
    }

    func testAlphabeticalButtonSortsWordColumn() throws {
        let app = XCUIApplication()
        app.launchArguments.append("UITestSmallWordSet")
        app.launch()

        app.tabBars.buttons["Слова"].tap()

        let alphabeticalButton = app.buttons["words.action.alphabetical"]
        XCTAssertTrue(alphabeticalButton.waitForExistence(timeout: 2))

        alphabeticalButton.tap()

        let predicate = NSPredicate(format: "identifier BEGINSWITH %@", "words.word.")
        let wordButtons = app.buttons.matching(predicate)
        XCTAssertEqual(wordButtons.count, russianAlphabeticalOrder.count)

        let visibleWords = wordButtons.allElementsBoundByIndex.map(\.label)
        XCTAssertEqual(visibleWords, russianAlphabeticalOrder)
    }
}
