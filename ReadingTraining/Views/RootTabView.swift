import SwiftUI

struct RootTabView: View {
    private enum Tab: Hashable {
        case syllables
        case words
        case readAloud
    }

    @State private var selectedTab: Tab

    init() {
        let arguments = ProcessInfo.processInfo.arguments
        let initialTab: Tab

        if arguments.contains("UITestTabWords") {
            initialTab = .words
        } else if arguments.contains("UITestTabReadAloud") {
            initialTab = .readAloud
        } else {
            initialTab = .syllables
        }

        _selectedTab = State(initialValue: initialTab)
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            ContentView()
                .tabItem {
                    Label("Слоги", systemImage: "textformat.abc")
                }
                .tag(Tab.syllables)

            WordsTrainerScreen()
                .tabItem {
                    Label("Слова", systemImage: "text.book.closed.fill")
                }
                .tag(Tab.words)

            ReadAloudTrainerScreen()
                .tabItem {
                    Label("Прочитай", systemImage: "gift.fill")
                }
                .tag(Tab.readAloud)
        }
        .tint(Color(red: 0.18, green: 0.48, blue: 0.78))
    }
}

struct RootTabView_Previews: PreviewProvider {
    static var previews: some View {
        RootTabView()
    }
}
