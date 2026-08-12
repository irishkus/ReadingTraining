enum LetterCaseMode: String, CaseIterable, Identifiable {
    case uppercase
    case lowercase

    var id: Self {
        self
    }

    var title: String {
        switch self {
        case .uppercase:
            return "АБВ"
        case .lowercase:
            return "абв"
        }
    }

    func transform(_ value: String) -> String {
        switch self {
        case .uppercase:
            return value.uppercased()
        case .lowercase:
            return value.lowercased()
        }
    }
}
