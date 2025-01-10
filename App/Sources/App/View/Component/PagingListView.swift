import SwiftUI

struct PagingListView<T: Identifiable & Sendable>: View {
    var listRowSeparator: Visibility = .hidden
    let itemView: (T) -> AnyView
    var emptyView: (() -> AnyView)? = nil
    let onTap: (T) -> Void
    let onNext: () -> Void
    let onRefresh: () async -> Void
    var headerView: (() -> AnyView)? = nil
    var data: WithCursor<T>?
    @Binding var isLoading: Bool
    @Binding var isRefreshing: Bool

    var body: some View {
        List {
            if let headerView = headerView {
                headerView()
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
            }

            if let data = data {
                ForEach(data.items, id: \.id) { item in
                    if item.id == data.items.last?.id {
                        VStack(spacing: 0) {
                            itemView(item)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    onTap(item)
                                }
                                .onAppear {
                                    if data.hasNext && !isLoading && !isRefreshing {
                                        onNext()
                                    }
                                }

                            if isLoading && data.hasNext {
                                indicator
                            }
                        }
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(listRowSeparator)
                    } else {
                        itemView(item)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                onTap(item)
                            }
                            .listRowInsets(EdgeInsets())
                            .listRowSeparator(listRowSeparator)
                    }
                }

                if data.items.isEmpty && emptyView != nil {
                    emptyView!()
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color(.systemBackground))
        .refreshable {
            guard !isLoading && !isRefreshing else {
                return
            }
            await onRefresh()
        }
        .frame(maxWidth: .infinity)
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
