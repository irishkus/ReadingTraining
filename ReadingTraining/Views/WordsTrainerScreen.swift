import SwiftUI
import UIKit

struct WordsTrainerScreen: View {
    @StateObject private var viewModel = WordMatchGameViewModel()
    @State private var connectionPoints: [String: CGPoint] = [:]
    @State private var isParentGatePresented = false
    @State private var parentGateChallenge = ParentGateChallenge.random()

    var body: some View {
        GeometryReader { proxy in
            let compactHeight = proxy.size.height < 760

            ZStack {
                TrainerBackgroundView()

                VStack(spacing: compactHeight ? 10 : 14) {
                    header(compactHeight: compactHeight)

                    board(compactHeight: compactHeight)
                        .frame(maxHeight: .infinity)

                    footer(compactHeight: compactHeight)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, compactHeight ? 12 : 16)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .sheet(isPresented: $viewModel.isCelebrationPresented, onDismiss: viewModel.dismissCelebration) {
            celebrationSheet
                .presentationDetents([.height(280)])
                .presentationDragIndicator(.visible)
        }
    }

    private func header(compactHeight: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Слова и картинки")
                .font(.system(size: compactHeight ? 28 : 32, weight: .black, design: .rounded))
                .foregroundStyle(Color(red: 0.19, green: 0.27, blue: 0.35))

            Text("Нажмите на слово, потом на подходящую картинку.")
                .font(.system(size: compactHeight ? 14 : 15, weight: .bold, design: .rounded))
                .foregroundStyle(.primary.opacity(0.72))

            Text("Повторное нажатие на карточку убирает линию.")
                .font(.system(size: compactHeight ? 13 : 14, weight: .semibold, design: .rounded))
                .foregroundStyle(.primary.opacity(0.52))

            Text("Ошибки: \(viewModel.errorCount) из \(viewModel.maximumMistakeCount)")
                .font(.system(size: compactHeight ? 13 : 14, weight: .bold, design: .rounded))
                .foregroundStyle(
                    viewModel.errorCount == 0
                        ? .primary.opacity(0.58)
                        : Color(red: 0.78, green: 0.30, blue: 0.28)
                )
                .accessibilityIdentifier("words.errorCounter")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 18)
        .padding(.vertical, compactHeight ? 14 : 16)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(.white.opacity(0.82))
        )
        .shadow(color: Color.black.opacity(0.06), radius: 14, x: 0, y: 8)
    }

