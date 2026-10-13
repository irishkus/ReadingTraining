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

    func testReadingMenuOpensSyllablesExercise() throws {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(waitForElement("menu.reading.syllables", in: app).exists)
        XCTAssertTrue(waitForElement("menu.reading.words", in: app).exists)
        XCTAssertTrue(waitForElement("menu.reading.readAloud", in: app).exists)

        waitForElement("menu.reading.syllables", in: app).tap()

        XCTAssertTrue(waitForElement("action.swap", in: app, timeout: 10).exists)
        waitForElement("navigation.back", in: app).tap()
        XCTAssertTrue(waitForElement("menu.reading.syllables", in: app).exists)
    }

    func testRussianMenuOpensWordBuilderExercise() throws {
        let app = XCUIApplication()
        app.launch()

        let russianTab = app.tabBars.buttons["Русский"]
        XCTAssertTrue(russianTab.waitForExistence(timeout: 5))
        russianTab.tap()

        waitForElement("menu.russian.wordBuilder", in: app).tap()

        XCTAssertTrue(waitForElement("wordBuilder.action.refresh", in: app, timeout: 10).exists)
    }

    func testRussianMenuOpensVowelsExercise() throws {
        let app = XCUIApplication()
        app.launch()

        let russianTab = app.tabBars.buttons["Русский"]
        XCTAssertTrue(russianTab.waitForExistence(timeout: 5))
        russianTab.tap()

        XCTAssertTrue(waitForElement("menu.russian.wordBuilder", in: app).exists)
        waitForElement("menu.russian.vowels", in: app).tap()

        XCTAssertTrue(waitForElement("vowels.action.check", in: app, timeout: 10).exists)
        XCTAssertTrue(waitForElement("vowels.action.refresh", in: app).exists)
    }

    func testVowelsExerciseConfirmsCorrectLetters() throws {
        let app = XCUIApplication()
        app.launchArguments += ["UITestSmallWordSet", "UITestDeterministicVowels", "UITestTabVowels"]
        app.launch()

        waitForElement("vowels.letter.1", in: app, timeout: 10).tap()
        waitForValue("Выбрано", element: waitForElement("vowels.letter.1", in: app))

        waitForElement("vowels.letter.3", in: app).tap()
        waitForValue("Выбрано", element: waitForElement("vowels.letter.3", in: app))

        waitForElement("vowels.action.check", in: app).tap()

        waitForValue("Гласная", element: waitForElement("vowels.letter.1", in: app))
        waitForValue("Гласная", element: waitForElement("vowels.letter.3", in: app))
        XCTAssertTrue(waitForElement("vowels.celebration.title", in: app).exists)
    }

    func testLaunchShowsDefaultSyllable() throws {
        let app = XCUIApplication()
        app.launchArguments.append("UITestTabSyllables")
        app.launch()

        openSyllablesTab(in: app)

        let leftLetter = waitForElement("syllable.leftLetter", in: app)
        let rightLetter = waitForElement("syllable.rightLetter", in: app)

        waitForLabel("М", element: leftLetter)
        waitForLabel("А", element: rightLetter)
        XCTAssertTrue(waitForElement("action.swap", in: app).exists)
    }

    func testSwapButtonChangesVisibleOrder() throws {
        let app = XCUIApplication()
        app.launchArguments.append("UITestTabSyllables")
        app.launch()

        openSyllablesTab(in: app)

        waitForElement("action.swap", in: app).tap()

        waitForLabel("А", element: waitForElement("syllable.leftLetter", in: app))
        waitForLabel("М", element: waitForElement("syllable.rightLetter", in: app))
    }

    func testLetterPickerChangesLeftLetter() throws {
        let app = XCUIApplication()
        app.launchArguments.append("UITestTabSyllables")
        app.launch()

        openSyllablesTab(in: app)

        waitForElement("syllable.leftLetter", in: app).tap()

        let pickerLetter = waitForElement("picker.letter.С", in: app)
        XCTAssertTrue(pickerLetter.waitForExistence(timeout: 5))

        pickerLetter.tap()

        waitForLabel("С", element: waitForElement("syllable.leftLetter", in: app))
    }

    func testLowercaseModeAndRandomButtonUpdateVisibleLetter() throws {
        let app = XCUIApplication()
        app.launchArguments.append("UITestTabSyllables")
        app.launch()

        openSyllablesTab(in: app)

        let lowercaseButton = app
            .descendants(matching: .segmentedControl)
            .matching(identifier: "caseMode.picker")
            .firstMatch
            .buttons["абв"]
        XCTAssertTrue(lowercaseButton.waitForExistence(timeout: 5))
        lowercaseButton.tap()

        let rightLetter = waitForElement("syllable.rightLetter", in: app)
        waitForLabel("м", element: waitForElement("syllable.leftLetter", in: app))
        waitForLabel("а", element: rightLetter)

        let previousLetter = rightLetter.label
        waitForElement("action.random.right", in: app).tap()

        let newLetter = waitForDifferentLabel(from: previousLetter, element: rightLetter)
        XCTAssertNotEqual(newLetter, previousLetter)
        XCTAssertTrue(["а", "о", "у", "ы", "э", "я", "ё", "ю", "и", "е"].contains(newLetter))
    }

    func testWordsTabShowsGameAndCelebrationAfterCorrectMatches() throws {
        let app = XCUIApplication()
        app.launchArguments += ["UITestSmallWordSet", "UITestTabWords"]
        app.launch()

        openWordsTab(in: app)

        XCTAssertTrue(app.buttons["words.word.beads"].waitForExistence(timeout: 5))

        let pairs = ["beads", "bucket", "bread", "bag", "doll"]
        for key in pairs {
            app.buttons["words.word.\(key)"].tap()
            app.buttons["words.picture.\(key)"].tap()
        }

        XCTAssertTrue(app.staticTexts["words.celebration.title"].waitForExistence(timeout: 2))
    }

    func testAlphabeticalButtonSortsWordColumn() throws {
        let app = XCUIApplication()
        app.launchArguments += ["UITestSmallWordSet", "UITestTabWords"]
        app.launch()

        openWordsTab(in: app)

        let alphabeticalButton = waitForElement("words.action.alphabetical", in: app)
        XCTAssertEqual(alphabeticalButton.value as? String, "active")

        let predicate = NSPredicate(format: "identifier BEGINSWITH %@", "words.word.")
        let wordButtons = app.buttons.matching(predicate)
        XCTAssertEqual(wordButtons.count, russianAlphabeticalOrder.count)

        let visibleWords = wordButtons.allElementsBoundByIndex.map(\.label)
        XCTAssertEqual(visibleWords, russianAlphabeticalOrder)
    }

    func testAlphabeticalModeStaysActiveAfterNewRound() throws {
        let app = XCUIApplication()
        app.launchArguments += ["UITestSmallWordSet", "UITestTabWords"]
        app.launch()

        openWordsTab(in: app)

        let alphabeticalButton = waitForElement("words.action.alphabetical", in: app)
        XCTAssertEqual(alphabeticalButton.value as? String, "active")

        waitForElement("words.action.restart", in: app).tap()

        waitForValue("active", element: alphabeticalButton)

        let predicate = NSPredicate(format: "identifier BEGINSWITH %@", "words.word.")
        let wordButtons = app.buttons.matching(predicate)
        let visibleWords = wordButtons.allElementsBoundByIndex.map(\.label)
        XCTAssertEqual(visibleWords, russianAlphabeticalOrder)
    }

    func testAlphabeticalModeStaysActiveAfterCelebrationPlayAgain() throws {
        let app = XCUIApplication()
        app.launchArguments += ["UITestSmallWordSet", "UITestTabWords"]
        app.launch()

        openWordsTab(in: app)

        let alphabeticalButton = waitForElement("words.action.alphabetical", in: app)

        let pairs = ["bread", "beads", "bucket", "doll", "bag"]
        for key in pairs {
            app.buttons["words.word.\(key)"].tap()
            app.buttons["words.picture.\(key)"].tap()
        }

        XCTAssertTrue(app.staticTexts["words.celebration.title"].waitForExistence(timeout: 2))

        app.buttons["words.celebration.playAgain"].tap()

        XCTAssertTrue(alphabeticalButton.waitForExistence(timeout: 5))
        waitForValue("active", element: alphabeticalButton)

        let predicate = NSPredicate(format: "identifier BEGINSWITH %@", "words.word.")
        let wordButtons = app.buttons.matching(predicate)
        let visibleWords = wordButtons.allElementsBoundByIndex.map(\.label)
        XCTAssertEqual(visibleWords, russianAlphabeticalOrder)
    }

    func testRepeatedTapOnConnectedPictureRemovesConnection() throws {
        let app = XCUIApplication()
        app.launchArguments += ["UITestSmallWordSet", "UITestTabWords"]
        app.launch()

        openWordsTab(in: app)

        let wordButton = app.buttons["words.word.beads"]
        let pictureButton = app.buttons["words.picture.bucket"]

        XCTAssertTrue(wordButton.waitForExistence(timeout: 5))
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
        app.launchArguments += ["UITestSmallWordSet", "UITestTabWords"]
        app.launch()

        openWordsTab(in: app)

        let counter = app.staticTexts["words.errorCounter"]
        XCTAssertTrue(counter.waitForExistence(timeout: 5))
        XCTAssertEqual(counter.label, "Ошибки: 0 из 7")

        let wordButton = app.buttons["words.word.beads"]
        let pictureButton = app.buttons["words.picture.bucket"]

        XCTAssertTrue(wordButton.waitForExistence(timeout: 5))
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
        app.launchArguments += ["UITestSmallWordSet", "UITestTabWords"]
        app.launch()

        openWordsTab(in: app)

        let alphabeticalButton = waitForElement("words.action.alphabetical", in: app)
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

        let keyboardDoneButton = app.buttons["words.parentGate.keyboardDone"]
        XCTAssertTrue(keyboardDoneButton.waitForExistence(timeout: 2))
        keyboardDoneButton.tap()

        app.buttons["words.parentGate.submit"].tap()
        XCTAssertTrue(title.waitForNonExistence(timeout: 3))

        waitForValue("inactive", element: waitForElement("words.action.alphabetical", in: app))
    }

    func testReadAloudTabShowsCelebrationAfterRecognizedWord() throws {
        let app = XCUIApplication()
        app.launchArguments += ["UITestSmallWordSet", "UITestReadAloudAutoSuccess", "UITestTabReadAloud"]
        app.launch()

        app.tabBars.buttons["Прочитай"].tap()

        let box = app.buttons["read.box.beads"]
        XCTAssertTrue(box.waitForExistence(timeout: 2))

        box.tap()

        XCTAssertTrue(app.staticTexts["read.celebration.title"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["read.celebration.continue"].exists)
    }

    func testReadAloudCompletingAllBoxesShowsRoundCelebration() throws {
        let app = XCUIApplication()
        app.launchArguments += ["UITestSmallWordSet", "UITestReadAloudAutoSuccess", "UITestTabReadAloud"]
        app.launch()

        openReadAloudTab(in: app)

        let keys = ["beads", "bucket", "bread", "bag", "doll"]
        for key in keys.dropLast() {
            completeReadAloudBox(key, in: app)
            XCTAssertTrue(app.buttons["read.celebration.continue"].waitForExistence(timeout: 2))
            app.buttons["read.celebration.continue"].tap()
        }

        completeReadAloudBox(keys.last!, in: app)

        XCTAssertTrue(app.staticTexts["read.roundCelebration.title"].waitForExistence(timeout: 3))
        XCTAssertEqual(app.staticTexts["read.progress"].label, "Открыто: 5 из 5")
    }

    func testReadAloudPlayAgainResetsProgressCounter() throws {
        let app = XCUIApplication()
        app.launchArguments += ["UITestSmallWordSet", "UITestReadAloudAutoSuccess", "UITestTabReadAloud"]
        app.launch()

        openReadAloudTab(in: app)

        let keys = ["beads", "bucket", "bread", "bag", "doll"]
        for key in keys.dropLast() {
            completeReadAloudBox(key, in: app)
            app.buttons["read.celebration.continue"].tap()
        }
        completeReadAloudBox(keys.last!, in: app)

        let playAgainButton = app.buttons["read.roundCelebration.playAgain"]
        XCTAssertTrue(playAgainButton.waitForExistence(timeout: 3))
        playAgainButton.tap()

        let progress = app.staticTexts["read.progress"]
        XCTAssertTrue(progress.waitForExistence(timeout: 2))
        waitForLabel("Открыто: 0 из 5", element: progress)
        XCTAssertFalse(app.staticTexts["read.roundCelebration.title"].exists)
    }

    func testReadAloudRestartButtonClearsOpenedProgress() throws {
        let app = XCUIApplication()
        app.launchArguments += ["UITestSmallWordSet", "UITestReadAloudAutoSuccess", "UITestTabReadAloud"]
        app.launch()

        openReadAloudTab(in: app)

        completeReadAloudBox("beads", in: app)
        XCTAssertTrue(app.buttons["read.celebration.continue"].waitForExistence(timeout: 2))
        app.buttons["read.celebration.continue"].tap()

        let progress = app.staticTexts["read.progress"]
        XCTAssertTrue(progress.waitForExistence(timeout: 2))
        waitForLabel("Открыто: 1 из 5", element: progress)

        app.buttons["read.action.restart"].tap()

        waitForLabel("Открыто: 0 из 5", element: progress)
    }

    private func waitForLabel(
        _ label: String,
        element: XCUIElement,
        timeout: TimeInterval = 5
    ) {
        XCTAssertTrue(element.waitForExistence(timeout: timeout))
        let predicate = NSPredicate(format: "label == %@", label)
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        let result = XCTWaiter().wait(for: [expectation], timeout: timeout)

        if result != .completed {
            XCTFail("Expected label '\(label)', got '\(element.label)'")
        }
    }

    private func waitForValue(
        _ value: String,
        element: XCUIElement,
        timeout: TimeInterval = 5
    ) {
        XCTAssertTrue(element.waitForExistence(timeout: timeout))
        let predicate = NSPredicate(format: "value == %@", value)
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        let result = XCTWaiter().wait(for: [expectation], timeout: timeout)

        if result != .completed {
            XCTFail("Expected value '\(value)', got '\(String(describing: element.value))'")
        }
    }

    private func waitForDifferentLabel(
        from initialLabel: String,
        element: XCUIElement,
        timeout: TimeInterval = 5
    ) -> String {
        XCTAssertTrue(element.waitForExistence(timeout: timeout))
        let predicate = NSPredicate(format: "label != %@", initialLabel)
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        let result = XCTWaiter().wait(for: [expectation], timeout: timeout)

        if result != .completed {
            XCTFail("Label did not change from '\(initialLabel)'")
        }

        return element.label
    }

    private func openSyllablesTab(in app: XCUIApplication) {
        let swapButton = identifiedElement("action.swap", in: app)
        let leftRandomButton = identifiedElement("action.random.left", in: app)

        XCTAssertTrue(
            waitForElements([swapButton, leftRandomButton], timeout: 10),
            "Syllables screen did not become accessible after launch"
        )
    }

    private func openWordsTab(in app: XCUIApplication) {
        let alphabeticalButton = identifiedElement("words.action.alphabetical", in: app)
        let restartButton = identifiedElement("words.action.restart", in: app)

        XCTAssertTrue(
            waitForElements([alphabeticalButton, restartButton], timeout: 10),
            "Words screen did not become accessible after launch"
        )
    }

    private func identifiedElement(_ identifier: String, in app: XCUIApplication) -> XCUIElement {
        return app.descendants(matching: .any).matching(identifier: identifier).firstMatch
    }

    private func waitForElement(
        _ identifier: String,
        in app: XCUIApplication,
        timeout: TimeInterval = 5
    ) -> XCUIElement {
        let element = identifiedElement(identifier, in: app)
        XCTAssertTrue(element.waitForExistence(timeout: timeout))
        return element
    }

    private func waitForElements(
        _ elements: [XCUIElement],
        timeout: TimeInterval
    ) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)

        while Date() < deadline {
            if elements.allSatisfy(\.exists) {
                return true
            }

            RunLoop.current.run(until: Date().addingTimeInterval(0.1))
        }

        return elements.allSatisfy(\.exists)
    }

    private func openReadAloudTab(in app: XCUIApplication) {
        XCTAssertTrue(app.buttons["read.box.beads"].waitForExistence(timeout: 10))
    }

    private func completeReadAloudBox(_ key: String, in app: XCUIApplication) {
        let box = app.buttons["read.box.\(key)"]
        XCTAssertTrue(box.waitForExistence(timeout: 2))
        box.tap()
    }

    private func squareRootFromChallenge(_ challenge: String) -> Int {
        let radicand = challenge
            .components(separatedBy: CharacterSet.decimalDigits.inverted)
            .joined()

        let value = Int(radicand) ?? 0
        return Int(Double(value).squareRoot())
    }
}
