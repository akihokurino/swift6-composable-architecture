import ComposableArchitecture
import SwiftUI

extension AssetSelectView {
    struct LocalAssetSelectView: View {
        @Bindable var store: StoreOf<AssetSelectReducer>
        let space = "LocalAssetSelectView"
        
        var body: some View {
            GeometryReader { geometry in
                ScrollViewReader { reader in
                    VStack {
                        Spacer12()
                                
                        HStack {
                            Menu {
                                Button(action: {
                                    store.send(.selectLocalAlbum(nil))
                                }) {
                                    Text("最近の項目")
                                }
                                ForEach(store.localAlbums, id: \.id) { album in
                                    Button(action: {
                                        store.send(.selectLocalAlbum(album))
                                    }) {
                                        Text(album.title)
                                    }
                                }
                            } label: {
                                HStack {
                                    Image(systemName: "line.3.horizontal.decrease")
                                        .foregroundColor(Color(UIColor.label))
                                            
                                    Spacer4()
                                            
                                    if let album = store.selectedLocalAlbum {
                                        Text(album.title)
                                            .font(.subheadline)
                                            .foregroundColor(Color(UIColor.label))
                                    } else {
                                        Text("最近の項目")
                                            .font(.subheadline)
                                            .foregroundColor(Color(UIColor.label))
                                    }
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Color.clear)
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule().stroke(Color.gray, lineWidth: 1)
                                )
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                                
                        ScrollView {
                            LazyVStack {
                                ForEach(DateGroup<LocalAsset>.from(assets: store.localAssets), id: \.id) { group in
                                    VStack(alignment: .leading) {
                                        Spacer20()
                                                
                                        HStack {
                                            Text(group.date.dateDisplayJST)
                                                .font(.title3)
                                                .foregroundColor(Color(UIColor.secondaryLabel))
                                            Spacer()
                                                    
                                            if store.selectMode == .multiple {
                                                if group.isAllSelected(selected: store.selectedLocalAssets) {
                                                    Button(action: {
                                                        store.send(.unSelectLocalAssets(group.assets))
                                                    }) {
                                                        Image(systemName: "checkmark")
                                                            .foregroundColor(.white)
                                                            .frame(width: 25, height: 25)
                                                            .background(Circle().foregroundColor(Color.black))
                                                    }
                                                } else {
                                                    Button(action: {
                                                        store.send(.selectLocalAssets(group.assets))
                                                    }) {
                                                        Circle()
                                                            .frame(width: 25, height: 25)
                                                            .background(Color.clear)
                                                            .overlay(
                                                                Circle().stroke(Color.gray, lineWidth: 2)
                                                            )
                                                    }
                                                    .foregroundColor(Color.clear)
                                                }
                                            }
                                        }
                                        .padding(.horizontal, 16)
                                        .frame(height: 32)
                                                
                                        Spacer12()
                                                
                                        LazyVGrid(columns: Array(repeating: .init(.flexible(), spacing: 2), count: 3), spacing: 2) {
                                            ForEach(group.assets, id: \.id) { asset in
                                                ZStack {
                                                    Button(action: {
                                                        store.send(.setCurrentLocalAsset(asset))
                                                        store.send(.isPresentedTabViewer(true))
                                                    }) {
                                                        LocalImageView(
                                                            asset: asset,
                                                            size: CGSize(
                                                                width: (geometry.size.width - 4) / 3,
                                                                height: (geometry.size.width - 4) / 3
                                                            ),
                                                            shouldShowVideoDuration: true
                                                        )
                                                    }
                                                            
                                                    VStack {
                                                        Spacer8()
                                                        HStack {
                                                            Spacer()
                                                            if store.selectedLocalAssets.contains(asset) {
                                                                Button(action: {
                                                                    store.send(.unSelectLocalAssets([asset]))
                                                                }) {
                                                                    Image(systemName: "checkmark.circle.fill")
                                                                        .resizable()
                                                                        .frame(width: 25, height: 25)
                                                                        .clipShape(Circle())
                                                                        .foregroundColor(.white)
                                                                }
                                                                .foregroundColor(Color.clear)
                                                            } else {
                                                                Button(action: {
                                                                    store.send(.selectLocalAssets([asset]))
                                                                }) {
                                                                    Circle()
                                                                        .frame(width: 25, height: 25)
                                                                        .background(Color.white.opacity(0.3))
                                                                        .clipShape(Circle())
                                                                        .overlay(
                                                                            Circle().stroke(Color.white, lineWidth: 2)
                                                                        )
                                                                }
                                                                .foregroundColor(Color.clear)
                                                            }
                                                            Spacer8()
                                                        }
                                                        Spacer()
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            .frame(maxHeight: .infinity)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .fullScreenCover(isPresented: $store.isPresentedTabViewer.sending(\.isPresentedTabViewer), content: {
                        NavigationStack {
                            GeometryReader(content: { proxy in
                                TabViewer<LocalAsset>(
                                    items: store.localAssets,
                                    current: store.currentLocalAsset,
                                    controlingToolbars: [.navigationBar, .tabBar],
                                    isSelectable: true,
                                    selectedItems: store.selectedLocalAssets,
                                    itemView: { item, isFullScreen in
                                        AnyView(Group {
                                            if item.isVideo {
                                                LoopVideoPlayerView(asset: item, size: proxy.size, suppressLoop: true, isShowControl: !isFullScreen, autoHeight: true)
                                                    .ignoresSafeArea()
                                            } else {
                                                GeometryReader { g in
                                                    Group {
                                                        ZoomableScrollView {
                                                            LocalImageView(asset: item, size: proxy.size, scaleType: .fit, autoHeight: true)
                                                                .ignoresSafeArea()
                                                        }
                                                    }
                                                    .position(x: g.frame(in: .local).midX, y: g.frame(in: .local).midY)
                                                }
                                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                            }
                                        })
                                    },
                                    onChangeIndex: { _, item in
                                        store.send(.setCurrentLocalAsset(item))
                                        reader.scrollTo(item.groupedDate()?.ISO8601Format() ?? "", anchor: .top)
                                    }
                                ) { selectedItems in
                                    store.send(.setSelectedLocalAsset(selectedItems))
                                    store.send(.isPresentedTabViewer(false))
                                    store.send(.setCurrentLocalAsset(nil))
                                }
                            })
                        }
                    })
                    .transaction { transaction in
                        transaction.disablesAnimations = true
                    }
                }
            }
        }
    }
}