    private func board(compactHeight: Bool) -> some View {
        GeometryReader { boardProxy in
            let rowSpacing: CGFloat = compactHeight ? 8 : 12
            let cardHeight = min(92, max(62, (boardProxy.size.height - (rowSpacing * 4)) / 5))
            let imageSize = compactHeight ? cardHeight * 0.82 : cardHeight * 0.88

            HStack(alignment: .top, spacing: compactHeight ? 16 : 20) {
                VStack(spacing: rowSpacing) {
                    ForEach(viewModel.words) { pair in
                        Button {
                            viewModel.selectWord(pair.id)
                        } label: {
                            MatchWordCard(
                                word: pair.word,
                                state: viewModel.cardState(forWordID: pair.id),
                                compactHeight: compactHeight
                            )
                        }
                        .buttonStyle(.plain)
                        .frame(maxWidth: .infinity)
                        .frame(height: cardHeight)
                        .background(
                            GeometryReader { geometry in
                                Color.clear.preference(
                                    key: MatchPointPreferenceKey.self,
                                    value: [
                                        "word-\(pair.id.uuidString)": CGPoint(
                                            x: geometry.frame(in: .named("matchBoard")).maxX - 24,
                                            y: geometry.frame(in: .named("matchBoard")).midY
                                        )
                                    ]
                                )
                            }
                        )
                        .accessibilityIdentifier("words.word.\(pair.key)")
                        .accessibilityLabel(pair.word)
                        .accessibilityValue(viewModel.cardState(forWordID: pair.id).accessibilityValue)
                    }
                }
                .frame(maxWidth: .infinity)

                VStack(spacing: rowSpacing) {
                    ForEach(viewModel.pictures) { pair in
                        Button {
                            viewModel.selectPicture(pair.id)
                        } label: {
                            MatchPictureCard(
                                illustration: pair.illustration,
                                state: viewModel.cardState(forPictureID: pair.id),
                                imageSize: imageSize
                            )
                        }
                        .buttonStyle(.plain)
                        .frame(maxWidth: .infinity)
                        .frame(height: cardHeight)
                        .background(
                            GeometryReader { geometry in
                                Color.clear.preference(
                                    key: MatchPointPreferenceKey.self,
                                    value: [
                                        "picture-\(pair.id.uuidString)": CGPoint(
                                            x: geometry.frame(in: .named("matchBoard")).minX + 12,
                                            y: geometry.frame(in: .named("matchBoard")).midY
                                        )
                                    ]
                                )
                            }
                        )
                        .accessibilityIdentifier("words.picture.\(pair.key)")
                        .accessibilityLabel(pair.word)
                        .accessibilityValue(viewModel.cardState(forPictureID: pair.id).accessibilityValue)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .overlay {
                ConnectionLayerView(
                    connections: viewModel.connections,
                    points: connectionPoints,
                    compactHeight: compactHeight
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .zIndex(1)
            }
            .padding(.horizontal, compactHeight ? 10 : 12)
            .padding(.vertical, compactHeight ? 12 : 14)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .fill(.white.opacity(0.82))
            )
            .onPreferenceChange(MatchPointPreferenceKey.self) { points in
                connectionPoints = points
            }
            .coordinateSpace(name: "matchBoard")
            .shadow(color: Color.black.opacity(0.06), radius: 16, x: 0, y: 8)
        }
    }

    private func footer(compactHeight: Bool) -> some View {
        HStack(spacing: 8) {
            Button {
                handleAlphabeticalButtonTap()
            } label: {
                footerButtonLabel(
                    title: "По алфавиту",
                    compactHeight: compactHeight,
                    isActive: viewModel.isAlphabeticalRound
                )
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("words.action.alphabetical")
            .accessibilityValue(viewModel.isAlphabeticalRound ? "active" : "inactive")
            .sheet(isPresented: $isParentGatePresented) {
                ParentGateSheet(challenge: parentGateChallenge) {
                    viewModel.startRandomRound()
                }
                .presentationDetents([.height(360)])
                .presentationDragIndicator(.visible)
            }

            Button {
                viewModel.startNewRound()
            } label: {
                footerButtonLabel(
                    title: "Новый набор",
                    compactHeight: compactHeight,
                    isActive: !viewModel.isAlphabeticalRound
                )
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("words.action.restart")
            .accessibilityValue(viewModel.isAlphabeticalRound ? "inactive" : "active")
        }
        .padding(.horizontal, 18)
        .padding(.vertical, compactHeight ? 12 : 14)
        .frame(height: compactHeight ? 72 : 76)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(.white.opacity(0.76))
        )
    }

    private func footerButtonLabel(
        title: String,
        compactHeight: Bool,
        isActive: Bool
    ) -> some View {
        Text(title)
            .font(.system(size: compactHeight ? 14 : 15, weight: .bold, design: .rounded))
            .foregroundStyle(
                isActive
                    ? Color(red: 0.18, green: 0.48, blue: 0.78)
                    : Color(red: 0.28, green: 0.45, blue: 0.62)
            )
            .frame(maxWidth: .infinity)
            .padding(.horizontal, compactHeight ? 12 : 14)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(isActive ? .white.opacity(0.88) : .white.opacity(0.62))
            )
    }

    private func handleAlphabeticalButtonTap() {
        if viewModel.isAlphabeticalRound {
            parentGateChallenge = ParentGateChallenge.random()
            isParentGatePresented = true
            return
        }

        viewModel.startAlphabetRound()
    }

    private var celebrationSheet: some View {
        VStack(spacing: 18) {
            Image(systemName: "star.circle.fill")
                .font(.system(size: 62))
                .foregroundStyle(Color(red: 0.98, green: 0.72, blue: 0.18))

            Text("Молодец!")
                .font(.system(size: 30, weight: .black, design: .rounded))
                .accessibilityIdentifier("words.celebration.title")

            Text("Все слова соединены правильно.")
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundStyle(.primary.opacity(0.72))

            Button {
                viewModel.startNewRound()
            } label: {
                Text("Играть еще")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .fill(Color(red: 0.18, green: 0.63, blue: 0.39))
                    )
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("words.celebration.playAgain")
        }
        .padding(24)
    }
}

private struct ParentGateChallenge {
    let radicand: Int
    let root: Int

    var expression: String {
        "√\(radicand)"
    }

    var answer: Int {
        root
    }

    static func random() -> ParentGateChallenge {
        let root = Int.random(in: 2...10)
        return ParentGateChallenge(radicand: root * root, root: root)
    }
}

private struct ParentGateSheet: View {
    let challenge: ParentGateChallenge
    let onSuccess: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var answer = ""
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 18) {
                Text("Проверка для родителя")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("words.parentGate.title")

                Text("Чтобы убрать режим \"По алфавиту\",\nвведите корень из числа.")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.primary.opacity(0.72))
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity)

                Text(challenge.expression)
                    .font(.system(size: 44, weight: .black, design: .rounded))
                    .accessibilityIdentifier("words.parentGate.challenge")

                TextField("Ответ", text: $answer)
                    .keyboardType(.numberPad)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(Color(.systemBackground))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Color(red: 0.18, green: 0.48, blue: 0.78).opacity(0.22), lineWidth: 1)
                    )
                    .accessibilityIdentifier("words.parentGate.answer")

                if let errorMessage {
                    Text(errorMessage)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(red: 0.78, green: 0.30, blue: 0.28))
                }

                Button {
                    submit()
                } label: {
                    Text("Проверить")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .fill(Color(red: 0.18, green: 0.48, blue: 0.78))
                        )
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("words.parentGate.submit")

                Spacer(minLength: 0)
            }
            .padding(24)
            .background(Color(.systemGroupedBackground))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Отмена") {
                        dismiss()
                    }
                    .accessibilityIdentifier("words.parentGate.cancel")
                }
            }
        }
    }

    private func submit() {
        guard Int(answer.trimmingCharacters(in: .whitespacesAndNewlines)) == challenge.answer else {
            errorMessage = "Неверный ответ. Попробуйте еще раз."
            answer = ""
            return
        }

        onSuccess()
        dismiss()
    }
}

