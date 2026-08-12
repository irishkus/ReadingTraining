import SwiftUI

struct SyllablePreviewView: View {
    let leftLetter: String
    let rightLetter: String
    let leftKind: LetterKind
    let rightKind: LetterKind
    let height: CGFloat
    let compactHeight: Bool
    let onTapLeft: () -> Void
    let onTapRight: () -> Void

    var body: some View {
        VStack(spacing: compactHeight ? 10 : 14) {
            VStack(spacing: 6) {
                Text("Текущий слог")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary.opacity(0.62))

                Text("Нажмите на букву чтобы сменить ее")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary.opacity(0.45))
            }

            HStack(spacing: -18) {
                letterButton(
                    letter: leftLetter,
                    kind: leftKind,
                    accessibilityIdentifier: "syllable.leftLetter",
                    action: onTapLeft
                )
                letterButton(
                    letter: rightLetter,
                    kind: rightKind,
                    accessibilityIdentifier: "syllable.rightLetter",
                    action: onTapRight
                )
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .padding(.horizontal, 10)
        .padding(.vertical, compactHeight ? 14 : 18)
        .background(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(.white.opacity(0.82))
        )
        .shadow(color: Color.black.opacity(0.06), radius: 16, x: 0, y: 8)
        .accessibilityIdentifier("syllable.preview")
    }

    private func letterButton(
        letter: String,
        kind: LetterKind,
        accessibilityIdentifier: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(letter)
                .font(.system(size: compactHeight ? 196 : 226, weight: .black, design: .rounded))
                .foregroundStyle(kind.accentColor)
                .lineLimit(1)
                .minimumScaleFactor(0.36)
                .padding(.horizontal, 2)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(accessibilityIdentifier)
        .accessibilityLabel(letter)
    }
}
