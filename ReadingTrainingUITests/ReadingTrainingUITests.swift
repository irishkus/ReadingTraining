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
        XCTAssertEqual(alphabeticalButton.value as? String, "active")

        let predicate = NSPredicate(format: "identifier BEGINSWITH %@", "words.word.")
        let wordButtons = app.buttons.matching(predicate)
        XCTAssertEqual(wordButtons.count, russianAlphabeticalOrder.count)

        let visibleWords = wordButtons.allElementsBoundByIndex.map(\.label)
        XCTAssertEqual(visibleWords, russianAlphabeticalOrder)
    }

    func testAlphabeticalModeStaysActiveAfterNewRound() throws {
        let app = XCUIApplication()
        app.launchArguments.append("UITestSmallWordSet")
        app.launch()

        app.tabBars.buttons["Слова"].tap()

        let alphabeticalButton = app.buttons["words.action.alphabetical"]
        XCTAssertTrue(alphabeticalButton.waitForExistence(timeout: 2))
        XCTAssertEqual(alphabeticalButton.value as? String, "active")

        app.buttons["words.action.restart"].tap()

        XCTAssertEqual(alphabeticalButton.value as? String, "active")

        let predicate = NSPredicate(format: "identifier BEGINSWITH %@", "words.word.")
        let wordButtons = app.buttons.matching(predicate)
        let visibleWords = wordButtons.allElementsBoundByIndex.map(\.label)
        XCTAssertEqual(visibleWords, russianAlphabeticalOrder)
    }

    func testAlphabeticalModeStaysActiveAfterCelebrationPlayAgain() throws {
        let app = XCUIApplication()
        app.launchArguments.append("UITestSmallWordSet")
        app.launch()

        app.tabBars.buttons["Слова"].tap()

        let alphabeticalButton = app.buttons["words.action.alphabetical"]
        XCTAssertTrue(alphabeticalButton.waitForExistence(timeout: 2))

        let pairs = ["bread", "beads", "bucket", "doll", "bag"]
        for key in pairs {
            app.buttons["words.word.\(key)"].tap()
            app.buttons["words.picture.\(key)"].tap()
        }

        XCTAssertTrue(app.staticTexts["words.celebration.title"].waitForExistence(timeout: 2))

        app.buttons["words.celebration.playAgain"].tap()

        XCTAssertTrue(alphabeticalButton.waitForExistence(timeout: 2))
        XCTAssertEqual(alphabeticalButton.value as? String, "active")

        let predicate = NSPredicate(format: "identifier BEGINSWITH %@", "words.word.")
        let wordButtons = app.buttons.matching(predicate)
        let visibleWords = wordButtons.allElementsBoundByIndex.map(\.label)
        XCTAssertEqual(visibleWords, russianAlphabeticalOrder)
    }

    func testRepeatedTapOnConnectedPictureRemovesConnection() throws {
        let app = XCUIApplication()
        app.launchArguments.append("UITestSmallWordSet")
        app.launch()

        app.tabBars.buttons["Слова"].tap()

        let wordButton = app.buttons["words.word.beads"]
        let pictureButton = app.buttons["words.picture.bucket"]

        XCTAssertTrue(wordButton.waitForExistence(timeout: 2))
        XCTAssertTrue(pictureButton.exists)

        wordButton.tap()
        pictureButton.tap()
        XCTAssertEqual(wordButton.value as? String, "incorrect")
        XCTAssertEqual(pictureButton.value as? String, "incorrect")

        pictureButton.tap()
        XCTAssertEqual(wordButton.value as? String, "idle")
        XCTAssertEqual(pictureButton.value as? String, "selected")
    }

    func testErrorCounterResetsAfterSeventhMistake() throws {
        let app = XCUIApplication()
        app.launchArguments.append("UITestSmallWordSet")
        app.launch()

        app.tabBars.buttons["Слова"].tap()

        let counter = app.staticTexts["words.errorCounter"]
        XCTAssertTrue(counter.waitForExistence(timeout: 2))
        XCTAssertEqual(counter.label, "Ошибки: 0 из 7")

        let wordButton = app.buttons["words.word.beads"]
        let pictureButton = app.buttons["words.picture.bucket"]

        XCTAssertTrue(wordButton.waitForExistence(timeout: 2))
        XCTAssertTrue(pictureButton.exists)

        for attempt in 1..<7 {
            wordButton.tap()
            pictureButton.tap()
            waitForLabel("Ошибки: \(attempt) из 7", element: counter)
        }

        wordButton.tap()
        pictureButton.tap()

        waitForLabel("Ошибки: 0 из 7", element: counter)
    }

    func testDisablingAlphabeticalModeRequiresParentGate() throws {
        let app = XCUIApplication()
        app.launchArguments.append("UITestSmallWordSet")
        app.launch()

        app.tabBars.buttons["Слова"].tap()

        let alphabeticalButton = app.buttons["words.action.alphabetical"]
        XCTAssertTrue(alphabeticalButton.waitForExistence(timeout: 2))
        XCTAssertEqual(alphabeticalButton.value as? String, "active")

        alphabeticalButton.tap()

        let title = app.staticTexts["words.parentGate.title"]
        XCTAssertTrue(title.waitForExistence(timeout: 2))

        let challenge = app.staticTexts["words.parentGate.challenge"].label
        let answer = squareRootFromChallenge(challenge)

        let answerField = app.textFields["words.parentGate.answer"]
        XCTAssertTrue(answerField.exists)
        answerField.tap()
        answerField.typeText(String(answer))

        app.buttons["words.parentGate.submit"].tap()

        waitForValue("inactive", element: alphabeticalButton)
    }

    func testReadAloudTabShowsCelebrationAfterRecognizedWord() throws {
        let app = XCUIApplication()
        app.launchArguments += ["UITestSmallWordSet", "UITestReadAloudAutoSuccess"]
        app.launch()

        app.tabBars.buttons["Прочитай"].tap()

        let box = app.buttons["read.box.beads"]
        XCTAssertTrue(box.waitForExistence(timeout: 2))

        box.tap()

        XCTAssertTrue(app.staticTexts["read.celebration.title"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["read.celebration.continue"].exists)
    }

    private func waitForLabel(_ label: String, element: XCUIElement) {
        let predicate = NSPredicate(format: "label == %@", label)
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        XCTAssertEqual(XCTWaiter().wait(for: [expectation], timeout: 2), .completed)
    }

    private func waitForValue(_ value: String, element: XCUIElement) {
        let predicate = NSPredicate(format: "value == %@", value)
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        XCTAssertEqual(XCTWaiter().wait(for: [expectation], timeout: 2), .completed)
    }

    private func squareRootFromChallenge(_ challenge: String) -> Int {
        let radicand = challenge
            .components(separatedBy: CharacterSet.decimalDigits.inverted)
            .joined()

        let value = Int(radicand) ?? 0
        return Int(Double(value).squareRoot())
    }
}
