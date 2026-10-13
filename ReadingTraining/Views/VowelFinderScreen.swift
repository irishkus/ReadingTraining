import SwiftUI

struct VowelFinderScreen: View {
    @StateObject private var viewModel = VowelFinderViewModel()

    private let vowelRed = Color(red: 0.88, green: 0.20, blue: 0.24)

    var body: some View {
        GeometryReader { proxy in
            let compact = proxy.size.height < 680

            ZStack {
                TrainerBackgroundView()

                VStack(spacing: compact ? 14 : 20) {
                    header(compact: compact)

                    VStack(spacing: compact ? 18 : 26) {
                        Text("Нажми на все гласные")
                            .font(.system(size: compact ? 20 : 23, weight: .black, design: .rounded))
                            .foregroundStyle(Color(red: 0.20, green: 0.29, blue: 0.38))

                        letterCells(availableWidth: proxy.size.width - 68, compact: compact)

                        legend(compact: compact)
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, compact ? 20 : 28)
                    .frame(maxWidth: .infinity, minHeight: compact ? 220 : 280)
                    .background(
                        RoundedRectangle(cornerRadius: 30, style: .continuous)
                            .fill(.white.opacity(0.82))
                    )
                    .shadow(color: Color.black.opacity(0.05), radius: 14, x: 0, y: 8)

                    actionButtons(compact: compact)

                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 16)
                .padding(.top, compact ? 12 : 18)
                .padding(.bottom, 12)
            }
        }
        .sheet(isPresented: $viewModel.isCelebrationPresented) {
            celebrationSheet
                .presentationDetents([.height(360)])
                .presentationDragIndicator(.visible)
        }
    }

    private func header(compact: Bool) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("Гласные")
                .font(.system(size: compact ? 28 : 32, weight: .black, design: .rounded))
                .foregroundStyle(Color(red: 0.19, green: 0.27, blue: 0.35))