private struct MatchWordCard: View {
    let word: String
    let state: WordMatchCardState
    let compactHeight: Bool

    var body: some View {
        Text(word)
            .font(.system(size: compactHeight ? 26 : 30, weight: .black, design: .rounded))
            .foregroundStyle(Color(red: 0.17, green: 0.23, blue: 0.30))
            .lineLimit(2)
            .multilineTextAlignment(.center)
            .minimumScaleFactor(0.52)
            .allowsTightening(true)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, 10)
            .background(cardShape.fill(state.fillColor))
            .overlay(cardShape.stroke(state.strokeColor, lineWidth: state.lineWidth))
            .shadow(color: state.shadowColor, radius: 10, x: 0, y: 4)
    }

    private var cardShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: 22, style: .continuous)
    }
}

private struct MatchPictureCard: View {
    let illustration: WordIllustration
    let state: WordMatchCardState
    let imageSize: CGFloat

    var body: some View {
        ZStack {
            cardShape.fill(state.fillColor)

            WordIllustrationImage(illustration: illustration, imageSize: imageSize)
                .padding(4)
        }
        .overlay(cardShape.stroke(state.strokeColor, lineWidth: state.lineWidth))
        .shadow(color: state.shadowColor, radius: 10, x: 0, y: 4)
    }

    private var cardShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: 22, style: .continuous)
    }
}

private struct WordIllustrationImage: View {
    let illustration: WordIllustration
    let imageSize: CGFloat

