import SwiftUI

struct ShimmerEffectBox: View {
    @State private var startPoint = UnitPoint(x: -1.8, y: -1.2)
    @State private var endPoint = UnitPoint(x: 0, y: -0.2)
    var speed: CGFloat
    var colors: [Color]

    var body: some View {
        LinearGradient(
            colors: colors,
            startPoint: startPoint,
            endPoint: endPoint
        )
        .onAppear(perform: loopAnimation)
    }

    private func loopAnimation() {
        withAnimation(
            .easeInOut(duration: speed)
                .repeatForever(autoreverses: false)
        ) {
            startPoint = .init(x: 1, y: 1)
            endPoint = .init(x: 2.2, y: 2.2)
        }
    }
}

struct ShimmerModifier: ViewModifier {
    private var isActive: Bool
    private var speed: CGFloat
    private var colors: [Color] = [
        Color(uiColor: .systemGray5),
        Color(uiColor: .systemGray6),
        Color(uiColor: .systemGray5)
    ]
    private var cornerRadius: CGFloat

    init(
        isActive: Bool,
        speed: CGFloat,
        colors: [Color],
        cornerRadius: CGFloat
    ) {
        self.isActive = isActive
        self.speed = speed
        self.cornerRadius = cornerRadius
        if !colors.isEmpty {
            self.colors = colors
        }
    }

    func body(content: Content) -> some View {
        if isActive {
            content
                .overlay {
                    ShimmerEffectBox(
                        speed: speed,
                        colors: colors
                    ).cornerRadius(cornerRadius)
                }
        }
    }
}
