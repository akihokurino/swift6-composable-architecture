
import ComposableArchitecture
import SwiftUI

extension SearchView {
    struct ResultView: View {
        @Bindable var store: StoreOf<SearchReducer>

        var body: some View {
            SlideTabView(contents: [
                SlideTabContent(id: 0, title: "ユーザー", inner: AnyView(UserListView(store: store))),
                SlideTabContent(id: 1, title: "旅行記", inner: AnyView(PologListView(store: store))),
            ], selection: $store.tabSelection.sending(\.setTabSelection))
        }
    }
}

extension SearchView {
    struct UserListView: View {
        @Bindable var store: StoreOf<SearchReducer>

        var body: some View {
            PagingListView<UserOverview>(
                listRowSeparator: .hidden,
                itemView: { user in
                    let isFollowing = store.followingMap[user.id]
                    let isBlocking = store.blockingMap[user.id]
                    return AnyView(
                        UserItemView(
                            user: user,
                            isFollowing: isFollowing,
                            isBlocking: isBlocking,
                            followAction: {
                                store.send(.toggleFollow(user))
                            },
                            unBlockAction: {}
                        )
                    )
                },
                emptyView: {
                    AnyView(EmptyView(query: store.query))
                },
                onTap: { user in
                    store.send(.presentUserDetailView(user))
                },
                onNext: {
                    store.send(.searchUsers(false))
                },
                onRefresh: {
                    store.send(.searchUsers(true))
                },
                data: store.users,
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

extension SearchView {
    struct PologListView: View {
        @Bindable var store: StoreOf<SearchReducer>

        var body: some View {
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
                emptyView: {
                    AnyView(EmptyView(query: store.query))
                },
                onTap: { polog in
                    store.send(.presentPologDetailView(polog))
                },
                onNext: {
                    store.send(.searchPologs(false))
                },
                onRefresh: {
                    store.send(.searchPologs(true))
                },
                data: store.pologs,
                isLoading: $store.isPresentedNextLoading.sending(\.isPresentedNextLoading),
                isRefreshing: $store.isPresentedPullToRefresh.sending(\.isPresentedPullToRefresh)
            )
            .listStyle(PlainListStyle())
            .padding(.horizontal, 2)
            .padding(.vertical, 24)
        }
    }
}

extension SearchView {
    struct EmptyView: View {
        let query: String

        var body: some View {
            VStack {
                Spacer()
                Text("「\(query)」に該当する結果がありませんでした")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(Color(UIColor.label))
                    .multilineTextAlignment(.center)
                Spacer16()
                Text("キーワードを変えて検索してみてください")
                    .font(.subheadline)
                    .foregroundColor(Color(UIColor.secondaryLabel))
                    .multilineTextAlignment(.center)
                Spacer()
            }
            .padding(.horizontal, 16)
        }
    }
}