    var body: some View {
        Group {
            switch illustration {
            case .asset(let name):
                Image(name)
                    .resizable()
                    .scaledToFit()
            case .bundlePNG(let name):
                if let image = WordImageStore.shared.image(named: name) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.white.opacity(0.7))

                        Image(systemName: "photo")
                            .font(.system(size: imageSize * 0.34, weight: .bold))
                            .foregroundStyle(Color.gray.opacity(0.7))
                    }
                }
            }
        }
        .frame(width: imageSize, height: imageSize)
    }
}

@MainActor
private final class WordImageStore {
    static let shared = WordImageStore()

    private var cache: [String: UIImage] = [:]

    func image(named name: String) -> UIImage? {
        if let cached = cache[name] {
            return cached
        }

        guard
            let url = Bundle.main.url(forResource: name, withExtension: "png", subdirectory: "WordImages"),
            let image = UIImage(contentsOfFile: url.path)
        else {
            return nil
        }

        cache[name] = image
        return image
    }
}

private struct ConnectionLayerView: View {
    let connections: [WordMatchConnection]
    let points: [String: CGPoint]
    let compactHeight: Bool

    var body: some View {
        Canvas { context, _ in
            for connection in connections {
                guard
                    let start = points["word-\(connection.wordID.uuidString)"],
                    let end = points["picture-\(connection.pictureID.uuidString)"]
                else {
                    continue
                }

                var path = Path()
                path.move(to: start)
                path.addCurve(
                    to: end,
                    control1: CGPoint(x: start.x + 44, y: start.y),
                    control2: CGPoint(x: end.x - 44, y: end.y)
                )

                context.stroke(
                    path,
                    with: .color(.white.opacity(0.96)),
                    style: StrokeStyle(
                        lineWidth: compactHeight ? 8 : 10,
                        lineCap: .round,
                        lineJoin: .round
                    )
                )

                context.stroke(
                    path,
                    with: .color(connection.isCorrect ? .green : .red),
                    style: StrokeStyle(
                        lineWidth: compactHeight ? 4 : 5,
                        lineCap: .round,
                        lineJoin: .round
                    )
                )
            }
        }
        .allowsHitTesting(false)
    }
}

private struct MatchPointPreferenceKey: PreferenceKey {
    static var defaultValue: [String: CGPoint] = [:]

    static func reduce(value: inout [String: CGPoint], nextValue: () -> [String: CGPoint]) {
        value.merge(nextValue(), uniquingKeysWith: { _, new in new })
    }
}

private extension WordMatchCardState {
    var accessibilityValue: String {
        switch self {
        case .idle:
            return "idle"
        case .selected:
            return "selected"
        case .correct:
            return "correct"
        case .incorrect:
            return "incorrect"
        }
    }

    var fillColor: Color {
        switch self {
        case .idle:
            return .white.opacity(0.94)
        case .selected:
            return Color(red: 1.00, green: 0.95, blue: 0.76)
        case .correct:
            return Color(red: 0.89, green: 0.97, blue: 0.90)
        case .incorrect:
            return Color(red: 0.99, green: 0.90, blue: 0.90)
        }
    }

    var strokeColor: Color {
        switch self {
        case .idle:
            return Color.black.opacity(0.08)
        case .selected:
            return Color(red: 0.96, green: 0.67, blue: 0.18)
        case .correct:
            return Color(red: 0.18, green: 0.63, blue: 0.39)
        case .incorrect:
            return Color(red: 0.86, green: 0.22, blue: 0.25)
        }
    }

    var lineWidth: CGFloat {
        switch self {
        case .idle:
            return 1
        case .selected, .correct, .incorrect:
            return 3
        }
    }

    var shadowColor: Color {
        switch self {
        case .selected:
            return strokeColor.opacity(0.22)
        case .correct, .incorrect:
            return strokeColor.opacity(0.16)
        case .idle:
            return Color.black.opacity(0.05)
        }
    }
}

struct WordsTrainerScreen_Previews: PreviewProvider {
    static var previews: some View {
        WordsTrainerScreen()
    }
}
