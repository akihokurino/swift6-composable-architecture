import SwiftUI

struct PagingGridView<T: Identifiable & Sendable>: View {
    let space = "PagingGridView"
    let columns: Int
    let gap: CGFloat
    let itemView: (T) -> AnyView
    var emptyView: (() -> AnyView)? = nil
    let onTap: (T) -> Void
    let onNext: () -> Void
    let onRefresh: () async -> Void
    var headerView: (() -> AnyView)? = nil
    var data: WithCursor<T>?
    @Binding var isLoading: Bool
    @Binding var isRefreshing: Bool
    @State private var scrollOffset: CGFloat = .zero

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                if let headerView = headerView {
                    headerView()
                }

                if let data = data {
                    ZStack {
                        LazyVGrid(columns: Array(repeating: .init(.flexible(), spacing: gap), count: columns) as [GridItem], spacing: gap) {
                            ForEach(data.items, id: \.id) { item in
                                itemView(item)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        onTap(item)
                                    }
                            }
                        }

                        GeometryReader { geometry in
                            Color.clear.preference(key: PagingGridViewOffsetKey.self, value: geometry.frame(in: .named(space)).maxY)
                        }
                    }

                    if isLoading && data.hasNext {
                        indicator
                    }

                    if data.items.isEmpty && emptyView != nil {
                        emptyView!()
                    }
                }
            }
        }
        .coordinateSpace(name: space)
        .onPreferenceChange(PagingGridViewOffsetKey.self) { offset in
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
    }
}

struct PagingGridViewOffsetKey: PreferenceKey {
    typealias Value = CGFloat
    static let defaultValue: CGFloat = .zero
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
