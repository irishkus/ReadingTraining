import SwiftUI

enum ReadingExerciseRoute: Hashable {
    case syllables
    case words
    case readAloud
}

enum RussianExerciseRoute: Hashable {
    case wordBuilder
    case vowels
}

struct ReadingExerciseMenu: View {
    var body: some View {
        ExerciseMenuView(
            title: "Чтение",
            subtitle: "Выберите упражнение",
            items: [
                ExerciseMenuItem(
                    route: ReadingExerciseRoute.syllables,
                    title: "Слоги",
                    subtitle: "Учимся соединять буквы",
                    systemImage: "textformat.abc",
                    color: Color(red: 0.20, green: 0.56, blue: 0.78),
                    accessibilityIdentifier: "menu.reading.syllables"
                ),
                ExerciseMenuItem(
                    route: ReadingExerciseRoute.words,
                    title: "Слова",
                    subtitle: "Соединяем слова и картинки",
                    systemImage: "photo.on.rectangle.angled",
                    color: Color(red: 0.20, green: 0.66, blue: 0.43),
                    accessibilityIdentifier: "menu.reading.words"
                ),
                ExerciseMenuItem(
                    route: ReadingExerciseRoute.readAloud,
                    title: "Прочитай",
                    subtitle: "Читаем слова вслух",
                    systemImage: "waveform",
                    color: Color(red: 0.94, green: 0.55, blue: 0.24),
                    accessibilityIdentifier: "menu.reading.readAloud"
                )
            ]
        )
    }
}

struct RussianExerciseMenu: View {
    var body: some View {
        ExerciseMenuView(
            title: "Русский",
            subtitle: "Выберите упражнение",
            items: [
                ExerciseMenuItem(
                    route: RussianExerciseRoute.wordBuilder,
                    title: "Составь слово",
                    subtitle: "Собираем слово из букв",
                    systemImage: "square.grid.3x3.fill",
                    color: Color(red: 0.76, green: 0.39, blue: 0.30),
                    accessibilityIdentifier: "menu.russian.wordBuilder"
                ),
                ExerciseMenuItem(
                    route: RussianExerciseRoute.vowels,
                    title: "Гласные",
                    subtitle: "Находим гласные в словах",
                    systemImage: "character.cursor.ibeam",
                    color: Color(red: 0.88, green: 0.28, blue: 0.30),
                    accessibilityIdentifier: "menu.russian.vowels"
                )
            ]
        )
    }
}

private struct ExerciseMenuItem<Route: Hashable>: Identifiable {
    let route: Route
    let title: String
    let subtitle: String
    let systemImage: String
    let color: Color
    let accessibilityIdentifier: String

    var id: Route { route }
}

private struct ExerciseMenuView<Route: Hashable>: View {
    let title: String
    let subtitle: String
    let items: [ExerciseMenuItem<Route>]

    var body: some View {
        ZStack {
            TrainerBackgroundView()

            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(title)
                        .font(.system(size: 36, weight: .black, design: .rounded))
                        .foregroundStyle(Color(red: 0.18, green: 0.27, blue: 0.36))

                    Text(subtitle)
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary.opacity(0.56))
                }
                .padding(.horizontal, 4)

                VStack(spacing: 14) {
                    ForEach(items) { item in
                        NavigationLink(value: item.route) {
                            ExerciseMenuRow(item: item)
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier(item.accessibilityIdentifier)
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 18)
            .padding(.top, 24)
        }
        .navigationBarHidden(true)
    }
}

private struct ExerciseMenuRow<Route: Hashable>: View {
    let item: ExerciseMenuItem<Route>

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: item.systemImage)
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 60, height: 60)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(item.color)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.system(size: 23, weight: .black, design: .rounded))
                    .foregroundStyle(Color(red: 0.18, green: 0.27, blue: 0.36))

                Text(item.subtitle)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary.opacity(0.55))
            }

            Spacer(minLength: 8)

            Image(systemName: "chevron.right")
                .font(.system(size: 17, weight: .black))
                .foregroundStyle(item.color.opacity(0.75))
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 92)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(.white.opacity(0.86))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(.white.opacity(0.66), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 12, x: 0, y: 7)
    }
}
