import ComposableArchitecture
import SwiftUI

struct PologRegistrationPrepareView: View {
    @Bindable var store: StoreOf<PologRegistrationPrepareReducer>

    var body: some View {
        ContentView(store: store)
            .onAppear {
                store.send(.initialize)
            }
            .modifier(HUDModifier(isPresented: $store.isPresentedHUD.sending(\.isPresentedHUD)))
            .modifier(AlertModifier(entity: store.alert, onTap: {
                store.send(.isPresentedAlert(false))
            }, isPresented: $store.isPresentedAlert.sending(\.isPresentedAlert)))
            .modifier(CustomAlertModifier(store: store))
            .modifier(NavigationModifier(store: store))
    }
}

extension PologRegistrationPrepareView {
    struct ContentView: View {
        @Bindable var store: StoreOf<PologRegistrationPrepareReducer>

        var body: some View {
            VStack {
                Spacer16()
                HStack {
                    Text("旅行記の投稿")
                        .bold()
                        .font(.title3)
                        .foregroundColor(Color(UIColor.label))
                    Spacer()
                    Button(action: {
                        store.send(.dismiss)
                    }) {
                        Image(systemName: "xmark")
                            .foregroundColor(Color(UIColor.secondaryLabel))
                            .background(Circle().fill(Color(UIColor.tertiarySystemFill)).frame(width: 30, height: 30))
                    }
                }
                .padding(.horizontal, 16)

                Spacer12()
                ActionButtonView(text: "新規投稿", buttonType: .primary) {
                    store.send(.presentAssetSelectView)
                }
                .padding(.horizontal, 16)

                Spacer12()
                ActionButtonView(text: "旅行記の書き方", buttonType: .normal, icon: Image(systemName: "questionmark.circle")) {}.padding(.horizontal, 16)

                Spacer20()
                List {
                    Section(
                        header: Text("下書き")
                            .font(.subheadline)
                            .foregroundColor(Color(UIColor.secondaryLabel))
                    ) {
                        ForEach(store.drafts, id: \.id) { item in
                            DraftView(inputPolog: item)
                                .onTapGesture {
                                    store.send(.startRegistration(item))
                                }
                                .swipeActions(edge: .trailing) {
                                    Button {
                                        store.send(.presentDeleteDraftAlert(item))
                                    } label: {
                                        Text("削除")
                                    }
                                    .tint(.red)
                                }
                        }
                    }
                }
                .scrollContentBackground(.hidden)
                .background(Color(.systemBackground))

                Spacer()
            }
        }
    }
}

extension PologRegistrationPrepareView {
    struct DraftView: View {
        let inputPolog: InputPolog

        var body: some View {
            HStack {
                VStack(alignment: .leading) {
                    Text(inputPolog.title.isNotEmpty ? inputPolog.title : "タイトル未設定")
                        .font(.callout)
                        .foregroundColor(Color(UIColor.label))
                    Spacer4()
                    Text(inputPolog.displayDraftedAtJST)
                        .font(.footnote)
                        .foregroundColor(Color(UIColor.secondaryLabel))
                }
                Spacer()
            }
            .contentShape(Rectangle())
        }
    }
}

extension PologRegistrationPrepareView {
    struct CustomAlertModifier: ViewModifier {
        @Bindable var store: StoreOf<PologRegistrationPrepareReducer>

        func body(content: Content) -> some View {
            WithViewStore(store, observe: { $0 }) { _ in
                content
                    .alert(
                        "下書きを削除しますか",
                        isPresented: $store.isPresentedDeleteDraftAlert.sending(\.isPresentedDeleteDraftAlert)
                    ) {
                        HStack {
                            Button("キャンセル", role: .cancel) {
                                store.send(.isPresentedDeleteDraftAlert(false))
                            }
                            Button("削除する", role: .destructive) {
                                store.send(.deleteDraft)
                            }
                        }
                    } message: {}
            }
        }
    }
}

extension PologRegistrationPrepareView {
    struct NavigationModifier: ViewModifier {
        @Bindable var store: StoreOf<PologRegistrationPrepareReducer>

        func body(content: Content) -> some View {
            content.sheet(
                item: $store.scope(state: \.destination?.assetSelect, action: \.destination.assetSelect)
            ) { store in
                NavigationStack {
                    AssetSelectView(store: store)
                }
            }
        }
    }
}
