import ComposableArchitecture
import Foundation

@Reducer
struct AssetSelectReducer {
    @Dependency(\.dismiss) var dismiss
    @Dependency(\.photosClient) var photosClient
    @Dependency(\.gqlClient) var gqlClient

    @Reducer
    enum Destination {}

    @ObservableState
    struct State: Equatable {
        // common
        var isInitialized = false
        var alert: AlertEntity?
        var isPresentedHUD = false
        var isPresentedAlert = false

        // data
        var onlyLocalAsset = false
        var onlyPhotoAsset = false
        var tabSelection = 0
        var localAlbums: [LocalAssetCollection] = []
        var localAssets: [LocalAsset] = []
        var selectedLocalAlbum: LocalAssetCollection?
        var selectedLocalAssets: Set<LocalAsset> = Set()
        var groups: WithCursor<UserGroupOverview>?
        var groupAlbums: WithCursor<GroupAlbumOverview>?
        var groupAssets: WithCursor<GroupAsset>?
        var selectedGroup: UserGroupOverview?
        var selectedGroupAlbum: GroupAlbumOverview?
        var selectedGroupAssets: Set<GroupAsset> = Set()
        var groupAssetViewType: GroupAssetViewType = .groupList
        var selectMode: SelectMode = .multiple
        var currentLocalAsset: LocalAsset? = nil
        var currentGroupAsset: GroupAsset? = nil

        var selectedAssetCount: Int {
            return selectedLocalAssets.count + selectedGroupAssets.count
        }

        // presentation
        var isPresentedTabViewer = false

        // destination
        @Presents var destination: Destination.State?
    }

    enum Action {
        // common
        case initialize
        case setAlert(AlertEntity)
        case isPresentedHUD(Bool)
        case isPresentedAlert(Bool)

        // action
        case dismiss
        case confirm
        case finish([Asset])
        case selectLocalAlbum(LocalAssetCollection?)
        case selectLocalAssets([LocalAsset])
        case unSelectLocalAssets([LocalAsset])
        case selectGroup(UserGroupOverview)
        case selectGroupAlbum(GroupAlbumOverview)
        case selectGroupAssets([GroupAsset])
        case unSelectGroupAssets([GroupAsset])

        // setter
        case setTabSelection(Int)
        case setLocalAlbums([LocalAssetCollection])
        case setLocalAssets([LocalAsset])
        case setGroups(WithCursor<UserGroupOverview>)
        case setGroupAlbums(WithCursor<GroupAlbumOverview>?)
        case setGroupAssets(WithCursor<GroupAsset>?)
        case setGroupAssetViewType(GroupAssetViewType)
        case setSelectMode(SelectMode)
        case setCurrentLocalAsset(LocalAsset?)
        case setCurrentGroupAsset(GroupAsset?)
        case setSelectedLocalAsset(Set<LocalAsset>)
        case setSelectedGroupAsset(Set<GroupAsset>)

        // presentation
        case isPresentedTabViewer(Bool)

        // destination
        case destination(PresentationAction<Destination.Action>)
    }

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            // ----------------------------------------------------------------
            // common
            // ----------------------------------------------------------------
            case .initialize:
                guard !state.isInitialized else {
                    return .none
                }
                state.isInitialized = true
                state.isPresentedHUD = true
                let onlyLocalAsset = state.onlyLocalAsset
                let onlyPhotoAsset = state.onlyPhotoAsset

                return .run { send in
                    let status = await photosClient.requestAuthorization()

                    await withTaskGroup(of: Void.self) { group in
                        group.addTask {
                            if status == .authorized || status == .limited {
                                let albums = await photosClient.getAlbums()
                                await send(.setLocalAlbums(albums))
                            }
                        }

                        group.addTask {
                            if status == .authorized || status == .limited {
                                let assets = await photosClient.getAssets(filter: onlyPhotoAsset ? .photo : nil)
                                await send(.setLocalAssets(assets))
                            }
                        }

                        if !onlyLocalAsset {
                            group.addTask {
                                do {
                                    let itemsWithCursor = try (await gqlClient.query(PologAPI.GetMyGroupsQuery(cursor: gqlOption(nil), limit: 10000))).me.groups
                                    let pager = WithCursor<UserGroupOverview>.new()
                                    await send(.setGroups(pager.next(itemsWithCursor.nodes.map { $0.fragments.groupOverviewFragment }, cursor: itemsWithCursor.pageInfo.endCursor, hasNext: itemsWithCursor.pageInfo.hasNextPage)))
                                } catch {
                                    await send(.setAlert(AlertEntity.from(error: error)))
                                }
                            }
                        }
                    }

                    await send(.isPresentedHUD(false))
                }
            case .setAlert(let entity):
                state.alert = entity
                state.isPresentedAlert = true
                return .none
            case .isPresentedHUD(let val):
                state.isPresentedHUD = val
                return .none
            case .isPresentedAlert(let val):
                state.isPresentedAlert = val
                return .none
            // ----------------------------------------------------------------
            // action
            // ----------------------------------------------------------------
            case .dismiss:
                return .run { _ in
                    await dismiss()
                }
            case .confirm:
                let selected = (Array(state.selectedLocalAssets), Array(state.selectedGroupAssets))
                guard (selected.0.count + selected.1.count) > 0 else {
                    return .none
                }
                let results = state.selectedLocalAssets.map { Asset.from(local: $0) } + state.selectedGroupAssets.map { Asset.from(group: $0) }
                return Effect.send(.finish(results))
            case .finish:
                // delegate
                return .run { _ in
                    await dismiss()
                }
            case .selectLocalAlbum(let album):
                state.selectedLocalAlbum = album
                let onlyPhotoAsset = state.onlyPhotoAsset

