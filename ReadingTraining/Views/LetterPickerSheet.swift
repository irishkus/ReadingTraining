import SwiftUI

struct LetterPickerSheet: View {
    let kind: LetterKind
    let caseMode: LetterCaseMode
    let letters: [String]
    let selectedLetter: String
    let onSelect: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var query = ""

    private let gridColumns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    private var normalizedQuery: String {
        query.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    }

    private var filteredLetters: [String] {
        guard !normalizedQuery.isEmpty else {
            return letters
        }

        return letters.filter { $0.contains(normalizedQuery) }
    }

    private var exactMatch: String? {
        letters.first(where: { $0 == normalizedQuery })
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 10) {
                    Text(kind.sheetDescription)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(.primary.opacity(0.72))

                    TextField("Введите букву", text: $query)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(Color(.systemBackground))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(kind.accentColor.opacity(0.2), lineWidth: 1)
                        )
                        .accessibilityIdentifier("picker.query")

                    if let exactMatch {
                        Button {
                            onSelect(exactMatch)
                            dismiss()
                        } label: {
                            HStack(spacing: 10) {
                                Text(caseMode.transform(exactMatch))
                                    .font(.system(size: 28, weight: .black, design: .rounded))

                                Text("Выбрать введенную букву")
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                            }
                            .foregroundStyle(kind.accentColor)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .fill(kind.accentColor.opacity(0.12))
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("picker.selectExact")
                    }
                }

                ScrollView(showsIndicators: false) {
                    LazyVGrid(columns: gridColumns, spacing: 10) {
                        ForEach(filteredLetters, id: \.self) { letter in
                            Button {
                                onSelect(letter)
                                dismiss()
                            } label: {
                                Text(caseMode.transform(letter))
                                    .font(.system(size: 32, weight: .black, design: .rounded))
                                    .foregroundStyle(letter == selectedLetter ? .white : kind.accentColor)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 64)
                                    .background(
                                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                                            .fill(letter == selectedLetter ? kind.accentColor : .white)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                                            .stroke(kind.accentColor.opacity(letter == selectedLetter ? 0 : 0.18), lineWidth: 1.2)
                                    )
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("picker.letter.\(letter)")
                            .accessibilityLabel(caseMode.transform(letter))
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .padding(16)
            .background(Color(.systemGroupedBackground))
            .navigationTitle(kind.sheetTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Готово") {
                        dismiss()
                    }
                }
            }
        }
        .onChange(of: query) { _, newValue in
            let filteredValue = String(newValue.filter(\.isLetter).prefix(1)).uppercased()
            if filteredValue != newValue {
                query = filteredValue
            }
        }
    }
}
