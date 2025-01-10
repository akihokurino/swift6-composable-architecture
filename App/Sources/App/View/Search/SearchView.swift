import ComposableArchitecture
import SwiftUI

struct SearchView: View {
    @Bindable var store: StoreOf<SearchReducer>

    var body: some View {
        ContentView(store: store)
            .onAppear {
                store.send(.initialize)
            }
            .navigationTitle("検索")
            .navigationBarTitleDisplayMode(.inline)
            .modifier(HUDModifier(isPresented: $store.isPresentedHUD.sending(\.isPresentedHUD)))
            .modifier(AlertModifier(entity: store.alert, onTap: {
                store.send(.isPresentedAlert(false))
            }, isPresented: $store.isPresentedAlert.sending(\.isPresentedAlert)))
            .modifier(NavigationModifier(store: store))
    }
}

extension SearchView {
    struct ContentView: View {
        @Bindable var store: StoreOf<SearchReducer>

        var body: some View {
            VStack(spacing: 0) {
                SearchBarView(store: store)
                    .padding(.horizontal, 16)

                if store.isEditingSearchBar {
                    VStack {
                        Spacer20()
                        HStack {
                            Text("検索履歴")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(Color(.secondaryLabel))
                            Spacer()
                        }
                        Spacer16()
                    }
                    .padding(.horizontal, 16)
                    SearchHistoryListView(store: store)
                } else if !store.isSearching {
                    VStack {
                        Spacer20()
                        HStack {
                            Text("おすすめユーザー")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(Color(.secondaryLabel))
                            Spacer()
                        }
                        Spacer16()
                    }
                    .padding(.horizontal, 16)
                    RecommendedUserListView(store: store)
                } else {
                    ResultView(store: store)
                }

                Spacer()
            }
            .onChange(of: store.isEditingSearchBar) { newValue in
                if newValue {}
            }
        }
    }
}

extension SearchView {
    struct SearchHistoryListView: View {
        @Bindable var store: StoreOf<SearchReducer>

        var body: some View {
            List {
                ForEach(store.searchHistory?.values ?? [], id: \.self) { query in
                    Button {
                        hideKeyboard()
                        store.send(.selectSearchHistory(query))
                    } label: {
                        HStack {
                            Image(systemName: "clock.arrow.circlepath")
                                .frame(width: 24, height: 24)
                                .padding(8)
                                .foregroundStyle(Color.black)
                                .background(Color(.tertiarySystemFill))
                                .cornerRadius(.infinity)
                            Spacer12()
                            Text(query)
                                .lineLimit(1)
                                .font(.subheadline)
                                .foregroundColor(.primary)
                        }
                    }
                    .swipeActions(edge: .trailing) {
                        Button {
                            store.send(.deleteSearchHistory(query))
                        } label: {
                            Text("削除")
                        }
                        .tint(.red)
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
                }
            }
            .padding(.horizontal, 16)
            .scrollDismissesKeyboard(.immediately)
            .listStyle(PlainListStyle())
            .listRowSpacing(12)
            .scrollContentBackground(.hidden)
            .background(Color(.systemBackground))
            .environment(\.defaultMinListRowHeight, 0)
        }
    }
}

extension SearchView {
    struct RecommendedUserListView: View {
        @Bindable var store: StoreOf<SearchReducer>

        var body: some View {
            List {
                ForEach(store.recommendedUsers?.items ?? [], id: \.self) { user in
                    let isFollowing = store.followingMap[user.id]
                    let isBlocking = store.blockingMap[user.id]
                    UserItemView(
                        user: user,
                        isFollowing: isFollowing,
                        isBlocking: isBlocking,
                        followAction: {},
                        unBlockAction: {}
                    )
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets())
                    .onTapGesture {}
                }
            }
            .padding(.horizontal, 16)
            .scrollDismissesKeyboard(.immediately)
            .listStyle(PlainListStyle())
            .listRowSpacing(12)
            .scrollContentBackground(.hidden)
            .background(Color(.systemBackground))
            .environment(\.defaultMinListRowHeight, 0)
        }
    }
}

extension SearchView {
    struct NavigationModifier: ViewModifier {
        @Bindable var store: StoreOf<SearchReducer>

        func body(content: Content) -> some View {
            content
                .navigationDestination(
                    item: $store.scope(state: \.destination?.userDetail, action: \.destination.userDetail)
                ) { store in
                    UserDetailView(store: store)
                }
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
