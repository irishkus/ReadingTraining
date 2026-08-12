import Combine
import Foundation

@MainActor
final class SyllableTrainerViewModel: ObservableObject {
    @Published var selectedConsonant = "М"
    @Published var selectedVowel = "А"
    @Published var isConsonantLeading = true
    @Published var letterCaseMode: LetterCaseMode = .uppercase
    @Published var activePicker: LetterPickerContext?

    var leftKind: LetterKind {
        isConsonantLeading ? .consonant : .vowel
    }

    var rightKind: LetterKind {
        isConsonantLeading ? .vowel : .consonant
    }

    func displayedLetter(for kind: LetterKind) -> String {
        letterCaseMode.transform(selectedLetter(for: kind))
    }

    func letters(for kind: LetterKind) -> [String] {
        RussianLetters.letters(for: kind)
    }

    func openPicker(for kind: LetterKind) {
        activePicker = LetterPickerContext(kind: kind)
    }

    func closePicker() {
        activePicker = nil
    }

    func select(_ letter: String, for kind: LetterKind) {
        switch kind {
        case .vowel:
            selectedVowel = letter
        case .consonant:
            selectedConsonant = letter
        }
    }

    func randomize(_ kind: LetterKind) {
        let baseLetters = letters(for: kind)
        let currentLetter = selectedLetter(for: kind)
        var nextLetter = baseLetters.randomElement() ?? currentLetter

        if baseLetters.count > 1 {
            while nextLetter == currentLetter {
                nextLetter = baseLetters.randomElement() ?? currentLetter
            }
        }

        select(nextLetter, for: kind)
    }

    func toggleOrder() {
        isConsonantLeading.toggle()
    }

    private func selectedLetter(for kind: LetterKind) -> String {
        switch kind {
        case .vowel:
            return selectedVowel
        case .consonant:
            return selectedConsonant
        }
    }
}
