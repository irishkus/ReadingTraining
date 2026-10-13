import SwiftUI

struct RootTabView: View {
    private enum Tab: Hashable {
        case reading
        case russian
    }

    @State private var selectedTab: Tab
    @State private var readingPath: [ReadingExerciseRoute]
    @State private var russianPath: [RussianExerciseRoute]

    init() {
        let arguments = ProcessInfo.processInfo.arguments
        var initialTab: Tab = .reading
        var initialReadingPath: [ReadingExerciseRoute] = []
        var initialRussianPath: [RussianExerciseRoute] = []

        if arguments.contains("UITestTabWords") {
            initialReadingPath = [.words]
        } else if arguments.contains("UITestTabReadAloud") {
            initialReadingPath = [.readAloud]
        } else if arguments.contains("UITestTabWordBuilder") {
            initialTab = .russian
            initialRussianPath = [.wordBuilder]
        } else if arguments.contains("UITestTabVowels") {
            initialTab = .russian
            initialRussianPath = [.vowels]
        } else if arguments.contains("UITestTabSyllables") {
            initialReadingPath = [.syllables]
        }

        _selectedTab = State(initialValue: initialTab)
        _readingPath = State(initialValue: initialReadingPath)
        _russianPath = State(initialValue: initialRussianPath)
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack(path: $readingPath) {
                ReadingExerciseMenu()
                    .navigationDestination(for: ReadingExerciseRoute.self) { route in
                        switch route {
                        case .syllables:
                            ContentView()
                                .exerciseNavigationBar()
                        case .words:
                            WordsTrainerScreen()
                                .exerciseNavigationBar()
                        case .readAloud:
                            ReadAloudTrainerScreen()
                                .exerciseNavigationBar()
                        }
                    }
            }
                .tabItem {
                    Label("Чтение", systemImage: "book.fill")
                }
                .tag(Tab.reading)

            NavigationStack(path: $russianPath) {
                RussianExerciseMenu()
                    .navigationDestination(for: RussianExerciseRoute.self) { route in
                        switch route {
                        case .wordBuilder:
                            WordBuilderScreen()
                                .exerciseNavigationBar()
                        case .vowels:
                            VowelFinderScreen()
                                .exerciseNavigationBar()
                        }
                    }
            }
                .tabItem {
                    Label("Русский", systemImage: "textformat")
                }
                .tag(Tab.russian)
        }
        .tint(Color(red: 0.18, green: 0.48, blue: 0.78))
    }
}

private extension View {
    func exerciseNavigationBar() -> some View {
        modifier(ExerciseNavigationBarModifier())
    }
}

private struct ExerciseNavigationBarModifier: ViewModifier {
    @Environment(\.dismiss) private var dismiss

    func body(content: Content) -> some View {
        content
            .toolbar(.visible, for: .navigationBar)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Label("Назад", systemImage: "chevron.left")
                    }
                    .accessibilityIdentifier("navigation.back")
                }
            }
    }
}

struct RootTabView_Previews: PreviewProvider {
    static var previews: some View {
        RootTabView()
    }
}
