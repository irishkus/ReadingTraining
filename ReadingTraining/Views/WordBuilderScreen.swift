import SwiftUI

struct WordBuilderScreen: View {
    @StateObject private var viewModel = WordBuilderViewModel()

    var body: some View {
        GeometryReader { proxy in
            let compact = proxy.size.height < 720

            ZStack {
                TrainerBackgroundView()

                VStack(spacing: compact ? 10 : 14) {
                    header(compact: compact)
                    pictureCard(compact: compact)
                    letterSlots(availableWidth: proxy.size.width - 32, compact: compact)
                    availableLetters(availableWidth: proxy.size.width - 32, compact: compact)
                    actionButtons(compact: compact)
                }
                .padding(.horizontal, 16)
                .padding(.top, compact ? 10 : 14)
                .padding(.bottom, compact ? 8 : 12)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
        }
        .sheet(isPresented: $viewModel.isCelebrationPresented) {
            celebrationSheet
                .presentationDetents([.height(390)])
                .presentationDragIndicator(.visible)
        }
    }

    private func header(compact: Bool) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Составь слово")
                .font(.system(size: compact ? 27 : 31, weight: .black, design: .rounded))
                .foregroundStyle(Color(red: 0.19, green: 0.27, blue: 0.35))

            Text("Выбирай буквы снизу и составляй слово.")
                .font(.system(size: compact ? 14 : 15, weight: .bold, design: .rounded))
                .foregroundStyle(.primary.opacity(0.68))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 18)
        .padding(.vertical, compact ? 12 : 15)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(.white.opacity(0.84))
        )
        .shadow(color: Color.black.opacity(0.05), radius: 12, x: 0, y: 7)
    }

    private func pictureCard(compact: Bool) -> some View {
        WordIllustrationImage(
            illustration: viewModel.currentPair.illustration,
            imageSize: compact ? 140 : 180
        )
        .frame(maxWidth: .infinity)
        .frame(height: compact ? 154 : 198)
        .background(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(.white.opacity(0.78))
        )
        .shadow(color: Color.black.opacity(0.05), radius: 14, x: 0, y: 8)
        .accessibilityIdentifier("wordBuilder.picture.\(viewModel.currentPair.key)")
    }

    private func letterSlots(availableWidth: CGFloat, compact: Bool) -> some View {
        let count = viewModel.letters.count
        let columnsCount = count > 8 ? Int(ceil(Double(count) / 2.0)) : count
        let spacing: CGFloat = compact ? 5 : 7
        let calculatedWidth = max(
            1,
            (availableWidth - 24 - CGFloat(max(columnsCount - 1, 0)) * spacing) / CGFloat(max(columnsCount, 1))
        )
        let slotSize = min(compact ? 48 : 54, calculatedWidth)
        let rowCount = Int(ceil(Double(count) / Double(max(columnsCount, 1))))

        return VStack(spacing: spacing) {
            ForEach(0..<rowCount, id: \.self) { row in
                HStack(spacing: spacing) {
                    ForEach(slotRange(row: row, columnsCount: columnsCount, totalCount: count), id: \.self) { index in
                        Button {
                            viewModel.returnLetter(at: index)
                        } label: {
                            Text(viewModel.letters[index] ?? "")
                                .font(.system(size: min(30, slotSize * 0.58), weight: .black, design: .rounded))
                                .foregroundStyle(Color(red: 0.18, green: 0.42, blue: 0.68))
                                .frame(width: slotSize, height: slotSize)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(.white.opacity(0.90))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(
                                            viewModel.isIncorrect ? Color.red.opacity(0.78) : Color.blue.opacity(0.24),
                                            lineWidth: viewModel.isIncorrect ? 2.5 : 1.5
                                        )
                                )
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("wordBuilder.slot.\(index)")
                        .accessibilityLabel("Буква \(index + 1)")
                        .accessibilityValue(viewModel.letters[index] ?? "Пусто")
                        .disabled(viewModel.letters[index] == nil)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .frame(maxWidth: .infinity, minHeight: compact ? 54 : 62)
        .animation(.easeInOut(duration: 0.2), value: viewModel.isIncorrect)
    }

    private func availableLetters(availableWidth: CGFloat, compact: Bool) -> some View {
        let columnsCount = compact ? 7 : 8
        let spacing: CGFloat = compact ? 6 : 8
        let tileSize = min(
            compact ? 42 : 46,
            max(1, (availableWidth - CGFloat(columnsCount - 1) * spacing) / CGFloat(columnsCount))
        )
        let rowCount = Int(ceil(Double(viewModel.availableLetters.count) / Double(columnsCount)))

        return VStack(spacing: spacing) {
            ForEach(0..<rowCount, id: \.self) { row in
                HStack(spacing: spacing) {
                    ForEach(
                        slotRange(row: row, columnsCount: columnsCount, totalCount: viewModel.availableLetters.count),
                        id: \.self
                    ) { index in
                        let letter = viewModel.availableLetters[index]

                        Button {
                            viewModel.useLetter(letter)
                        } label: {
                            Text(letter.value)
                                .font(.system(size: compact ? 24 : 27, weight: .black, design: .rounded))
                                .foregroundStyle(Color(red: 0.22, green: 0.35, blue: 0.49))
                                .frame(width: tileSize, height: compact ? 40 : 46)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(Color(red: 1.0, green: 0.86, blue: 0.52).opacity(0.88))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(.white.opacity(0.72), lineWidth: 1.5)
                                )
                        }
                        .buttonStyle(.plain)
                        .opacity(letter.isUsed ? 0 : 1)
                        .disabled(letter.isUsed)
                        .accessibilityHidden(letter.isUsed)
                        .accessibilityIdentifier("wordBuilder.choice.\(letter.id.uuidString)")
                        .accessibilityLabel(letter.value)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .frame(maxWidth: .infinity, minHeight: compact ? 86 : 100, alignment: .top)
        .animation(.easeInOut(duration: 0.16), value: viewModel.availableLetters)
    }

    private func slotRange(row: Int, columnsCount: Int, totalCount: Int) -> Range<Int> {
        let start = row * columnsCount
        return start..<min(start + columnsCount, totalCount)
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
            .disabled(!viewModel.isComplete)
            .opacity(viewModel.isComplete ? 1 : 0.42)
            .accessibilityIdentifier("wordBuilder.action.check")

            Button {
                viewModel.showAnotherPicture()
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
            .accessibilityIdentifier("wordBuilder.action.refresh")
        }
    }

    private var celebrationSheet: some View {
        VStack(spacing: 16) {
            Image(systemName: "star.circle.fill")
                .font(.system(size: 58, weight: .bold))
                .foregroundStyle(Color(red: 0.96, green: 0.67, blue: 0.15))

            Text("Молодец!")
                .font(.system(size: 34, weight: .black, design: .rounded))
                .foregroundStyle(Color(red: 0.19, green: 0.27, blue: 0.35))
                .accessibilityIdentifier("wordBuilder.celebration.title")

            Text("Слово составлено правильно")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(.primary.opacity(0.66))

            Text(viewModel.currentPair.word)
                .font(.system(size: 30, weight: .black, design: .rounded))
                .foregroundStyle(Color(red: 0.18, green: 0.63, blue: 0.39))

            Button {
                viewModel.continueAfterCelebration()
            } label: {
                Text("Следующая картинка")
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
            .accessibilityIdentifier("wordBuilder.celebration.continue")
        }
        .padding(24)
    }
}

struct WordBuilderScreen_Previews: PreviewProvider {
    static var previews: some View {
        WordBuilderScreen()
    }
}
