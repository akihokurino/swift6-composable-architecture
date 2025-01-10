import ComposableArchitecture
import Foundation

@Reducer
struct HomeReducer {
    @Dependency(\.gqlClient) var gqlClient

    @Reducer
    enum Destination {
        case pologDetail(PologDetailReducer)
    }

    @ObservableState
    struct State: Equatable {
        // common
        var isInitialized = false
        var alert: AlertEntity?
        var isPresentedHUD = false
        var isPresentedAlert = false

        // data
        @Shared(.inMemory("sharedUserInfo")) var loginUser: SharedUserInfo?
        var recomendedPologs: WithCursor<PologOverview>?
        var latestPologs: WithCursor<PologOverview>?
        var followingPologs: WithCursor<PologOverview>?
        var tabSelection: Int = 0

        // presentation
        var isPresentedNextLoading = false
        var isPresentedPullToRefresh = false

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
        case fetchRecommendedPologs(Bool)
        case fetchLatestPologs(Bool)
        case fetchFollowingPologs(Bool)

        // setter
        case setRecommendedPologs(WithCursor<PologOverview>)
        case setLatestPologs(WithCursor<PologOverview>)
        case setFollowingPologs(WithCursor<PologOverview>)
        case setTabSelection(Int)

        // presentation
        case isPresentedNextLoading(Bool)
        case isPresentedPullToRefresh(Bool)
        case presentPologDetailView(PologOverview)

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
                return .none
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
            case .fetchRecommendedPologs(let isRefresh):
                var _pager = state.recomendedPologs
                if _pager == nil {
                    _pager = WithCursor.new()
                    state.isPresentedHUD = true
                } else if isRefresh {
                    _pager = WithCursor.new()
                    state.isPresentedPullToRefresh = true
                } else {
                    state.isPresentedNextLoading = true
                }
                let pager = _pager!
                let cursor = pager.cursor
                let limit = pager.limit

                return .run { send in
                    do {
                        let itemsWithCursor = try (await gqlClient.query(PologAPI.GetRecommendedPologsQuery(cursor: gqlOption(cursor), limit: limit))).recommendedPologs
                        await send(.setRecommendedPologs(pager.next(itemsWithCursor.nodes.map { $0.fragments.pologOverviewFragment }, cursor: itemsWithCursor.pageInfo.endCursor, hasNext: itemsWithCursor.pageInfo.hasNextPage)))
                    } catch {
                        await send(.setAlert(AlertEntity.from(error: error)))
                    }

                    await send(.isPresentedHUD(false))
                    await send(.isPresentedPullToRefresh(false))
                    await send(.isPresentedNextLoading(false))
                }
            case .fetchLatestPologs(let isRefresh):
                var _pager = state.latestPologs
                if _pager == nil {
                    _pager = WithCursor.new()
                    state.isPresentedHUD = true
                } else if isRefresh {
                    _pager = WithCursor.new()
                    state.isPresentedPullToRefresh = true
                } else {
                    state.isPresentedNextLoading = true
                }
                let pager = _pager!
                let cursor = pager.cursor
                let limit = pager.limit

                return .run { send in
                    do {
                        let itemsWithCursor = try (await gqlClient.query(PologAPI.GetLatestPologsQuery(cursor: gqlOption(cursor), limit: limit))).pologs
                        await send(.setLatestPologs(pager.next(itemsWithCursor.nodes.map { $0.fragments.pologOverviewFragment }, cursor: itemsWithCursor.pageInfo.endCursor, hasNext: itemsWithCursor.pageInfo.hasNextPage)))
                    } catch {
                        await send(.setAlert(AlertEntity.from(error: error)))
                    }

                    await send(.isPresentedHUD(false))
                    await send(.isPresentedPullToRefresh(false))
                    await send(.isPresentedNextLoading(false))
                }
            case .fetchFollowingPologs(let isRefresh):
                var _pager = state.followingPologs
                if _pager == nil {
                    _pager = WithCursor.new()
                    state.isPresentedHUD = true
                } else if isRefresh {
                    _pager = WithCursor.new()
                    state.isPresentedPullToRefresh = true
                } else {
                    state.isPresentedNextLoading = true
                }
                let pager = _pager!
                let cursor = pager.cursor
                let limit = pager.limit

                return .run { send in
                    do {
                        let itemsWithCursor = try (await gqlClient.query(PologAPI.GetMyFollowingPologsQuery(cursor: gqlOption(cursor), limit: limit))).me.followingPologs
                        await send(.setFollowingPologs(pager.next(itemsWithCursor.nodes.map { $0.fragments.pologOverviewFragment }, cursor: itemsWithCursor.pageInfo.endCursor, hasNext: itemsWithCursor.pageInfo.hasNextPage)))
                    } catch {
                        await send(.setAlert(AlertEntity.from(error: error)))
                    }

                    await send(.isPresentedHUD(false))
                    await send(.isPresentedPullToRefresh(false))
                    await send(.isPresentedNextLoading(false))
                }
            // ----------------------------------------------------------------
            // setter
            // ----------------------------------------------------------------
            case .setRecommendedPologs(let val):
                state.recomendedPologs = val
                return .none
            case .setLatestPologs(let val):
                state.latestPologs = val
                return .none
            case .setFollowingPologs(let val):
                state.followingPologs = val
                return .none
            case .setTabSelection(let val):
                state.tabSelection = val
                return .none
            // ----------------------------------------------------------------
            // presentation
            // ----------------------------------------------------------------
            case .isPresentedNextLoading(let val):
                state.isPresentedNextLoading = val
                return .none
            case .isPresentedPullToRefresh(let val):
                state.isPresentedPullToRefresh = val
                return .none
            case .presentPologDetailView(let polog):
                state.destination = .pologDetail(PologDetailReducer.State(pologId: polog.id))
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
}

extension HomeReducer.Destination.State: Equatable {}
