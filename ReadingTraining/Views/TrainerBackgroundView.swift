import SwiftUI

struct TrainerBackgroundView: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.97, green: 0.93, blue: 0.84),
                    Color(red: 0.86, green: 0.95, blue: 0.90),
                    Color(red: 0.82, green: 0.91, blue: 0.97)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Circle()
                .fill(Color.white.opacity(0.22))
                .frame(width: 260, height: 260)
                .offset(x: -150, y: -250)

            Circle()
                .fill(Color.white.opacity(0.14))
                .frame(width: 320, height: 320)
                .offset(x: 160, y: 310)
        }
    }
}
