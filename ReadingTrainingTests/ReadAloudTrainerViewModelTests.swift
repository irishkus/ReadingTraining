import XCTest
@testable import ReadingTraining

@MainActor
final class ReadAloudTrainerViewModelTests: XCTestCase {
    func testInitialRoundContainsRequestedNumberOfPairs() {
        let pairs = [
            WordMatchPair(key: "cup", word: "ЧАШКА", illustration: .bundlePNG(name: "cup")),
            WordMatchPair(key: "book", word: "КНИГА", illustration: .bundlePNG(name: "book")),
            WordMatchPair(key: "cat", word: "КОТ", illustration: .bundlePNG(name: "cat")),
            WordMatchPair(key: "bus", word: "АВТОБУС", illustration: .bundlePNG(name: "bus"))
        ]

        let viewModel = ReadAloudTrainerViewModel(
            pairs: pairs,
            roundSize: 3,
            speechRecognizer: ReadAloudSpeechRecognizerMock(),
            shuffleOnInit: false
        )

        XCTAssertEqual(viewModel.pairs.count, 3)
        XCTAssertEqual(viewModel.totalCount, 3)
        XCTAssertEqual(viewModel.completedCount, 0)
    }

    func testCorrectTranscriptOnLastPairShowsRoundCelebration() async {
        let mock = ReadAloudSpeechRecognizerMock()
        let pair = WordMatchPair(key: "cup", word: "ЧАШКА", illustration: .bundlePNG(name: "cup"))
        let viewModel = ReadAloudTrainerViewModel(
            pairs: [pair],
            roundSize: 1,
            speechRecognizer: mock,
            shuffleOnInit: false
        )

        viewModel.selectPair(pair)
        await Task.yield()
        await Task.yield()

        XCTAssertTrue(viewModel.isListening)
        XCTAssertEqual(mock.lastExpectedWord, "ЧАШКА")

        await mock.emit(.transcript("чашка", isFinal: false))

        XCTAssertFalse(viewModel.isListening)
        XCTAssertEqual(viewModel.completedPairIDs, Set([pair.id]))
        XCTAssertNil(viewModel.celebrationPair)
        XCTAssertEqual(viewModel.finalCelebrationPair?.id, pair.id)
        XCTAssertTrue(viewModel.isRoundCelebrationPresented)
    }

    func testCorrectTranscriptOnIntermediatePairShowsInlineCelebration() async {
        let mock = ReadAloudSpeechRecognizerMock()
        let firstPair = WordMatchPair(key: "cup", word: "ЧАШКА", illustration: .bundlePNG(name: "cup"))
        let secondPair = WordMatchPair(key: "book", word: "КНИГА", illustration: .bundlePNG(name: "book"))
        let viewModel = ReadAloudTrainerViewModel(
            pairs: [firstPair, secondPair],
            roundSize: 2,
            speechRecognizer: mock,
            shuffleOnInit: false
        )

        viewModel.selectPair(firstPair)
        await Task.yield()
        await Task.yield()

        await mock.emit(.transcript("чашка", isFinal: false))

        XCTAssertEqual(viewModel.celebrationPair?.id, firstPair.id)
        XCTAssertFalse(viewModel.isRoundCelebrationPresented)
    }

    func testWrongFinalTranscriptDoesNotCompletePair() async {
        let mock = ReadAloudSpeechRecognizerMock()
        let pair = WordMatchPair(key: "book", word: "КНИГА", illustration: .bundlePNG(name: "book"))
        let viewModel = ReadAloudTrainerViewModel(
            pairs: [pair],
            roundSize: 1,
            speechRecognizer: mock,
            shuffleOnInit: false
        )

        viewModel.selectPair(pair)
        await Task.yield()
        await Task.yield()

        await mock.emit(.transcript("ручка", isFinal: true))

        XCTAssertFalse(viewModel.isListening)
        XCTAssertFalse(viewModel.completedPairIDs.contains(pair.id))
        XCTAssertNil(viewModel.celebrationPair)
        XCTAssertEqual(viewModel.statusText, "Нажмите на коробку и прочитайте слово вслух.")
        XCTAssertTrue(viewModel.recognizedText.isEmpty)
    }

    func testStartNewRoundClearsCompletedStateAndCelebration() async {
        let mock = ReadAloudSpeechRecognizerMock()
        let pair = WordMatchPair(key: "cat", word: "КОТ", illustration: .bundlePNG(name: "cat"))
        let viewModel = ReadAloudTrainerViewModel(
            pairs: [pair],
            roundSize: 1,
            speechRecognizer: mock,
            shuffleOnInit: false
        )

        viewModel.selectPair(pair)
        await Task.yield()
        await Task.yield()
        await mock.emit(.transcript("кот", isFinal: false))

        viewModel.startNewRound()

        XCTAssertTrue(viewModel.completedPairIDs.isEmpty)
        XCTAssertNil(viewModel.celebrationPair)
        XCTAssertNil(viewModel.finalCelebrationPair)
        XCTAssertFalse(viewModel.isRoundCelebrationPresented)
        XCTAssertEqual(viewModel.statusText, "Нажмите на коробку и прочитайте слово вслух.")
    }
}

@MainActor
private final class ReadAloudSpeechRecognizerMock: ReadAloudSpeechRecognizing {
    private var handler: (@MainActor (ReadAloudSpeechEvent) -> Void)?

    var lastExpectedWord: String?

    func requestAuthorization() async -> ReadAloudSpeechAuthorizationStatus {
        .authorized
    }

    func startListening(
        expectedWord: String,
        onEvent: @escaping @MainActor (ReadAloudSpeechEvent) -> Void
    ) throws {
        lastExpectedWord = expectedWord
        handler = onEvent
        onEvent(.started)
    }

    func stopListening() {
        handler = nil
    }

    func emit(_ event: ReadAloudSpeechEvent) async {
        if let handler {
            await handler(event)
        }
    }
}
