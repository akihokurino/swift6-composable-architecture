import ComposableArchitecture
import Foundation

@Reducer
struct PologCommentListReducer {
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
        let pologId: String
        var comments: WithCursor<PologComment>?
        var comment: String = ""

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
        case fetchComments(Bool)
        case sendComment

        // setter
        case setComments(WithCursor<PologComment>)
        case setComment(String)

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
                    await send(.fetchComments(true))
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
            case .fetchComments(let isRefresh):
                var _pager = state.comments
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
                let pologId = state.pologId

                return .run { send in
                    do {
                        let itemsWithCursor = try (await gqlClient.query(PologAPI.GetPologCommentsQuery(pologId: pologId, cursor: gqlOption(cursor), limit: limit))).polog.comments
                        await send(.setComments(pager.next(
                            itemsWithCursor.nodes.map { $0.fragments.pologCommentFragment },
                            cursor: itemsWithCursor.pageInfo.endCursor,
                            hasNext: itemsWithCursor.pageInfo.hasNextPage)))
                    } catch {
                        await send(.setAlert(AlertEntity.from(error: error)))
                    }

                    await send(.isPresentedHUD(false))
                    await send(.isPresentedPullToRefresh(false))
                    await send(.isPresentedNextLoading(false))
                }
            case .sendComment:
                guard state.comment.isNotEmpty else {
                    return .none
                }

                state.isPresentedHUD = true
                let pologId = state.pologId
                let pager = state.comments ?? WithCursor.new()
                let text = state.comment

                return .run { send in
                    do {
                        let comment = try (await gqlClient.mutation(PologAPI.CreatePologCommentMutation(pologId: pologId, text: text))).pologCommentCreate.fragments.pologCommentFragment
                        await send(.setComments(pager.insert(comment)))
                        await send(.setComment(""))
                    } catch {
                        await send(.setAlert(AlertEntity.from(error: error)))
                    }

                    await send(.isPresentedHUD(false))
                }
            // ----------------------------------------------------------------
            // setter
            // ----------------------------------------------------------------
            case .setComments(let val):
                state.comments = val
                return .none
            case .setComment(let val):
                state.comment = val
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

extension PologCommentListReducer.Destination.State: Equatable {}
