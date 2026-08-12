import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = SyllableTrainerViewModel()

    var body: some View {
        GeometryReader { proxy in
            let compactHeight = proxy.size.height < 760
            let previewHeight = min(max(proxy.size.height * 0.42, 270), 360)
            let stackSpacing: CGFloat = compactHeight ? 10 : 14

            ZStack {
                TrainerBackgroundView()

                VStack(spacing: stackSpacing) {
                    TrainerHeaderView(compactHeight: compactHeight)
                    caseModePicker

                    SyllablePreviewView(
                        leftLetter: viewModel.displayedLetter(for: viewModel.leftKind),
                        rightLetter: viewModel.displayedLetter(for: viewModel.rightKind),
                        leftKind: viewModel.leftKind,
                        rightKind: viewModel.rightKind,
                        height: previewHeight,
                        compactHeight: compactHeight,
                        onTapLeft: { viewModel.openPicker(for: viewModel.leftKind) },
                        onTapRight: { viewModel.openPicker(for: viewModel.rightKind) }
                    )

                    HStack(spacing: 10) {
                        RandomChoiceButton(
                            kind: viewModel.leftKind,
                            accessibilityIdentifier: "action.random.left"
                        ) {
                            viewModel.randomize(viewModel.leftKind)
                        }

                        RandomChoiceButton(
                            kind: viewModel.rightKind,
                            accessibilityIdentifier: "action.random.right"
                        ) {
                            viewModel.randomize(viewModel.rightKind)
                        }
                    }

                    swapButton
                }
                .padding(.horizontal, 16)
                .padding(.vertical, compactHeight ? 12 : 16)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .sheet(item: $viewModel.activePicker) { picker in
            LetterPickerSheet(
                kind: picker.kind,
                caseMode: viewModel.letterCaseMode,
                letters: viewModel.letters(for: picker.kind),
                selectedLetter: selectedRawLetter(for: picker.kind)
            ) { newLetter in
                viewModel.select(newLetter, for: picker.kind)
            }
            .presentationDetents([.fraction(0.58), .large])
            .presentationDragIndicator(.visible)
        }
    }

    private var caseModePicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Форма букв")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(.primary.opacity(0.78))

            Picker("Форма букв", selection: $viewModel.letterCaseMode) {
                ForEach(LetterCaseMode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .accessibilityIdentifier("caseMode.picker")
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.white.opacity(0.74))
        )
    }

    private var swapButton: some View {
        Button {
            withAnimation(.spring(response: 0.34, dampingFraction: 0.78)) {
                viewModel.toggleOrder()
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "arrow.left.arrow.right.circle.fill")
                    .font(.system(size: 20, weight: .bold))

                Text("Поменять местами")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.12, green: 0.56, blue: 0.74),
                                Color(red: 0.22, green: 0.45, blue: 0.86)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
        }
        .buttonStyle(.plain)
        .shadow(color: Color.black.opacity(0.08), radius: 14, x: 0, y: 8)
        .accessibilityIdentifier("action.swap")
    }

    private func selectedRawLetter(for kind: LetterKind) -> String {
        switch kind {
        case .vowel:
            return viewModel.selectedVowel
        case .consonant:
            return viewModel.selectedConsonant
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
