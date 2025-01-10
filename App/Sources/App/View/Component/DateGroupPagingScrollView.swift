import SwiftUI

struct DateGroupPagingScrollView<T: Identifiable & HasDate & Hashable & Sendable>: View {
    let space = "DateGroupPagingScrollView"
    let itemView: (DateGroup<T>) -> AnyView
    let onNext: () -> Void
    let onRefresh: () async -> Void
    var headerView: (() -> AnyView)? = nil
    var data: WithCursor<T>?
    @Binding var isLoading: Bool
    @Binding var isRefreshing: Bool

    var body: some View {
        ScrollView {
            VStack {
                if let headerView = headerView {
                    headerView()
                }

                if let data = data {
                    ForEach(DateGroup<T>.from(assets: data.items), id: \.id) { group in
                        itemView(group)
                    }

                    GeometryReader { geometry in
                        Color.clear.preference(key: DateGroupPagingScrollViewOffsetKey.self, value: geometry.frame(in: .named(space)).maxY)
                    }

                    if isLoading && data.hasNext {
                        indicator
                    }
                }
            }
            .frame(maxHeight: .infinity)
        }
        .coordinateSpace(name: space)
        .onPreferenceChange(DateGroupPagingScrollViewOffsetKey.self) { offset in
            guard let data = data else {
                return
            }
            if !isLoading && !isRefreshing && offset < windowHeight() + 1 && data.items.count > 0 && data.hasNext {
                onNext()
            }
        }
        .refreshable {
            guard !isLoading && !isRefreshing else {
                return
            }
            await onRefresh()
        }
    }

    var indicator: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                ProgressView()
                Spacer()
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .frame(height: 60)
        .listRowSeparator(.hidden)
        .listRowInsets(EdgeInsets())
    }
}

struct DateGroupPagingScrollViewOffsetKey: PreferenceKey {
    typealias Value = CGFloat
    static let defaultValue: CGFloat = .zero
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
