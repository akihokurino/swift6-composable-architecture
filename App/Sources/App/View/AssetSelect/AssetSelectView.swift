import ComposableArchitecture
import SwiftUI

struct AssetSelectView: View {
    @Bindable var store: StoreOf<AssetSelectReducer>

    var body: some View {
        ContentView(store: store)
            .onAppear {
                store.send(.initialize)
            }
            .navigationTitle("画像を選択")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(leading: Button(action: {
                store.send(.dismiss)
            }) {
                Text("キャンセル")
                    .foregroundColor(Color(UIColor.label))
            }, trailing: Button(action: {
                store.send(.confirm)
            }) {
                if store.selectedAssetCount == 0 {
                    Text("追加")
                        .foregroundColor(Color(UIColor.label))
                } else {
                    Text("追加（\(store.selectedAssetCount)）")
                        .foregroundColor(Color(UIColor.label))
                }
            })
            .modifier(HUDModifier(isPresented: $store.isPresentedHUD.sending(\.isPresentedHUD)))
            .modifier(AlertModifier(entity: store.alert, onTap: {
                store.send(.isPresentedAlert(false))
            }, isPresented: $store.isPresentedAlert.sending(\.isPresentedAlert)))
    }
}

extension AssetSelectView {
    struct ContentView: View {
        @Bindable var store: StoreOf<AssetSelectReducer>

        var body: some View {
            if store.onlyLocalAsset {
                LocalAssetSelectView(store: store)
            } else {
                SlideTabView(contents: [
                    SlideTabContent(id: 0, title: "写真", inner: AnyView(LocalAssetSelectView(store: store))),
                    SlideTabContent(id: 1, title: "グループ共有画像", inner: AnyView(GroupAssetSelectView(store: store))),
                ], selection: $store.tabSelection.sending(\.setTabSelection))
            }
        }
    }
}
