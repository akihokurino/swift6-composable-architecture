import ActivityIndicatorView
import SwiftUI

struct HUD: View {
    @Binding var isLoading: Bool

    var body: some View {
        ZStack {
            Group {
                if isLoading {
                    ProgressView()
                        .controlSize(.large)
                }
            }
            .frame(width: 80, height: 80, alignment: .center)
            .background(.regularMaterial)
            .cornerRadius(8)
        }
        .frame(minWidth: 0,
               maxWidth: .infinity,
               minHeight: 0,
               maxHeight: .infinity,
               alignment: .center)
        .edgesIgnoringSafeArea(.all)
    }
}

struct HUDModifier: ViewModifier {
    @Binding var isPresented: Bool

    func body(content: Content) -> some View {
        content
            .overlay(
                Group {
                    HUD(isLoading: $isPresented)
                }, alignment: .center
            )
    }
}
