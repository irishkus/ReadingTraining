import SwiftUI

struct RootTabView: View {
    var body: some View {
        TabView {
            ContentView()
                .tabItem {
                    Label("Слоги", systemImage: "textformat.abc")
                }

            WordsTrainerScreen()
                .tabItem {
                    Label("Слова", systemImage: "text.book.closed.fill")
                }

            ReadAloudTrainerScreen()
                .tabItem {
                    Label("Прочитай", systemImage: "gift.fill")
                }
        }
        .tint(Color(red: 0.18, green: 0.48, blue: 0.78))
    }
}

struct RootTabView_Previews: PreviewProvider {
    static var previews: some View {
        RootTabView()
    }
}
