import ComposableArchitecture
import SwiftUI

extension AssetSelectView {
    struct GroupAssetSelectView: View {
        @Bindable var store: StoreOf<AssetSelectReducer>

        var body: some View {
            Group {
                switch store.groupAssetViewType {
                case .groupList:
                    GroupListView(store: store)
                case .groupAlbumList:
                    GroupAlbumListView(store: store)
                case .groupAssetList:
                    GroupAssetListView(store: store)
                }
            }
        }
    }
}

extension AssetSelectView {
    struct GroupListView: View {
        @Bindable var store: StoreOf<AssetSelectReducer>

        var body: some View {
            PagingListView<UserGroupOverview>(
                listRowSeparator: .visible,
                itemView: { group in
                    AnyView(GroupView(group: group))
                },
                onTap: { group in
                    store.send(.selectGroup(group))
                },
                onNext: {},
                onRefresh: {},
                headerView: {
                    AnyView(
                        VStack(alignment: .leading) {
                            Spacer20()
                            Text("グループ")
                                .bold()
                                .font(.subheadline)
                                .foregroundColor(Color(UIColor.secondaryLabel))
                                .padding(.horizontal, 16)
                            Spacer8()
                            Divider()
                        }
                    )
                },
                data: store.groups,
                isLoading: Binding.constant(false),
                isRefreshing: Binding.constant(false)
            )
            .listStyle(PlainListStyle())
        }
    }
}

extension AssetSelectView {
    struct GroupView: View {
        let group: UserGroupOverview

        var body: some View {
            HStack {
                Text(group.name)
                    .font(.body)
                    .foregroundColor(Color(UIColor.label))
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(Color(UIColor.tertiaryLabel))
            }
            .padding(.horizontal, 16)
            .frame(height: 60)
        }
    }
}

extension AssetSelectView {
    struct GroupAlbumListView: View {
        @Bindable var store: StoreOf<AssetSelectReducer>

        var body: some View {
            VStack {
                HStack {
                    Button(action: {
                        store.send(.setGroupAssetViewType(.groupList))
                        store.send(.setGroupAlbums(nil))
                        store.send(.setGroupAssets(nil))
                    }) {
                        Text("グループ")
                            .font(.subheadline)
                            .foregroundColor(Color(UIColor.secondaryLabel))
                    }

                    Spacer8()
                    Image(systemName: "chevron.right")
                        .foregroundColor(Color(UIColor.tertiaryLabel))
                    Spacer8()

                    Button(action: {
                        store.send(.setGroupAssetViewType(.groupAlbumList))
                        store.send(.setGroupAssets(nil))
                    }) {
                        Text(store.selectedGroup?.name ?? "")
                            .font(.subheadline)
                            .foregroundColor(Color(UIColor.label))
                    }

                    Spacer()
                }
                .padding(.horizontal, 16)
                .frame(height: 46)
                .background(Color(UIColor.secondarySystemBackground))

                PagingListView<GroupAlbumOverview>(
                    listRowSeparator: .visible,
                    itemView: { album in
                        AnyView(GroupAlbumView(album: album))
                    },
                    onTap: { album in
                        store.send(.selectGroupAlbum(album))
                    },
                    onNext: {},
                    onRefresh: {},
                    headerView: {
                        AnyView(
                            VStack(alignment: .leading) {
                                Spacer20()
                                Text("アルバム")
                                    .bold()
                                    .font(.subheadline)
                                    .foregroundColor(Color(UIColor.secondaryLabel))
                                    .padding(.horizontal, 16)
                                Spacer8()
                                Divider()
                            }
                        )
                    },
                    data: store.groupAlbums,
                    isLoading: Binding.constant(false),
                    isRefreshing: Binding.constant(false)
                )
                .listStyle(PlainListStyle())
            }
        }
    }
}

extension AssetSelectView {
    struct GroupAlbumView: View {
        let album: GroupAlbumOverview

        var body: some View {
            HStack {
                Text(album.name)
                    .foregroundColor(Color(UIColor.label))
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(Color(UIColor.tertiaryLabel))
            }
            .padding(.horizontal, 16)
            .frame(height: 60)
        }
    }
}

extension AssetSelectView {
    struct GroupAssetListView: View {
        @Bindable var store: StoreOf<AssetSelectReducer>

