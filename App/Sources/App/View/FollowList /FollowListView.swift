import ComposableArchitecture
import SwiftUI

struct FollowListView: View {
    @Bindable var store: StoreOf<FollowListReducer>

    var body: some View {
        ContentView(store: store)
            .onAppear {
                store.send(.initialize)
            }
            .modifier(NavigationModifier(store: store))
            .modifier(HUDModifier(isPresented: $store.isPresentedHUD.sending(\.isPresentedHUD)))
            .modifier(AlertModifier(entity: store.alert, onTap: {
                store.send(.isPresentedAlert(false))
            }, isPresented: $store.isPresentedAlert.sending(\.isPresentedAlert)))
            .navigationBarBackButtonHidden(true)
            .navigationBarItems(leading: Group {
                Button(action: {
                    store.send(.dismiss)
                }) {
                    Image(systemName: "chevron.backward")
                        .foregroundColor(Color(UIColor.label))
                }
            })
    }
}

extension FollowListView {
    struct ContentView: View {
        @Bindable var store: StoreOf<FollowListReducer>

        var body: some View {
            SlideTabView(contents: [
                SlideTabContent(id: 0, title: "\(store.user?.followeeCount ?? 0)フォロー中", inner: AnyView(
                    FolloweeListView(store: store)
                )),
                SlideTabContent(id: 1, title: "\(store.user?.followerCount ?? 0)フォロワー", inner: AnyView(
                    FollowerListView(store: store)
                )),
            ], selection: $store.tabSelection.sending(\.setTabSelection))
                .navigationTitle(store.user?.username ?? "")
                .toolbarRole(.editor)
        }
    }
}

extension FollowListView {
    struct FolloweeListView: View {
        @Bindable var store: StoreOf<FollowListReducer>

        var body: some View {
            PagingListView<UserOverview>(
                listRowSeparator: .hidden,
                itemView: { user in
                    let isFollowing = store.followingMap[user.id] ?? false
                    return AnyView(UserItemView(
                        user: user,
                        isFollowing: isFollowing,
                        followAction: {
                            store.send(.toggleFollow(user))
                        },
                        unBlockAction: {}
                    ))
                },
                onTap: { user in
                    store.send(.presentUserDetailView(user))
                },
                onNext: {
                    store.send(.fetchFollowees(false))
                },
                onRefresh: {
                    store.send(.fetchFollowees(true))
                },
                data: store.followees,
                isLoading: $store.isPresentedNextLoading.sending(\.isPresentedNextLoading),
                isRefreshing: $store.isPresentedPullToRefresh.sending(\.isPresentedPullToRefresh)
            )
            .listStyle(PlainListStyle())
            .listRowSpacing(12)
            .padding(.top, 20)
            .padding(.horizontal, 16)
        }
    }
}

extension FollowListView {
    struct FollowerListView: View {
        @Bindable var store: StoreOf<FollowListReducer>

        var body: some View {
            PagingListView<UserOverview>(
                listRowSeparator: .hidden,
                itemView: { user in
                    let isFollowing = store.followingMap[user.id] ?? false
                    return AnyView(UserItemView(
                        user: user,
                        isFollowing: isFollowing,
                        followAction: {
                            store.send(.toggleFollow(user))
                        },
                        unBlockAction: {}
                    ))
                },
                onTap: { user in
                    store.send(.presentUserDetailView(user))
                },
                onNext: {
                    store.send(.fetchFollowers(false))
                },
                onRefresh: {
                    store.send(.fetchFollowers(true))
                },
                data: store.followers,
                isLoading: $store.isPresentedNextLoading.sending(\.isPresentedNextLoading),
                isRefreshing: $store.isPresentedPullToRefresh.sending(\.isPresentedPullToRefresh)
            )
            .listStyle(PlainListStyle())
            .listRowSpacing(12)
            .padding(.top, 20)
            .padding(.horizontal, 16)
        }
    }
}

extension FollowListView {
    struct NavigationModifier: ViewModifier {
        @Bindable var store: StoreOf<FollowListReducer>

        func body(content: Content) -> some View {
            content
                .navigationDestination(
                    item: $store.scope(state: \.destination?.userDetail, action: \.destination.userDetail)
                ) { store in
                    UserDetailView(store: store)
                }
        }
    }
}
