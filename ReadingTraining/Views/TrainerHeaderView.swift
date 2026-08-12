import SwiftUI

struct TrainerHeaderView: View {
    let compactHeight: Bool

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            Image("ReadingHero")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(maxWidth: .infinity)
                .frame(height: compactHeight ? 94 : 112)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text("Читаем слоги")
                    .font(.system(size: compactHeight ? 26 : 30, weight: .black, design: .rounded))
                    .foregroundStyle(Color(red: 0.14, green: 0.20, blue: 0.28))
                    .padding(.leading, 80)

                Text("Нажмите прямо на букву в слоге, чтобы выбрать ее.")
                    .font(.system(size: compactHeight ? 13 : 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color(red: 0.14, green: 0.20, blue: 0.28).opacity(0.82))
                    .padding(.leading, 80)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .shadow(color: Color.white.opacity(0.65), radius: 8, x: 0, y: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.white.opacity(0.35), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
}