                return .run { send in
                    let assets = await photosClient.getAssets(
                        album: album,
                        filter: onlyPhotoAsset ? .photo : nil)
                    await send(.setLocalAssets(assets))
                }
            case .selectLocalAssets(let assets):
                guard !assets.isEmpty else {
                    return .none
                }

                switch state.selectMode {
                case .single:
                    state.selectedLocalAssets.removeAll()
                    state.selectedLocalAssets.insert(assets.first!)
                case .multiple:
                    for asset in assets {
                        state.selectedLocalAssets.insert(asset)
                    }
                }

                return .none
            case .unSelectLocalAssets(let assets):
                guard !assets.isEmpty else {
                    return .none
                }

                switch state.selectMode {
                case .single:
                    state.selectedLocalAssets.removeAll()
                case .multiple:
                    for asset in assets {
                        state.selectedLocalAssets.remove(asset)
                    }
                }

                return .none
            case .selectGroup(let group):
                state.selectedGroup = group

                return .run { send in
                    do {
                        let itemsWithCursor = try (await gqlClient.query(PologAPI.GetGroupAlbumsQuery(cursor: gqlOption(nil), limit: 10000, groupId: group.id))).group.albums
                        let pager = WithCursor<GroupAlbumOverview>.new()
                        await send(.setGroupAlbums(pager.next(itemsWithCursor.nodes.map { $0.fragments.groupAlbumOverviewFragment }, cursor: itemsWithCursor.pageInfo.endCursor, hasNext: itemsWithCursor.pageInfo.hasNextPage)))
                    } catch {
                        await send(.setAlert(AlertEntity.from(error: error)))
                    }

                    await send(.setGroupAssetViewType(.groupAlbumList))
                }
            case .selectGroupAlbum(let album):
                state.selectedGroupAlbum = album
                let onlyPhotoAsset = state.onlyPhotoAsset

                return .run { send in
                    do {
                        let itemsWithCursor = try (await gqlClient.query(PologAPI.GetGroupAssetsQuery(cursor: gqlOption(nil), limit: 10000, albumId: album.id, kind: gqlEnumOption(onlyPhotoAsset ? .photo : nil)))).groupAlbum.assets
                        let pager = WithCursor<GroupAsset>.new()
                        await send(.setGroupAssets(pager.next(itemsWithCursor.nodes.map { $0.fragments.groupAssetFragment }, cursor: itemsWithCursor.pageInfo.endCursor, hasNext: itemsWithCursor.pageInfo.hasNextPage)))
                    } catch {
                        await send(.setAlert(AlertEntity.from(error: error)))
                    }

                    await send(.setGroupAssetViewType(.groupAssetList))
                }
            case .selectGroupAssets(let assets):
                guard !assets.isEmpty else {
                    return .none
                }

                switch state.selectMode {
                case .single:
                    state.selectedGroupAssets.removeAll()
                    state.selectedGroupAssets.insert(assets.first!)
                case .multiple:
                    for asset in assets {
                        state.selectedGroupAssets.insert(asset)
                    }
                }

                return .none
            case .unSelectGroupAssets(let assets):
                guard !assets.isEmpty else {
                    return .none
                }

                switch state.selectMode {
                case .single:
                    state.selectedGroupAssets.removeAll()
                case .multiple:
                    for asset in assets {
                        state.selectedGroupAssets.remove(asset)
                    }
                }

                return .none
            // ----------------------------------------------------------------
            // setter
            // ----------------------------------------------------------------
            case .setTabSelection(let val):
                state.tabSelection = val
                return .none
            case .setLocalAlbums(let val):
                state.localAlbums = val
                return .none
            case .setLocalAssets(let val):
                state.localAssets = val
                return .none
            case .setGroups(let val):
                state.groups = val
                return .none
            case .setGroupAlbums(let val):
                state.groupAlbums = val
                return .none
            case .setGroupAssets(let val):
                state.groupAssets = val
                return .none
            case .setGroupAssetViewType(let val):
                state.groupAssetViewType = val
                return .none
            case .setSelectMode(let val):
                state.selectMode = val
                return .none
            case .setCurrentLocalAsset(let asset):
                state.currentLocalAsset = asset
                return .none
            case .setCurrentGroupAsset(let asset):
                state.currentGroupAsset = asset
                return .none
            case .setSelectedLocalAsset(let val):
                state.selectedLocalAssets = val
                return .none
            case .setSelectedGroupAsset(let val):
                state.selectedGroupAssets = val
                return .none
            // ----------------------------------------------------------------
            // presentation
            // ----------------------------------------------------------------
            case .isPresentedTabViewer(let val):
                state.isPresentedTabViewer = val
                return .none
            // ----------------------------------------------------------------
            // destination
            // ----------------------------------------------------------------
            case .destination(let action):
                guard let action = action.presented else {
                    return .none
                }
                switch action {
                default:
                    return .none
                }
            }
        }
        .ifLet(\.$destination, action: \.destination)
    }

    enum GroupAssetViewType {
        case groupList
        case groupAlbumList
        case groupAssetList
    }

    enum SelectMode {
        case single
        case multiple
    }
}

extension AssetSelectReducer.Destination.State: Equatable {}
