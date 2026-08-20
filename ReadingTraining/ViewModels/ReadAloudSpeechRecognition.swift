import AVFoundation
import Foundation
import Speech

enum ReadAloudSpeechAuthorizationStatus: Equatable {
    case authorized
    case denied
    case restricted
    case unsupported
}

enum ReadAloudSpeechEvent: Equatable {
    case started
    case transcript(String, isFinal: Bool)
    case failure(String)
}

protocol ReadAloudSpeechRecognizing: AnyObject {
    func requestAuthorization() async -> ReadAloudSpeechAuthorizationStatus
    func startListening(
        expectedWord: String,
        onEvent: @escaping @MainActor (ReadAloudSpeechEvent) -> Void
    ) throws
    func stopListening()
}

enum ReadAloudSpeechRecognizerFactory {
    static func makeRecognizer(processInfo: ProcessInfo = .processInfo) -> any ReadAloudSpeechRecognizing {
        if processInfo.arguments.contains("UITestReadAloudAutoSuccess") {
            return MockReadAloudSpeechRecognizer(mode: .success)
        }

        return SystemReadAloudSpeechRecognizer()
    }
}

private enum ReadAloudSpeechRecognizerError: LocalizedError {
    case unsupportedLanguage
    case recognizerUnavailable
    case audioEngineFailure

    var errorDescription: String? {
        switch self {
        case .unsupportedLanguage:
            return "На этом устройстве недоступно распознавание русской речи."
        case .recognizerUnavailable:
            return "Распознавание речи сейчас недоступно. Попробуйте еще раз чуть позже."
        case .audioEngineFailure:
            return "Не удалось включить микрофон. Проверьте разрешение и попробуйте еще раз."
        }
    }
}

final class SystemReadAloudSpeechRecognizer: ReadAloudSpeechRecognizing {
    private let audioEngine = AVAudioEngine()
    private let speechRecognizer: SFSpeechRecognizer?

    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var sessionID = UUID()

    init(locale: Locale = Locale(identifier: "ru_RU")) {
        speechRecognizer = SFSpeechRecognizer(locale: locale)
    }

    func requestAuthorization() async -> ReadAloudSpeechAuthorizationStatus {
        guard speechRecognizer != nil else {
            return .unsupported
        }

        let speechStatus = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }

        switch speechStatus {
        case .authorized:
            break
        case .denied:
            return .denied
        case .restricted:
            return .restricted
        case .notDetermined:
            return .denied
        @unknown default:
            return .denied
        }

        let microphoneAllowed = await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { allowed in
                continuation.resume(returning: allowed)
            }
        }

        return microphoneAllowed ? .authorized : .denied
    }

    func startListening(
        expectedWord _: String,
        onEvent: @escaping @MainActor (ReadAloudSpeechEvent) -> Void
    ) throws {
        stopListening()

        guard let speechRecognizer else {
            throw ReadAloudSpeechRecognizerError.unsupportedLanguage
        }

        guard speechRecognizer.isAvailable else {
            throw ReadAloudSpeechRecognizerError.recognizerUnavailable
        }

        let newSessionID = UUID()
        sessionID = newSessionID

        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: [.duckOthers])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            throw ReadAloudSpeechRecognizerError.audioEngineFailure
        }

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.requiresOnDeviceRecognition = false
        recognitionRequest = request

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }

        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            cleanupAudioSession()
            throw ReadAloudSpeechRecognizerError.audioEngineFailure
        }

        Task { @MainActor in
            onEvent(.started)
        }

        recognitionTask = speechRecognizer.recognitionTask(with: request) { [weak self] result, error in
            guard let self, self.sessionID == newSessionID else {
                return
            }

            if let result {
                Task { @MainActor in
                    onEvent(.transcript(result.bestTranscription.formattedString, isFinal: result.isFinal))
                }

                if result.isFinal {
                    self.cleanupAudioSession()
                }
            }

            guard let error else {
                return
            }

            self.cleanupAudioSession()

            // Ignore cancellation-like endings triggered by the app itself.
            let nsError = error as NSError
            if nsError.domain == "kAFAssistantErrorDomain", nsError.code == 216 {
                return
            }

            Task { @MainActor in
                onEvent(.failure("Я не смогла расслышать слово. Попробуем еще раз."))
            }
        }
    }

    func stopListening() {
        sessionID = UUID()
        cleanupAudioSession()
    }

    private func cleanupAudioSession() {
        recognitionRequest?.endAudio()
        recognitionRequest = nil

        recognitionTask?.cancel()
        recognitionTask = nil

        if audioEngine.isRunning {
            audioEngine.stop()
        }

        audioEngine.inputNode.removeTap(onBus: 0)

        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}

private final class MockReadAloudSpeechRecognizer: ReadAloudSpeechRecognizing {
    enum Mode {
        case success
    }

    private let mode: Mode
    private var task: Task<Void, Never>?

    init(mode: Mode) {
        self.mode = mode
    }

    func requestAuthorization() async -> ReadAloudSpeechAuthorizationStatus {
        .authorized
    }

    func startListening(
        expectedWord: String,
        onEvent: @escaping @MainActor (ReadAloudSpeechEvent) -> Void
    ) throws {
        stopListening()

        task = Task {
            await onEvent(.started)
            try? await Task.sleep(nanoseconds: 250_000_000)
            guard !Task.isCancelled else {
                return
            }

            switch mode {
            case .success:
                await onEvent(.transcript(expectedWord, isFinal: true))
            }
        }
    }

    func stopListening() {
        task?.cancel()
        task = nil
    }
}
