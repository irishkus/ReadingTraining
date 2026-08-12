struct LetterPickerContext: Identifiable {
    let kind: LetterKind

    var id: String {
        kind.rawValue
    }
}
