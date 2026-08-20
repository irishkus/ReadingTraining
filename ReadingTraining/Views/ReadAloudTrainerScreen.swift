import SwiftUI

struct ReadAloudTrainerScreen: View {
    @StateObject private var viewModel = ReadAloudTrainerViewModel()

    var body: some View {
        GeometryReader { proxy in
            let compactHeight = proxy.size.height < 760
            let verticalSpacing: CGFloat = compactHeight ? 10 : 14

            ZStack {
                TrainerBackgroundView()

                VStack(spacing: verticalSpacing) {
                    header(compactHeight: compactHeight)
                    boxesGrid(compactHeight: compactHeight)
                }
                .padding(.horizontal, 16)
                .padding(.top, compactHeight ? 12 : 16)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

                if let pair = viewModel.celebrationPair {
                    celebrationOverlay(for: pair, compactHeight: compactHeight)
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                footer(compactHeight: compactHeight)
                    .padding(.horizontal, 16)
                    .padding(.top, verticalSpacing)
                    .padding(.bottom, compactHeight ? 6 : 8)
            }
        }
        .sheet(isPresented: $viewModel.isRoundCelebrationPresented, onDismiss: viewModel.dismissRoundCelebration) {
            roundCelebrationSheet
                .presentationDetents([.height(400)])
                .presentationDragIndicator(.visible)
                .celebrationSheetCorners()
        }
        .animation(.spring(response: 0.34, dampingFraction: 0.82), value: viewModel.celebrationPair?.id)
    }

    private func header(compactHeight: Bool) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Прочитай")
                .font(.system(size: compactHeight ? 28 : 32, weight: .black, design: .rounded))
                .foregroundStyle(Color(red: 0.19, green: 0.27, blue: 0.35))

            Text("Нажмите на коробку и прочитайте слово вслух.")
                .font(.system(size: compactHeight ? 14 : 15, weight: .bold, design: .rounded))
                .foregroundStyle(.primary.opacity(0.74))

            Text(transcriptPlaceholder)
                .font(.system(size: compactHeight ? 13 : 14, weight: .semibold, design: .rounded))
                .foregroundStyle(
                    viewModel.recognizedText.isEmpty
                        ? .primary.opacity(0.34)
                        : Color(red: 0.30, green: 0.42, blue: 0.57)
                )
                .lineLimit(2)
                .minimumScaleFactor(0.72)
                .frame(maxWidth: .infinity, minHeight: compactHeight ? 36 : 40, alignment: .topLeading)
                .accessibilityIdentifier("read.transcript")
        }
        .frame(
            maxWidth: .infinity,
            minHeight: compactHeight ? 122 : 132,
            alignment: .topLeading
        )
        .padding(.horizontal, 18)
        .padding(.vertical, compactHeight ? 14 : 16)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(.white.opacity(0.82))
        )
        .shadow(color: Color.black.opacity(0.06), radius: 14, x: 0, y: 8)
    }

    private var transcriptPlaceholder: String {
        if viewModel.recognizedText.isEmpty {
            return "Здесь будет распознанный текст."
        }

        return "Слышу: \(viewModel.recognizedText)"
    }

    private func boxesGrid(compactHeight: Bool) -> some View {
        GeometryReader { proxy in
            let rows = viewModel.pairs.chunked(into: 2)
            let rowCount = max(rows.count, 1)
            let rowSpacing: CGFloat = compactHeight ? 14 : 18
            let boxHeight = min(
                compactHeight ? 126 : 140,
                max(
                    compactHeight ? 86 : 96,
                    (proxy.size.height - CGFloat(rowCount - 1) * rowSpacing) / CGFloat(rowCount)
                )
            )

            VStack(spacing: rowSpacing) {
                ForEach(Array(rows.enumerated()), id: \.offset) { rowIndex, row in
                    HStack(spacing: compactHeight ? 12 : 16) {
                        ForEach(Array(row.enumerated()), id: \.element.id) { columnIndex, pair in
                            let paletteIndex = (rowIndex * 2 + columnIndex) % ReadGiftBoxStyle.palette.count

                            Button {
                                viewModel.selectPair(pair)
                            } label: {
                                ReadGiftBoxCard(
                                    word: pair.word,
                                    state: viewModel.cardState(for: pair.id),
                                    style: ReadGiftBoxStyle.palette[paletteIndex],
                                    compactHeight: compactHeight
                                )
                            }
                            .buttonStyle(.plain)
                            .frame(maxWidth: .infinity)
                            .frame(height: boxHeight)
                            .accessibilityIdentifier("read.box.\(pair.key)")
                            .accessibilityLabel(pair.word)
                            .accessibilityValue(viewModel.cardState(for: pair.id).accessibilityValue)
                        }

                        if row.count == 1 {
                            Color.clear
                                .frame(maxWidth: .infinity)
                                .frame(height: boxHeight)
                        }
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, compactHeight ? 12 : 14)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .fill(.white.opacity(0.80))
            )
            .shadow(color: Color.black.opacity(0.06), radius: 16, x: 0, y: 8)
        }
    }

    private func footer(compactHeight: Bool) -> some View {
        HStack(spacing: 12) {
            Text("Открыто: \(viewModel.completedCount) из \(viewModel.totalCount)")
                .font(.system(size: compactHeight ? 16 : 17, weight: .black, design: .rounded))
                .foregroundStyle(Color(red: 0.22, green: 0.30, blue: 0.38))

            Spacer(minLength: 0)

            Button {
                viewModel.startNewRound()
            } label: {
                Text("Новый набор")
                    .font(.system(size: compactHeight ? 15 : 16, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(red: 0.18, green: 0.48, blue: 0.78))
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    .background(
                        Capsule()
                            .fill(.white.opacity(0.88))
                    )
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("read.action.restart")
        }
        .padding(.horizontal, 18)
        .padding(.vertical, compactHeight ? 12 : 14)
        .frame(height: compactHeight ? 72 : 76)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(.white.opacity(0.76))
        )
    }

    private func celebrationOverlay(for pair: WordMatchPair, compactHeight: Bool) -> some View {
        ZStack {
            Color.black.opacity(0.18)
                .ignoresSafeArea()
                .onTapGesture {
                    viewModel.dismissCelebration()
                }

            FireworksOverlayView()
                .allowsHitTesting(false)

            VStack(spacing: compactHeight ? 14 : 16) {
                Text("Молодец!")
                    .font(.system(size: compactHeight ? 28 : 32, weight: .black, design: .rounded))
                    .foregroundStyle(Color(red: 0.19, green: 0.27, blue: 0.35))
                    .accessibilityIdentifier("read.celebration.title")

                WordIllustrationImage(
                    illustration: pair.illustration,
                    imageSize: compactHeight ? 160 : 190
                )
                .padding(.vertical, 8)

                Text(pair.word)
                    .font(.system(size: compactHeight ? 24 : 28, weight: .black, design: .rounded))
                    .foregroundStyle(Color(red: 0.22, green: 0.30, blue: 0.38))
                    .multilineTextAlignment(.center)

                Button {
                    viewModel.dismissCelebration()
                } label: {
                    Text("Дальше")
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
                .accessibilityIdentifier("read.celebration.continue")
            }
            .padding(24)
            .frame(maxWidth: compactHeight ? 320 : 360)
            .background(
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .fill(.white.opacity(0.96))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .stroke(.white.opacity(0.88), lineWidth: 2)
            )
            .shadow(color: Color.black.opacity(0.12), radius: 18, x: 0, y: 10)
            .transition(.scale(scale: 0.94).combined(with: .opacity))
        }
    }

    private var roundCelebrationSheet: some View {
        VStack(spacing: 16) {
            Image(systemName: "star.circle.fill")
                .font(.system(size: 62))
                .foregroundStyle(Color(red: 0.98, green: 0.72, blue: 0.18))

            Text("Молодец!")
                .font(.system(size: 30, weight: .black, design: .rounded))
                .accessibilityIdentifier("read.roundCelebration.title")

            Text("Все коробки названы правильно.")
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundStyle(.primary.opacity(0.72))

            if let pair = viewModel.finalCelebrationPair {
                WordIllustrationImage(
                    illustration: pair.illustration,
                    imageSize: 92
                )
            }

            Button {
                viewModel.startNewRound()
            } label: {
                Text("Играть еще")
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
            .accessibilityIdentifier("read.roundCelebration.playAgain")
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
    }
}

private struct ReadGiftBoxCard: View {
    let word: String
    let state: ReadAloudCardState
    let style: ReadGiftBoxStyle
    let compactHeight: Bool

    private var bodySideDepth: CGFloat {
        compactHeight ? 18 : 22
    }

    var body: some View {
        ZStack(alignment: .top) {
            GiftBoxBodyView(
                style: style,
                state: state,
                compactHeight: compactHeight,
                sideDepth: bodySideDepth
            )

            GiftBoxLidView(style: style, compactHeight: compactHeight)

            HStack(spacing: 0) {
                Text(word)
                    .font(.system(size: compactHeight ? 24 : 27, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.52)
                    .allowsTightening(true)
                    .padding(.horizontal, 22)
                    .padding(.vertical, compactHeight ? 34 : 38)
                    .rotationEffect(.degrees(style.labelTilt))
                    .shadow(color: Color.black.opacity(0.26), radius: 2, x: 0, y: 2)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                Color.clear
                    .frame(width: bodySideDepth)
            }
            .offset(y: compactHeight ? 14 : 16)

            VStack {
                HStack {
                    Spacer(minLength: 0)

                    if state == .completed {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: compactHeight ? 22 : 24))
                            .foregroundStyle(.white, Color(red: 0.18, green: 0.63, blue: 0.39))
                    } else if state == .listening {
                        Image(systemName: "mic.circle.fill")
                            .font(.system(size: compactHeight ? 22 : 24))
                            .foregroundStyle(.white, Color(red: 0.16, green: 0.50, blue: 0.85))
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(12)
        }
        .shadow(color: state.shadowColor, radius: 10, x: 0, y: 6)
    }
}

private struct GiftBoxBodyView: View {
    let style: ReadGiftBoxStyle
    let state: ReadAloudCardState
    let compactHeight: Bool
    let sideDepth: CGFloat

    private var sideSlant: CGFloat {
        compactHeight ? 12 : 14
    }

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let height = proxy.size.height
            let frontWidth = max(width - sideDepth, 0)

            ZStack(alignment: .topLeading) {
                Rectangle()
                    .fill(style.bodyGradient)
                    .frame(width: frontWidth, height: height)

                GiftBoxPatternView(style: style)
                    .frame(width: frontWidth, height: height)
                    .clipped()

                GiftBoxBodySideFace(slant: sideSlant)
                    .fill(style.bodyColors.last ?? style.bodyColors.first ?? .clear)
                    .overlay(
                        GiftBoxBodySideFace(slant: sideSlant)
                            .fill(Color.black.opacity(0.10))
                    )
                    .frame(width: sideDepth, height: height)
                    .offset(x: frontWidth)

                Rectangle()
                    .stroke(state.strokeColor, lineWidth: state.lineWidth)
                    .frame(width: frontWidth, height: height)

                GiftBoxBodySideFace(slant: sideSlant)
                    .stroke(state.strokeColor, lineWidth: state.lineWidth)
                    .frame(width: sideDepth, height: height)
                    .offset(x: frontWidth)
            }
        }
    }
}

private struct GiftBoxBodySideFace: Shape {
    let slant: CGFloat

    func path(in rect: CGRect) -> Path {
        let clampedSlant = min(slant, rect.height * 0.25)
        var path = Path()

        path.move(to: CGPoint(x: rect.minX, y: rect.minY + clampedSlant))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - clampedSlant))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()

        return path
    }
}

private struct GiftBoxLidView: View {
    let style: ReadGiftBoxStyle
    let compactHeight: Bool

    private var topDepth: CGFloat {
        compactHeight ? 14 : 18
    }

    private var frontHeight: CGFloat {
        compactHeight ? 18 : 22
    }

    private var sideDepth: CGFloat {
        compactHeight ? 22 : 28
    }

    private var overhang: CGFloat {
        compactHeight ? 12 : 16
    }

    var body: some View {
        GeometryReader { proxy in
            let bodyWidth = proxy.size.width
            let lidWidth = bodyWidth + (overhang * 2)
            let frontWidth = max(lidWidth - sideDepth, 0)

            ZStack(alignment: .topLeading) {
                GiftBoxLidTopFace(skew: sideDepth)
                    .fill(style.lidTopColor)
                    .overlay(
                        GiftBoxLidTopFace(skew: sideDepth)
                            .stroke(Color.black.opacity(0.20), lineWidth: 1)
                    )
                    .frame(width: lidWidth, height: topDepth)

                Rectangle()
                    .fill(style.lidTopColor.opacity(0.90))
                    .overlay(
                        Rectangle()
                            .stroke(Color.black.opacity(0.20), lineWidth: 1)
                    )
                    .frame(width: frontWidth, height: frontHeight)
                    .offset(y: topDepth - 1)

                GiftBoxLidSideFace(topDepth: topDepth)
                    .fill(style.lidSideColor)
                    .overlay(
                        GiftBoxLidSideFace(topDepth: topDepth)
                            .stroke(Color.black.opacity(0.20), lineWidth: 1)
                    )
                    .frame(width: sideDepth, height: topDepth + frontHeight - 1)
                    .offset(x: frontWidth)
            }
            .offset(x: -overhang)
            .shadow(color: Color.black.opacity(0.15), radius: 3, x: 0, y: 2)
        }
        .frame(height: topDepth + frontHeight)
        .padding(.horizontal, 10)
        .offset(y: compactHeight ? -12 : -16)
    }
}

private struct GiftBoxLidTopFace: Shape {
    let skew: CGFloat

    func path(in rect: CGRect) -> Path {
        let clampedSkew = min(skew, rect.width * 0.24)
        var path = Path()

        path.move(to: CGPoint(x: rect.minX + clampedSkew, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - clampedSkew, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()

        return path
    }
}

private struct GiftBoxLidSideFace: Shape {
    let topDepth: CGFloat

    func path(in rect: CGRect) -> Path {
        let clampedDepth = min(topDepth, rect.height * 0.55)
        var path = Path()

        path.move(to: CGPoint(x: rect.minX, y: rect.minY + clampedDepth))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - clampedDepth))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

private struct GiftBoxPatternView: View {
    let style: ReadGiftBoxStyle

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let height = proxy.size.height

            ZStack {
                ForEach(0..<10, id: \.self) { index in
                    let x = width * style.horizontalFractions[index % style.horizontalFractions.count]
                    let y = height * style.verticalFractions[index % style.verticalFractions.count]

                    Image(systemName: style.patternSymbol)
                        .font(.system(size: min(width, height) * 0.10, weight: .bold))
                        .foregroundStyle(style.patternColor.opacity(0.28))
                        .position(x: x, y: y)
                }
            }
        }
        .allowsHitTesting(false)
    }
}

private struct FireworksOverlayView: View {
    @State private var animate = false

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                ForEach(FireworkParticle.sample) { particle in
                    Image(systemName: particle.symbol)
                        .font(.system(size: particle.size, weight: .bold))
                        .foregroundStyle(particle.color)
                        .position(
                            x: proxy.size.width * particle.origin.x,
                            y: proxy.size.height * particle.origin.y
                        )
                        .offset(
                            x: animate ? particle.offset.width : 0,
                            y: animate ? particle.offset.height : 0
                        )
                        .scaleEffect(animate ? particle.scale : 0.35)
                        .opacity(animate ? 0 : 1)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onAppear {
                animate = false
                withAnimation(.easeOut(duration: 1.15)) {
                    animate = true
                }
            }
        }
        .ignoresSafeArea()
    }
}

private struct FireworkParticle: Identifiable {
    let id = UUID()
    let symbol: String
    let origin: CGPoint
    let offset: CGSize
    let scale: CGFloat
    let size: CGFloat
    let color: Color

    static let sample: [FireworkParticle] = [
        FireworkParticle(symbol: "sparkle", origin: CGPoint(x: 0.32, y: 0.28), offset: CGSize(width: -68, height: -46), scale: 1.2, size: 22, color: .yellow),
        FireworkParticle(symbol: "star.fill", origin: CGPoint(x: 0.36, y: 0.30), offset: CGSize(width: 62, height: -58), scale: 1.1, size: 20, color: .orange),
        FireworkParticle(symbol: "circle.fill", origin: CGPoint(x: 0.68, y: 0.28), offset: CGSize(width: -74, height: -40), scale: 0.9, size: 14, color: .pink),
        FireworkParticle(symbol: "sparkles", origin: CGPoint(x: 0.72, y: 0.30), offset: CGSize(width: 66, height: -62), scale: 1.0, size: 18, color: .blue),
        FireworkParticle(symbol: "star.fill", origin: CGPoint(x: 0.24, y: 0.50), offset: CGSize(width: -58, height: 22), scale: 1.0, size: 16, color: .mint),
        FireworkParticle(symbol: "sparkle", origin: CGPoint(x: 0.78, y: 0.50), offset: CGSize(width: 60, height: 24), scale: 1.3, size: 22, color: .purple),
        FireworkParticle(symbol: "circle.fill", origin: CGPoint(x: 0.42, y: 0.72), offset: CGSize(width: -44, height: 58), scale: 0.85, size: 12, color: .yellow),
        FireworkParticle(symbol: "sparkles", origin: CGPoint(x: 0.58, y: 0.72), offset: CGSize(width: 46, height: 60), scale: 1.1, size: 18, color: .green)
    ]
}

private struct ReadGiftBoxStyle {
    let bodyColors: [Color]
    let lidTopColor: Color
    let lidSideColor: Color
    let patternSymbol: String
    let patternColor: Color
    let labelTilt: Double

    var bodyGradient: LinearGradient {
        LinearGradient(colors: bodyColors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    let horizontalFractions: [CGFloat] = [0.16, 0.34, 0.58, 0.80]
    let verticalFractions: [CGFloat] = [0.24, 0.42, 0.62, 0.80]

    static let palette: [ReadGiftBoxStyle] = [
        ReadGiftBoxStyle(
            bodyColors: [Color(red: 0.98, green: 0.85, blue: 0.18), Color(red: 0.93, green: 0.72, blue: 0.16)],
            lidTopColor: Color(red: 0.95, green: 0.79, blue: 0.10),
            lidSideColor: Color(red: 0.84, green: 0.67, blue: 0.06),
            patternSymbol: "circle.fill",
            patternColor: .white,
            labelTilt: -1.5
        ),
        ReadGiftBoxStyle(
            bodyColors: [Color(red: 0.83, green: 0.20, blue: 0.24), Color(red: 0.70, green: 0.12, blue: 0.17)],
            lidTopColor: Color(red: 0.82, green: 0.18, blue: 0.22),
            lidSideColor: Color(red: 0.68, green: 0.10, blue: 0.14),
            patternSymbol: "snowflake",
            patternColor: .white,
            labelTilt: 0.8
        ),
        ReadGiftBoxStyle(
            bodyColors: [Color(red: 0.20, green: 0.73, blue: 0.91), Color(red: 0.12, green: 0.58, blue: 0.79)],
            lidTopColor: Color(red: 0.17, green: 0.64, blue: 0.88),
            lidSideColor: Color(red: 0.11, green: 0.50, blue: 0.71),
            patternSymbol: "snowflake",
            patternColor: .white,
            labelTilt: -0.8
        ),
        ReadGiftBoxStyle(
            bodyColors: [Color(red: 0.44, green: 0.66, blue: 0.22), Color(red: 0.31, green: 0.52, blue: 0.14)],
            lidTopColor: Color(red: 0.39, green: 0.53, blue: 0.16),
            lidSideColor: Color(red: 0.28, green: 0.39, blue: 0.12),
            patternSymbol: "leaf.fill",
            patternColor: Color(red: 0.81, green: 0.91, blue: 0.72),
            labelTilt: 1.2
        ),
        ReadGiftBoxStyle(
            bodyColors: [Color(red: 0.96, green: 0.63, blue: 0.78), Color(red: 0.88, green: 0.44, blue: 0.65)],
            lidTopColor: Color(red: 0.89, green: 0.43, blue: 0.65),
            lidSideColor: Color(red: 0.75, green: 0.31, blue: 0.53),
            patternSymbol: "diamond.fill",
            patternColor: Color(red: 1.00, green: 0.88, blue: 0.93),
            labelTilt: -1.0
        ),
        ReadGiftBoxStyle(
            bodyColors: [Color(red: 0.94, green: 0.49, blue: 0.24), Color(red: 0.79, green: 0.29, blue: 0.16)],
            lidTopColor: Color(red: 0.80, green: 0.30, blue: 0.17),
            lidSideColor: Color(red: 0.65, green: 0.20, blue: 0.12),
            patternSymbol: "line.3.horizontal",
            patternColor: Color(red: 1.00, green: 0.84, blue: 0.68),
            labelTilt: 1.4
        )
    ]
}

private extension ReadAloudCardState {
    var accessibilityValue: String {
        switch self {
        case .idle:
            return "idle"
        case .listening:
            return "listening"
        case .completed:
            return "completed"
        }
    }

    var strokeColor: Color {
        switch self {
        case .idle:
            return Color.black.opacity(0.10)
        case .listening:
            return Color(red: 0.16, green: 0.50, blue: 0.85)
        case .completed:
            return Color(red: 0.18, green: 0.63, blue: 0.39)
        }
    }

    var lineWidth: CGFloat {
        switch self {
        case .idle:
            return 1
        case .listening, .completed:
            return 3
        }
    }

    var shadowColor: Color {
        switch self {
        case .idle:
            return Color.black.opacity(0.06)
        case .listening, .completed:
            return strokeColor.opacity(0.18)
        }
    }
}

private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        guard size > 0 else {
            return [self]
        }

        return stride(from: 0, to: count, by: size).map { index in
            Array(self[index ..< Swift.min(index + size, count)])
        }
    }
}

struct ReadAloudTrainerScreen_Previews: PreviewProvider {
    static var previews: some View {
        ReadAloudTrainerScreen()
    }
}

extension View {
    @ViewBuilder
    func celebrationSheetCorners() -> some View {
        if #available(iOS 16.4, *) {
            self.presentationCornerRadius(30)
        } else {
            self
        }
    }
}
