import ComposableArchitecture
import SwiftUI

struct UserEditView: View {
    @Bindable var store: StoreOf<UserEditReducer>
        
    var body: some View {
        NavigationStack {
            ContentView(store: store)
                .onAppear {
                    store.send(.initialize)
                }
                .navigationBarTitle("プロフィール", displayMode: .inline)
                .navigationBarItems(leading: Button(action: {
                    store.send(.dismiss)
                }) {
                    Text("キャンセル")
                })
                .navigationBarItems(trailing: Button(action: {
                    store.send(.update)
                }) {
                    Text("保存")
                })
                .navigationBarBackButtonHidden(true)
                .modifier(NavigationModifier(store: store))
                .modifier(HUDModifier(isPresented: $store.isPresentedHUD.sending(\.isPresentedHUD)))
                .modifier(AlertModifier(entity: store.alert, onTap: {
                    store.send(.isPresentedAlert(false))
                }, isPresented: $store.isPresentedAlert.sending(\.isPresentedAlert)))
                .background(Color(.systemBackground))
        }
    }
}

extension UserEditView {
    struct ContentView: View {
        @Bindable var store: StoreOf<UserEditReducer>
        
        var body: some View {
            let thumbnailSize = CGSize(width: 120, height: 120)
            
            Form {
                Section {
                    HStack(spacing: 0) {
                        ZStack {
                            if let icon = store.icon {
                                switch icon {
                                case .localAsset(let asset):
                                    LocalImageView(asset: asset, size: thumbnailSize, isCircle: true)
                                case .remoteAsset(let asset):
                                    RemoteImageView(url: asset.thumbnailUrl, size: thumbnailSize, isCircle: true)
                                }
                            } else {
                                RemoteImageView(
                                    url: store.loginUser?.me.user.iconSignedUrl.url,
                                    size: thumbnailSize,
                                    isCircle: true
                                )
                            }
                        }
                        .padding(.trailing, 12)
                                            
                        Button("写真の変更") {
                            store.send(.presentAssetSelectView)
                        }
                        .foregroundColor(Color.primary)
                        .padding(.horizontal, 12.5)
                        .padding(.vertical, 7)
                        .background(Color(.tertiarySystemFill))
                        .cornerRadius(.infinity)
                                            
                        Spacer()
                    }
                }
                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                .listRowBackground(Color.clear)
                                    
                Section(header: Text("表示名").font(.footnote).fontWeight(.semibold)) {
                    TextField("表示名を入力", text: $store.fullName.sending(\.setFullName))
                }
                .listRowBackground(Color(.quaternarySystemFill))
                                    
                Section(header: Text("自己紹介").font(.footnote).fontWeight(.semibold)) {
                    MultilineTextFieldView(text: $store.profile.sending(\.setProfile))
                }
                .listRowBackground(Color(.quaternarySystemFill))
            }
            .scrollDismissesKeyboard(.immediately)
            .scrollContentBackground(.hidden)
            .applyContents {
                if #available(iOS 17.0, *) {
                    $0.contentMargins(.vertical, 20)
                        .listSectionSpacing(.compact)
                }
            }
        }
    }
}

extension UserEditView {
    struct NavigationModifier: ViewModifier {
        @Bindable var store: StoreOf<UserEditReducer>

        func body(content: Content) -> some View {
            WithViewStore(store, observe: { $0 }) { _ in
                content
                    .sheet(
                        item: $store.scope(state: \.destination?.assetSelect, action: \.destination.assetSelect)
                    ) { store in
                        NavigationStack {
                            AssetSelectView(store: store)
                        }
                    }
            }
        }
    }
}
