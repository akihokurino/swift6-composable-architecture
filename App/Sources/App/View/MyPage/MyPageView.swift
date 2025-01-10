import ComposableArchitecture
import SwiftUI

struct MyPageView: View {
    @Bindable var store: StoreOf<MyPageReducer>

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
            .navigationBarItems(trailing: HStack {
                Button(action: {}) { Image("IconPaperAirplane").foregroundColor(Color.primary) }
                Button(action: {}) { Image("IconBell").foregroundColor(Color.primary) }
                Button(action: {
                    store.send(.presentSettingView)
                }) { Image("IconSetting").foregroundColor(Color.primary) }
            })
    }
}

extension MyPageView {
    struct ContentView: View {
        @Bindable var store: StoreOf<MyPageReducer>

        var body: some View {
            PagingGridView<PologOverview>(
                columns: 1,
                gap: 14,
                itemView: { polog in
                    AnyView(
                        PologItemView(
                            menu: AnyView(
                                Menu {
                                    Button {
                                        store.send(.editPolog(polog))
                                    } label: {
                                        HStack {
                                            Text("編集")
                                            Spacer()
                                            Image("IconEdit")
                                        }
                                    }
                                    Button {} label: {
                                        HStack {
                                            Text("シェア")
                                            Spacer()
                                            Image(systemName: "square.and.arrow.up")
                                        }
                                    }
                                    if polog.routes.count >= 9 {
                                        Button {} label: {
                                            HStack {
                                                Text("ストーリー画像書き出し")
                                                Spacer()
                                                Image("IconExportImg")
                                            }
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

extension MyPageView {
    struct NavigationModifier: ViewModifier {
        @Bindable var store: StoreOf<MyPageReducer>

        func body(content: Content) -> some View {
            content
                .navigationDestination(
                    item: $store.scope(state: \.destination?.followList, action: \.destination.followList)
                ) { store in
                    FollowListView(store: store)
                }
                .navigationDestination(
                    item: $store.scope(state: \.destination?.userEdit, action: \.destination.userEdit)
                ) { store in
                    UserEditView(store: store)
                }
                .navigationDestination(
                    item: $store.scope(state: \.destination?.setting, action: \.destination.setting)
                ) { store in
                    SettingView(store: store)
                }
                .navigationDestination(
                    item: $store.scope(state: \.destination?.clippedPologList, action: \.destination.clippedPologList)
                ) { store in
                    ClippedPologListView(store: store)
                }
                .fullScreenCover(
                    item: $store.scope(state: \.destination?.pologDetail, action: \.destination.pologDetail)
                ) { store in
                    NavigationStack {
                        PologDetailView(store: store)
                    }
                }
                .fullScreenCover(
                    item: $store.scope(state: \.destination?.pologRegistrationFlow, action: \.destination.pologRegistrationFlow)
                ) { store in
                    NavigationStack {
                        PologRegistrationFlowView(store: store)
                    }
                }
        }
    }
}
