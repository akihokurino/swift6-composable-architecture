import ComposableArchitecture
import Foundation

@Reducer
struct ClippedPologListReducer {
    @Dependency(\.dismiss) var dismiss
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
        @Shared(.inMemory("sharedUserInfo")) var loginUser: SharedUserInfo?
        var pologs: WithCursor<PologOverview>?

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
        case dismiss
        case fetchPologs(Bool)

        // setter
        case setPologs(WithCursor<PologOverview>)

        // presentation
        case isPresentedNextLoading(Bool)
        case isPresentedPullToRefresh(Bool)

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
                return .run { send in
                    await send(.fetchPologs(true))
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
            case .fetchPologs(let isRefresh):
                var _pager = state.pologs
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
                        let itemsWithCursor = try (await gqlClient.query(PologAPI.GetMyClippedPologsQuery(cursor: gqlOption(cursor), limit: limit))).me.clippedPologs
                        await send(.setPologs(pager.next(itemsWithCursor.nodes.map { $0.fragments.pologOverviewFragment }, cursor: itemsWithCursor.pageInfo.endCursor, hasNext: itemsWithCursor.pageInfo.hasNextPage)))
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
            case .setPologs(let val):
                state.pologs = val
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

extension ClippedPologListReducer.Destination.State: Equatable {}
