import ComposableArchitecture
import SwiftUI

struct UserDetailView: View {
    @Bindable var store: StoreOf<UserDetailReducer>

    var body: some View {
        ContentView(store: store)
            .onAppear {
                store.send(.initialize)
            }
            .modifier(HUDModifier(isPresented: $store.isPresentedHUD.sending(\.isPresentedHUD)))
            .modifier(AlertModifier(entity: store.alert, onTap: {
                store.send(.isPresentedAlert(false))
            }, isPresented: $store.isPresentedAlert.sending(\.isPresentedAlert)))
            .modifier(NavigationModifier(store: store))
            .navigationBarBackButtonHidden(true)
            .navigationBarItems(leading: Group {
                Button(action: {
                    store.send(.dismiss)
                }) {
                    Image(systemName: "chevron.backward")
                        .foregroundColor(Color(UIColor.label))
                }
            }, trailing: HStack {
                Button(action: {}) { Image("IconPaperAirplane").foregroundColor(Color.primary) }
            })
    }
}

extension UserDetailView {
    struct ContentView: View {
        @Bindable var store: StoreOf<UserDetailReducer>

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
                                    Image(systemName: "ellipsis").foregroundColor(Color(.secondaryLabel))
                                        .padding()
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
                    store.send(.fetchPologs(false))
                },
                onRefresh: {
                    store.send(.fetchPologs(true))
                    store.send(.fetchPologSummary)
                },
                headerView: {
                    AnyView(
                        HeaderView(store: store)
                    )
                },
                data: store.pologs,
                isLoading: $store.isPresentedNextLoading.sending(\.isPresentedNextLoading),
                isRefreshing: $store.isPresentedPullToRefresh.sending(\.isPresentedPullToRefresh)
            )
            .listStyle(PlainListStyle())
        }
    }
}

extension UserDetailView {
    struct NavigationModifier: ViewModifier {
        @Bindable var store: StoreOf<UserDetailReducer>

        func body(content: Content) -> some View {
            content
                .navigationDestination(
                    item: $store.scope(state: \.destination?.followList, action: \.destination.followList)
                ) { store in
                    FollowListView(store: store)
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
