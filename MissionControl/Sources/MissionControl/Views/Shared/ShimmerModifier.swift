import SwiftUI

struct ShimmerModifier: ViewModifier {
    @State private var animating = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geo in
                    if !reduceMotion {
                        LinearGradient(
                            gradient: Gradient(colors: [
                                .clear,
                                (colorScheme == .dark ? Color.white : Color(white: 0.6)).opacity(0.28),
                                .clear
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: geo.size.width * 0.55)
                        .offset(x: animating
                                ? geo.size.width + geo.size.width * 0.55
                                : -geo.size.width * 0.55)
                    }
                }
                .clipped()
            )
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(.linear(duration: 1.4).repeatForever(autoreverses: false)) {
                    animating = true
                }
            }
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}
