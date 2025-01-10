import SwiftUI

struct FlowLayoutView<T: Identifiable & Sendable>: View {
    let items: [T]
    let spacing: CGFloat
    let itemView: (T) -> AnyView

    @State private var totalHeight: CGFloat = 0

    var body: some View {
        GeometryReader { geometry in
            generateContent(in: geometry)
                .background(GeometryReader {
                    Color.clear.preference(key: ViewHeightKey.self, value: $0.frame(in: .local).size.height)
                })
        }
        .onPreferenceChange(ViewHeightKey.self) { totalHeight in
            self.totalHeight = totalHeight
        }
        .frame(height: totalHeight)
    }

    private func generateContent(in geo: GeometryProxy) -> some View {
        var width = CGFloat.zero
        var height = CGFloat.zero
        let geoWidth = geo.size.width

        return ZStack(alignment: .topLeading) {
            ForEach(items, id: \.id) { data in
                itemView(data)
                    .padding(.all, spacing)
                    .alignmentGuide(.leading) { dimension in
                        let dimensionWidth = dimension.width
                        let dimensionHeight = dimension.height
                        return MainActor.assumeIsolated {
                            if abs(width - dimensionWidth) > geoWidth {
                                width = 0
                                height -= dimensionHeight
                            }
                            let result = width
                            if data.id == items.last?.id {
                                width = 0
                            } else {
                                width -= dimensionWidth
                            }
                            return result
                        }
                    }
                    .alignmentGuide(.top) { _ in
                        MainActor.assumeIsolated {
                            let result = height
                            if data.id == items.last?.id {
                                height = 0
                            }
                            return result
                        }
                    }
            }
        }
    }
}

struct ViewHeightKey: PreferenceKey {
    typealias Value = CGFloat
    static let defaultValue = CGFloat(0)

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}
