import SwiftUI

enum LetterKind: String, CaseIterable, Hashable {
    case vowel
    case consonant

    var accentColor: Color {
        switch self {
        case .vowel:
            return Color(red: 0.96, green: 0.47, blue: 0.27)
        case .consonant:
            return Color(red: 0.15, green: 0.58, blue: 0.74)
        }
    }

    var sheetTitle: String {
        switch self {
        case .vowel:
            return "Выберите гласную"
        case .consonant:
            return "Выберите согласную"
        }
    }

    var sheetDescription: String {
        "Можно нажать на букву ниже или ввести ее вручную."
    }
}
