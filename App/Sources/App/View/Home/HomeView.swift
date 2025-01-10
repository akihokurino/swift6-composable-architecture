import ComposableArchitecture
import SwiftUI

struct HomeView: View {
    @Bindable var store: StoreOf<HomeReducer>

    var body: some View {
        ContentView(store: store)
            .onAppear {
                store.send(.initialize)
            }
            .navigationBarTitleDisplayMode(.inline)
            .modifier(HUDModifier(isPresented: $store.isPresentedHUD.sending(\.isPresentedHUD)))
            .modifier(AlertModifier(entity: store.alert, onTap: {
                store.send(.isPresentedAlert(false))
            }, isPresented: $store.isPresentedAlert.sending(\.isPresentedAlert)))
            .modifier(NavigationModifier(store: store))
    }
}

extension HomeView {
    struct ContentView: View {
        @Bindable var store: StoreOf<HomeReducer>

        var body: some View {
            SlideTabView(contents: [
                SlideTabContent(id: 0, title: "おすすめ", inner: AnyView(RecommendListView(store: store))),
                SlideTabContent(id: 1, title: "新着", inner: AnyView(LatestListView(store: store))),
                SlideTabContent(id: 2, title: "フォロー", inner: AnyView(FollowingListView(store: store))),
            ], selection: $store.tabSelection.sending(\.setTabSelection))
        }
    }
}

extension HomeView {
    struct RecommendListView: View {
        @Bindable var store: StoreOf<HomeReducer>

        var body: some View {
            if store.recomendedPologs == nil {
                ShimmerView()
                    .onAppear {
                        store.send(.fetchRecommendedPologs(true))
                    }
            } else {
                PagingGridView<PologOverview>(
                    columns: 1,
                    gap: 14,
                    itemView: { polog in
                        AnyView(
                            PologItemView(
                                menu: AnyView(
                                    Menu {
                                        Button {} label: {
                                            HStack {
                                                Text("シェア")
                                                Spacer()
                                                Image(systemName: "square.and.arrow.up")
                                            }
                                        }
                                    } label: {
                                        Image(systemName: "ellipsis").foregroundColor(Color(.secondaryLabel)).padding()
                                    }
                                ),
                                polog: polog,
                                onTapHeart: {},
                                onTapClip: {}
                            )
                        )
                    },
                    onTap: { polog in
                        store.send(.presentPologDetailView(polog))
                    },
                    onNext: {
                        store.send(.fetchRecommendedPologs(false))
                    },
                    onRefresh: {
                        store.send(.fetchRecommendedPologs(true))
                    },
                    data: store.recomendedPologs,
                    isLoading: $store.isPresentedNextLoading.sending(\.isPresentedNextLoading),
                    isRefreshing: $store.isPresentedPullToRefresh.sending(\.isPresentedPullToRefresh)
                )
                .listStyle(PlainListStyle())
                .padding(.horizontal, 2)
                .padding(.vertical, 24)
            }
        }
    }
}

extension HomeView {
    struct LatestListView: View {
        @Bindable var store: StoreOf<HomeReducer>

        var body: some View {
            if store.latestPologs == nil {
                ShimmerView()
                    .onAppear {
                        store.send(.fetchLatestPologs(true))
                    }
            } else {
                PagingGridView<PologOverview>(
                    columns: 1,
                    gap: 14,
                    itemView: { polog in
                        AnyView(
                            PologItemView(
                                menu: AnyView(
                                    Menu {
                                        Button {} label: {
                                            HStack {
                                                Text("シェア")
                                                Spacer()
                                                Image(systemName: "square.and.arrow.up")
                                            }
                                        }
                                    } label: {
                                        Image(systemName: "ellipsis").foregroundColor(Color(.secondaryLabel)).padding()
                                    }
                                ),
                                polog: polog,
                                onTapHeart: {},
                                onTapClip: {}
                            )
                        )
                    },
                    onTap: { polog in
                        store.send(.presentPologDetailView(polog))
                    },
                    onNext: {
                        store.send(.fetchLatestPologs(false))
                    },
                    onRefresh: {
                        store.send(.fetchLatestPologs(true))
                    },
                    data: store.latestPologs,
                    isLoading: $store.isPresentedNextLoading.sending(\.isPresentedNextLoading),
                    isRefreshing: $store.isPresentedPullToRefresh.sending(\.isPresentedPullToRefresh)
                )
                .listStyle(PlainListStyle())
                .padding(.horizontal, 2)
                .padding(.vertical, 24)
            }
        }
    }
}

extension HomeView {
    struct FollowingListView: View {
        @Bindable var store: StoreOf<HomeReducer>

        var body: some View {
            if store.followingPologs == nil {
                ShimmerView()
                    .onAppear {
                        store.send(.fetchFollowingPologs(true))
                    }
            } else {
                PagingGridView<PologOverview>(
                    columns: 1,
                    gap: 14,
                    itemView: { polog in
                        AnyView(
                            PologItemView(
                                menu: AnyView(
                                    Menu {
                                        Button {} label: {
                                            HStack {
                                                Text("シェア")
                                                Spacer()
                                                Image(systemName: "square.and.arrow.up")
                                            }
                                        }
                                    } label: {
                                        Image(systemName: "ellipsis").foregroundColor(Color(.secondaryLabel)).padding()
                                    }
                                ),
                                polog: polog,
                                onTapHeart: {},
                                onTapClip: {}
                            )
                        )
                    },
                    onTap: { polog in
                        store.send(.presentPologDetailView(polog))
                    },
                    onNext: {
                        store.send(.fetchFollowingPologs(false))
                    },
                    onRefresh: {
                        store.send(.fetchFollowingPologs(true))
                    },
                    data: store.followingPologs,
                    isLoading: $store.isPresentedNextLoading.sending(\.isPresentedNextLoading),
                    isRefreshing: $store.isPresentedPullToRefresh.sending(\.isPresentedPullToRefresh)
                )
                .listStyle(PlainListStyle())
                .padding(.horizontal, 2)
                .padding(.vertical, 24)
            }
        }
    }
}

extension HomeView {
    struct ShimmerView: View {
        var body: some View {
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(0 ..< 5, id: \.self) { _ in
                        DummyPologItemView()
                    }
                }
            }
            .disabled(true)
            .padding(.horizontal, 2)
            .padding(.top, 24)
        }
    }
}

extension HomeView {
    struct NavigationModifier: ViewModifier {
        @Bindable var store: StoreOf<HomeReducer>

        func body(content: Content) -> some View {
            content
                .fullScreenCover(
                    item: $store.scope(state: \.destination?.pologDetail, action: \.destination.pologDetail)
                ) { store in
                    NavigationStack {
                        PologDetailView(store: store)
                    }
                }
        }
    }
}