            Text("Найди гласные буквы в слове.")
                .font(.system(size: compact ? 14 : 16, weight: .bold, design: .rounded))
                .foregroundStyle(.primary.opacity(0.62))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 18)
        .padding(.vertical, compact ? 13 : 16)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(.white.opacity(0.84))
        )
    }

    private func letterCells(availableWidth: CGFloat, compact: Bool) -> some View {
        let count = viewModel.letters.count
        let columnsCount = count > 8 ? Int(ceil(Double(count) / 2.0)) : count
        let spacing: CGFloat = compact ? 7 : 9
        let availableCellWidth = max(
            1,
            (availableWidth - CGFloat(max(columnsCount - 1, 0)) * spacing) / CGFloat(max(columnsCount, 1))
        )
        let size = min(compact ? 50 : 58, availableCellWidth)
        let rowCount = Int(ceil(Double(count) / Double(max(columnsCount, 1))))

        return VStack(spacing: spacing) {
            ForEach(0..<rowCount, id: \.self) { row in
                HStack(spacing: spacing) {
                    ForEach(indexRange(row: row, columnsCount: columnsCount, totalCount: count), id: \.self) { index in
                        letterButton(at: index, size: size)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
    }

    private func letterButton(at index: Int, size: CGFloat) -> some View {
        let isConfirmed = viewModel.confirmedVowelIndices.contains(index)
        let isIncorrect = viewModel.incorrectIndices.contains(index)
        let isSelected = viewModel.selectedIndices.contains(index)

        return Button {
            viewModel.toggleLetter(at: index)
        } label: {
            Text(viewModel.letters[index])
                .font(.system(size: min(34, size * 0.60), weight: .black, design: .rounded))
                .foregroundStyle(
                    isConfirmed
                        ? vowelRed
                        : Color(red: 0.20, green: 0.29, blue: 0.38)
                )
                .frame(width: size, height: size)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(cellColor(isConfirmed: isConfirmed, isIncorrect: isIncorrect, isSelected: isSelected))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(
                            borderColor(isConfirmed: isConfirmed, isIncorrect: isIncorrect, isSelected: isSelected),
                            lineWidth: 2.5
                        )
                )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("vowels.letter.\(index)")
        .accessibilityLabel(viewModel.letters[index])
        .accessibilityValue(cellAccessibilityValue(isConfirmed: isConfirmed, isIncorrect: isIncorrect, isSelected: isSelected))
    }

    private func legend(compact: Bool) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(vowelRed)
                .frame(width: 12, height: 12)

            Text("Гласные станут красными после проверки")
                .font(.system(size: compact ? 13 : 14, weight: .bold, design: .rounded))
                .foregroundStyle(.primary.opacity(0.58))
                .multilineTextAlignment(.center)
        }
    }

    private func actionButtons(compact: Bool) -> some View {
        HStack(spacing: 10) {
            Button {
                viewModel.checkAnswer()
            } label: {
                Label("Проверить", systemImage: "checkmark.circle.fill")
                    .font(.system(size: compact ? 16 : 17, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, compact ? 13 : 15)
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(Color(red: 0.18, green: 0.63, blue: 0.39))
                    )
            }
            .buttonStyle(.plain)
            .disabled(!viewModel.canCheck)
            .opacity(viewModel.canCheck ? 1 : 0.42)
            .accessibilityIdentifier("vowels.action.check")

            Button {
                viewModel.showAnotherWord()
            } label: {
                Label("Другое слово", systemImage: "arrow.clockwise")
                    .font(.system(size: compact ? 16 : 17, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(red: 0.21, green: 0.43, blue: 0.63))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, compact ? 13 : 15)
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(.white.opacity(0.86))
                    )
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("vowels.action.refresh")
        }
    }

    private var celebrationSheet: some View {
        VStack(spacing: 18) {
            Image(systemName: "star.circle.fill")
                .font(.system(size: 58, weight: .bold))
                .foregroundStyle(Color(red: 0.96, green: 0.67, blue: 0.15))

            Text("Молодец!")
                .font(.system(size: 34, weight: .black, design: .rounded))
                .foregroundStyle(Color(red: 0.19, green: 0.27, blue: 0.35))
                .accessibilityIdentifier("vowels.celebration.title")

            Text("Все гласные найдены")
                .font(.system(size: 19, weight: .bold, design: .rounded))
                .foregroundStyle(.primary.opacity(0.64))

            Button {
                viewModel.continueAfterCelebration()
            } label: {
                Text("Следующее слово")
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
            .accessibilityIdentifier("vowels.celebration.continue")
        }
        .padding(24)
    }

    private func cellColor(isConfirmed: Bool, isIncorrect: Bool, isSelected: Bool) -> Color {
        if isConfirmed { return .white.opacity(0.94) }
        if isIncorrect { return Color(red: 1.0, green: 0.88, blue: 0.70) }
        if isSelected { return Color(red: 0.84, green: 0.92, blue: 1.0) }
        return .white.opacity(0.94)
    }

    private func borderColor(isConfirmed: Bool, isIncorrect: Bool, isSelected: Bool) -> Color {
        if isConfirmed { return vowelRed.opacity(0.34) }
        if isIncorrect { return Color.orange.opacity(0.90) }
        if isSelected { return Color.blue.opacity(0.70) }
        return Color.blue.opacity(0.16)
    }

    private func cellAccessibilityValue(isConfirmed: Bool, isIncorrect: Bool, isSelected: Bool) -> String {
        if isConfirmed { return "Гласная" }
        if isIncorrect { return "Ошибка" }
        if isSelected { return "Выбрано" }
        return "Не выбрано"
    }

    private func indexRange(row: Int, columnsCount: Int, totalCount: Int) -> Range<Int> {
        let start = row * columnsCount
        return start..<min(start + columnsCount, totalCount)
    }
}

struct VowelFinderScreen_Previews: PreviewProvider {
    static var previews: some View {
        VowelFinderScreen()
    }
}