        var body: some View {
            GeometryReader { geometry in
                ScrollViewReader { reader in
                    VStack {
                        HStack {
                            Button(action: {
                                store.send(.setGroupAssetViewType(.groupList))
                                store.send(.setGroupAlbums(nil))
                                store.send(.setGroupAssets(nil))
                            }) {
                                Text("グループ")
                                    .font(.subheadline)
                                    .foregroundColor(Color(UIColor.secondaryLabel))
                            }

                            Spacer8()
                            Image(systemName: "chevron.right")
                                .foregroundColor(Color(UIColor.tertiaryLabel))
                            Spacer8()

                            Button(action: {
                                store.send(.setGroupAssetViewType(.groupAlbumList))
                                store.send(.setGroupAssets(nil))
                            }) {
                                Text(store.selectedGroup?.name ?? "")
                                    .font(.subheadline)
                                    .foregroundColor(Color(UIColor.secondaryLabel))
                            }

                            Spacer8()
                            Image(systemName: "chevron.right")
                                .foregroundColor(Color(UIColor.tertiaryLabel))
                            Spacer8()

                            Button(action: {}) {
                                Text(store.selectedGroupAlbum?.name ?? "")
                                    .font(.subheadline)
                                    .foregroundColor(Color(UIColor.label))
                            }

                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .frame(height: 46)
                        .background(Color(UIColor.secondarySystemBackground))

                        DateGroupPagingScrollView<GroupAsset>(
                            itemView: { group in
                                AnyView(VStack(alignment: .leading) {
                                    Spacer20()

                                    HStack {
                                        Text(group.date.dateDisplayJST)
                                            .font(.title3)
                                            .foregroundColor(Color(UIColor.secondaryLabel))
                                        Spacer()

                                        if store.selectMode == .multiple {
                                            if group.isAllSelected(selected: store.selectedGroupAssets) {
                                                Button(action: {
                                                    store.send(.unSelectGroupAssets(group.assets))
                                                }) {
                                                    Image(systemName: "checkmark")
                                                        .foregroundColor(.white)
                                                        .frame(width: 25, height: 25)
                                                        .background(Circle().foregroundColor(Color.black))
                                                }
                                            } else {
                                                Button(action: {
                                                    store.send(.selectGroupAssets(group.assets))
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
                                        ForEach(group.assets, id: \.self) { asset in
                                            ZStack {
                                                Button(action: {
                                                    store.send(.setCurrentGroupAsset(asset))
                                                    store.send(.isPresentedTabViewer(true))
                                                }) {
                                                    ZStack {
                                                        RemoteImageView(
                                                            url: asset.thumbnailUrl,
                                                            size: CGSize(
                                                                width: (geometry.size.width - 4) / 3,
                                                                height: (geometry.size.width - 4) / 3
                                                            )
                                                        )

                                                        HStack {
                                                            Spacer()
                                                            VStack {
                                                                Spacer()
                                                                Text(asset.displayDurationSecond)
                                                                Spacer4()
                                                            }
                                                            Spacer4()
                                                        }
                                                    }
                                                }

                                                VStack {
                                                    Spacer8()
                                                    HStack {
                                                        Spacer()
                                                        if store.selectedGroupAssets.contains(asset) {
                                                            Button(action: {
                                                                store.send(.unSelectGroupAssets([asset]))
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
                                                                store.send(.selectGroupAssets([asset]))
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
                                })
                            },
                            onNext: {},
                            onRefresh: {},
                            data: store.groupAssets,
                            isLoading: Binding.constant(false),
                            isRefreshing: Binding.constant(false)
                        )
                    }
                    .frame(maxWidth: .infinity)
                    .fullScreenCover(isPresented: $store.isPresentedTabViewer.sending(\.isPresentedTabViewer), content: {
                        NavigationStack {
                            GeometryReader(content: { proxy in
                                TabViewer<GroupAsset>(
                                    items: store.groupAssets?.items ?? [],
                                    current: store.currentGroupAsset,
                                    controlingToolbars: [.navigationBar, .tabBar],
                                    isSelectable: true,
                                    selectedItems: store.selectedGroupAssets,
                                    itemView: { item, isFullScreen in
                                        AnyView(Group {
                                            if item.isVideo {
                                                LoopVideoPlayerView(url: item.gsUrl.url, size: proxy.size, suppressLoop: true, isShowControl: !isFullScreen, autoHeight: true)
                                                    .ignoresSafeArea()
                                            } else {
                                                GeometryReader { g in
                                                    Group {
                                                        ZoomableScrollView {
                                                            RemoteImageView(
                                                                url: item.thumbnailUrl,
                                                                size: proxy.size,
                                                                scaleType: .fit,
                                                                autoHeight: true
                                                            )
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
                                        store.send(.setCurrentGroupAsset(item))
                                        reader.scrollTo(item.groupedDate()?.ISO8601Format() ?? "", anchor: .top)
                                    }
                                ) { selectedItems in
                                    store.send(.setSelectedGroupAsset(selectedItems))
                                    store.send(.isPresentedTabViewer(false))
                                    store.send(.setCurrentGroupAsset(nil))
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
