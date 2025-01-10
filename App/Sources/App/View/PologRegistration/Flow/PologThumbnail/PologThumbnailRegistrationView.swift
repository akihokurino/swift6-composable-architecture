import ComposableArchitecture
import SwiftUI

struct PologThumbnailRegistrationView: View {
    @Bindable var store: StoreOf<PologThumbnailRegistrationReducer>

    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            ContentView(store: store)
                .onAppear {
                    viewStore.send(.initialize)
                }
                .background(Color(.systemBackground))
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        Text("表紙を編集")
                            .fontWeight(.semibold)
                            .foregroundColor(Color(.label))
                    }
                }
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarBackButtonHidden(true)
                .navigationBarItems(leading: Group {
                    Button(action: {
                        viewStore.send(.dismiss)
                    }) {
                        Image(systemName: "chevron.backward")
                            .foregroundColor(Color(UIColor.label))
                    }
                }, trailing: HStack {
                    Button(action: {
                        viewStore.send(.confirm)
                    }) {
                        Text("確定")
                            .foregroundColor(Color(UIColor.label))
                    }
                })
                .modifier(NavigationModifier(store: store))
                .colorScheme(.light)
                .toolbarColorScheme(.light, for: .automatic)
        }
    }
}

extension PologThumbnailRegistrationView {
    struct ContentView: View {
        @Bindable var store: StoreOf<PologThumbnailRegistrationReducer>

        var body: some View {
            GeometryReader { geometry in
                let thumbnailWidth = abs(geometry.size.width - 150)
                let thumbnailSize = CGSize(width: thumbnailWidth, height: thumbnailWidth)
                    
                ScrollView {
                    VStack(spacing: 0) {
                        Spacer20()
                            
                        ZStack {
                            if let thumbnail = store.thumbnail {
                                switch thumbnail {
                                case .localAsset(let asset):
                                    LocalImageView(asset: asset, size: thumbnailSize, radius: 8)
                                case .remoteAsset(let asset):
                                    RemoteImageView(url: asset.thumbnailUrl, size: thumbnailSize, radius: 8)
                                }
                            } else {
                                Button(action: {
                                    store.send(.presentAssetSelectView)
                                }) {
                                    VStack {
                                        Spacer()
                                        HStack {
                                            Spacer()
                                            Text("表紙写真が選択されていません")
                                                .font(.footnote)
                                                .foregroundColor(Color(UIColor.tertiaryLabel))
                                                .multilineTextAlignment(.center)
                                                
                                            Spacer()
                                        }
                                        Spacer()
                                    }
                                    .frame(width: thumbnailWidth, height: thumbnailWidth)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10).stroke(Color.gray, lineWidth: 1)
                                    )
                                }
                            }
                                
                            VStack {
                                Spacer16()
                                HStack {
                                    Spacer16()
                                    Text(store.topLabel.prefix(8))
                                        .foregroundColor(.white)
                                    Spacer()
                                }
                                Spacer()
                                HStack {
                                    Spacer()
                                    Text(store.middleLabel.prefix(16))
                                        .foregroundColor(.white)
                                    Spacer()
                                }
                                Spacer()
                                HStack {
                                    Spacer()
                                    Text(store.bottomLabel.prefix(8))
                                        .foregroundColor(.white)
                                    Spacer16()
                                }
                                Spacer16()
                            }
                        }
                        .frame(width: thumbnailSize.width, height: thumbnailSize.height)
                            
                        Spacer16()
                            
                        Button(action: {
                            store.send(.presentAssetSelectView)
                        }) {
                            Text("写真を変更")
                                .font(.subheadline)
                                .foregroundColor(Color(UIColor.label))
                                .padding(.vertical, 4)
                                .padding(.horizontal, 10)
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule().fill(Color(UIColor.tertiarySystemFill))
                                )
                        }
                            
                        Spacer24()
                            
                        HStack {
                            Text("表紙に表示する文字")
                                .font(.body)
                                .foregroundColor(Color(UIColor.label))
                                .bold()
                            Spacer()
                            Text("任意")
                                .font(.caption)
                                .bold()
                                .foregroundColor(.white)
                                .padding(.vertical, 2)
                                .padding(.horizontal, 8)
                                .background(RoundedRectangle(cornerRadius: 4).foregroundColor(.gray))
                        }
                        .frame(maxWidth: .infinity)
                        Spacer20()
                            
                        HStack {
                            Text("誰と")
                                .font(.footnote)
                                .foregroundColor(Color(UIColor.secondaryLabel))
                                .padding(.horizontal, 16)
                                .bold()
                            Spacer()
                            Text("\(store.topLabel.count)/8")
                                .font(.footnote)
                                .foregroundColor(Color(UIColor.secondaryLabel))
                                .padding(.horizontal, 16)
                        }
                        .frame(maxWidth: .infinity)
                            
                        Spacer8()
                            
                        TextFieldView(value: $store.topLabel.sending(\.setTopLabel), placeholder: "例)一人旅、友人と", keyboardType: .default, height: 60) { value in
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                store.send(.setTopLabel(String(value.prefix(8))))
                            }
                        }
                            
                        Spacer16()
                            
                        HStack {
                            Text("どこで")
                                .font(.footnote)
                                .foregroundColor(Color(UIColor.secondaryLabel))
                                .padding(.horizontal, 16)
                                .bold()
                            Spacer()
                            Text("\(store.middleLabel.count)/16")
                                .font(.footnote)
                                .foregroundColor(Color(UIColor.secondaryLabel))
                                .padding(.horizontal, 16)
                        }
                        .frame(maxWidth: .infinity)
                            
                        Spacer8()
                            
                        TextFieldView(value: $store.middleLabel.sending(\.setMiddleLabel), placeholder: "例)浅草、京都、◯◯遊園地", keyboardType: .default, height: 60) { value in
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                store.send(.setMiddleLabel(String(value.prefix(16))))
                            }
                        }
                            
                        Spacer16()
                            
                        HStack {
                            Text("何をしたか")
                                .font(.footnote)
                                .foregroundColor(Color(UIColor.secondaryLabel))
                                .padding(.horizontal, 16)
                                .bold()
                            Spacer()
                            Text("\(store.bottomLabel.count)/8")
                                .font(.footnote)
                                .foregroundColor(Color(UIColor.secondaryLabel))
                                .padding(.horizontal, 16)
                        }
                        .frame(maxWidth: .infinity)
                            
                        Spacer8()
                            
                        TextFieldView(value: $store.bottomLabel.sending(\.setBottomLabel), placeholder: "例)◯◯旅行", keyboardType: .default, height: 60) { value in
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                store.send(.setBottomLabel(String(value.prefix(8))))
                            }
                        }
                            
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                }
                .scrollDismissesKeyboard(.immediately)
            }
        }
    }
}

extension PologThumbnailRegistrationView {
    struct NavigationModifier: ViewModifier {
        @Bindable var store: StoreOf<PologThumbnailRegistrationReducer>

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
