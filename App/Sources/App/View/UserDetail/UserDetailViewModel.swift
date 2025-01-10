import ComposableArchitecture
import Foundation

@Reducer
struct UserDetailReducer {
    @Dependency(\.dismiss) var dismiss
    @Dependency(\.gqlClient) var gqlClient

    @Reducer
    enum Destination {
        case followList(FollowListReducer)
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
        let userId: String
        var user: User?
        var pologListType: PologListType = .myPologs
        var pologSummary: PologSummary?
        var pologs: WithCursor<PologOverview>?
        var isFollowing: Bool = false
        var isFollowRequesting: Bool = false

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
        case fetchPologSummary
        case fetchPologs(Bool)
        case toggleFollow

        // setter
        case setUser(User)
        case setPologListType(PologListType)
        case setPologSummary(PologSummary)
        case setPologs(WithCursor<PologOverview>)
        case setFollowing(Bool)
        case setFollowRequesting(Bool)

        // presentation
        case isPresentedNextLoading(Bool)
        case isPresentedPullToRefresh(Bool)
        case presentFollowListView(Int)
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
                state.isPresentedHUD = true
                let userId = state.userId

                return .run { send in
                    do {
                        let user = try (await gqlClient.query(PologAPI.GetUserQuery(userId: userId))).user.fragments.userFragment
                        await send(.setUser(user))
                    } catch {
                        await send(.setAlert(AlertEntity.from(error: error)))
                    }

                    await send(.isPresentedHUD(false))
                    await send(.fetchPologSummary)
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
            case .fetchPologSummary:
                guard let user = state.user, user.isEnableShow else {
                    return .none
                }
                return .run { send in
                    do {
                        let summary = try (await gqlClient.query(PologAPI.GetPologSummaryQuery(userId: user.id))).user.pologSummary.fragments.pologSummaryFragment
                        await send(.setPologSummary(summary))
                    } catch {
                        await send(.setAlert(AlertEntity.from(error: error)))
                    }
                }
            case .fetchPologs(let isRefresh):
                guard let user = state.user, user.isEnableShow else {
                    return .none
                }
                var _pager = state.pologs
                if _pager == nil {
                    _pager = WithCursor.new()
                } else if isRefresh {
                    _pager = WithCursor.new()
                    state.isPresentedPullToRefresh = true
                } else {
                    state.isPresentedNextLoading = true
                }
                let pager = _pager!
                let cursor = pager.cursor
                let limit = pager.limit
                let listType = state.pologListType

                return .run { send in
                    do {
                        switch listType {
                        case .myPologs:
                            let itemsWithCursor = try (await gqlClient.query(PologAPI.GetPologsQuery(
                                userId: user.id,
                                cursor: gqlOption(cursor),
                                limit: limit,
                                q: gqlOption(nil),
                                sortType: gqlEnum(PologAPI.PologSortType.createdAt),
                                filter: gqlOption(nil)))).user.pologs
                            await send(.setPologs(pager.next(itemsWithCursor.nodes.map { $0.fragments.pologOverviewFragment }, cursor: itemsWithCursor.pageInfo.endCursor, hasNext: itemsWithCursor.pageInfo.hasNextPage)))
                        case .accompaniedPolog:
                            let itemsWithCursor = try (await gqlClient.query(PologAPI.GetAccompaniedPologsQuery(
                                userId: user.id,
                                cursor: gqlOption(cursor),
                                limit: limit,
                                q: gqlOption(nil),
                                sortType: gqlEnum(PologAPI.PologSortType.createdAt),
                                filter: gqlOption(nil)))).user.accompaniedPologs
                            await send(.setPologs(pager.next(itemsWithCursor.nodes.map { $0.fragments.pologOverviewFragment }, cursor: itemsWithCursor.pageInfo.endCursor, hasNext: itemsWithCursor.pageInfo.hasNextPage)))
                        }
                    } catch {
                        await send(.setAlert(AlertEntity.from(error: error)))
                    }

                    await send(.isPresentedHUD(false))
                    await send(.isPresentedPullToRefresh(false))
                    await send(.isPresentedNextLoading(false))
                }
            case .toggleFollow:
                guard let user = state.user else {
                    return .none
                }
                state.isPresentedHUD = true
                let following = state.isFollowing

                return .run { send in
                    do {
                        if following {
                            let _ = try await gqlClient.mutation(PologAPI.UnFollowUserMutation(toUserId: user.id))
                            await send(.setFollowing(false))
                        } else {
                            let _ = try await gqlClient.mutation(PologAPI.FollowUserMutation(toUserId: user.id))
                            if !user.isPublic {
                                await send(.setAlert(AlertEntity(title: "フォローのリクエスト", message: "フォローのリクエストを送信しました")))
                                await send(.setFollowRequesting(true))
                            } else {
                                await send(.setFollowing(true))
                            }
                        }

                        await send(.isPresentedHUD(false))
                    } catch {
                        await send(.setAlert(AlertEntity.from(error: error)))
                    }
                }
            // ----------------------------------------------------------------
            // setter
            // ----------------------------------------------------------------
            case .setUser(let val):
                state.user = val
                state.isFollowing = val.isFollowing
                state.isFollowRequesting = val.isFollowRequesting
                return .none
            case .setPologListType(let val):
                state.pologListType = val
                return .none
            case .setPologSummary(let val):
                state.pologSummary = val
                return .none
            case .setPologs(let val):
                state.pologs = val
                return .none
            case .setFollowing(let val):
                state.isFollowing = val
                return .none
            case .setFollowRequesting(let val):
                state.isFollowRequesting = val
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
            case .presentFollowListView(let tabSelection):
                guard let user = state.user else {
                    return .none
                }
                state.destination = .followList(FollowListReducer.State(userId: user.id, tabSelection: tabSelection))
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

    enum PologListType: Equatable {
        case myPologs
        case accompaniedPolog
    }
}

extension UserDetailReducer.Destination.State: Equatable {}
