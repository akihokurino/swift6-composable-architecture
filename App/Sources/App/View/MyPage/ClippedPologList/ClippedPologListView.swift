import ComposableArchitecture
import SwiftUI

struct ClippedPologListView: View {
    @Bindable var store: StoreOf<ClippedPologListReducer>

    var body: some View {
        ContentView(store: store)
            .onAppear {
                store.send(.initialize)
            }
            .toolbarRole(.editor)
            .navigationTitle("クリップ")
            .modifier(HUDModifier(isPresented: $store.isPresentedHUD.sending(\.isPresentedHUD)))
            .modifier(AlertModifier(entity: store.alert, onTap: {
                store.send(.isPresentedAlert(false))
            }, isPresented: $store.isPresentedAlert.sending(\.isPresentedAlert)))
    }
}

extension ClippedPologListView {
    struct ContentView: View {
        @Bindable var store: StoreOf<ClippedPologListReducer>

        var body: some View {
            NavigationStack {
                PagingGridView<PologOverview>(
                    columns: 1,
                    gap: 1,
                    itemView: { polog in
                        AnyView(
                            Button(action: {}) {
                                PologItemView(
                                    menu: AnyView(
                                        Menu {
                                            Button {} label: {
                                                HStack {
                                                    Text("シェア")
                                                    Spacer()
                                                    Image("IconEdit")
                                                }
                                            }
                                        } label: {
                                            Image(systemName: "ellipsis").foregroundColor(Color(.secondaryLabel)).padding()
                                        }
                                        .onTapGesture {}
                                    ),
                                    polog: polog,
                                    onTapHeart: {},
                                    onTapClip: {}
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        )
                    },
                    onTap: { _ in

                    },
                    onNext: {
                        store.send(.fetchPologs(false))
                    },
                    onRefresh: {
                        store.send(.fetchPologs(true))
                    },
                    data: store.pologs,
                    isLoading: $store.isPresentedNextLoading.sending(\.isPresentedNextLoading),
                    isRefreshing: $store.isPresentedPullToRefresh.sending(\.isPresentedPullToRefresh)
                )
                .listStyle(PlainListStyle())
                .padding(.horizontal, 2)
                .padding(.vertical, 16)
            }
        }
    }
}
