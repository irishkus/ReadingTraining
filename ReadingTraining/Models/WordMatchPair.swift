import Foundation

enum WordIllustration: Hashable {
    case asset(name: String)
    case bundlePNG(name: String)
}

struct WordMatchPair: Identifiable, Hashable {
    let id: UUID
    let key: String
    let word: String
    let illustration: WordIllustration

    init(id: UUID = UUID(), key: String, word: String, illustration: WordIllustration) {
        self.id = id
        self.key = key
        self.word = word
        self.illustration = illustration
    }
}

struct WordMatchConnection: Identifiable, Equatable {
    let wordID: WordMatchPair.ID
    let pictureID: WordMatchPair.ID
    let isCorrect: Bool

    var id: WordMatchPair.ID { wordID }
}

enum WordMatchCardState: Equatable {
    case idle
    case selected
    case correct
    case incorrect
}
