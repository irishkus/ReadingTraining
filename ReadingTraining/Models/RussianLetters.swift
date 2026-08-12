enum RussianLetters {
    static let vowels = ["А", "О", "У", "Ы", "Э", "Я", "Ё", "Ю", "И", "Е"]
    static let consonants = ["Б", "В", "Г", "Д", "Ж", "З", "Й", "К", "Л", "М", "Н", "П", "Р", "С", "Т", "Ф", "Х", "Ц", "Ч", "Ш", "Щ"]

    static func letters(for kind: LetterKind) -> [String] {
        switch kind {
        case .vowel:
            return vowels
        case .consonant:
            return consonants
        }
    }
}
