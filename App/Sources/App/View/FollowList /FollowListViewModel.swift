import ComposableArchitecture
import Foundation

@Reducer
struct FollowListReducer {
    @Dependency(\.dismiss) var dismiss
    @Dependency(\.gqlClient) var gqlClient

    @Reducer
    enum Destination {
        case userDetail(UserDetailReducer)
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
        var followees: WithCursor<UserOverview>?
        var followers: WithCursor<UserOverview>?
        var followingMap: [String: Bool] = [:]
        var blockingMap: [String: Bool] = [:]
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
        case dismiss
        case fetchFollowees(Bool)
        case fetchFollowers(Bool)
        case toggleFollow(UserOverview)
        case setFollowingMap((String, Bool))

        // setter
        case setUser(User)
        case setFollowees(WithCursor<UserOverview>)
        case setFollowers(WithCursor<UserOverview>)
        case setTabSelection(Int)

        // presentation
        case isPresentedNextLoading(Bool)
        case isPresentedPullToRefresh(Bool)
        case presentUserDetailView(UserOverview)

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
                    await send(.fetchFollowees(true))
                    await send(.fetchFollowers(true))
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
            case .fetchFollowees(let isRefresh):
                var _pager = state.followees
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
                let userId = state.userId

                return .run { send in
                    do {
                        let itemsWithCursor = try (await gqlClient.query(PologAPI.GetFolloweesQuery(userId: userId, cursor: gqlOption(cursor), limit: limit))).user.followees
                        await send(.setFollowees(pager.next(itemsWithCursor.nodes.map { $0.fragments.userOverviewFragment }, cursor: itemsWithCursor.pageInfo.endCursor, hasNext: itemsWithCursor.pageInfo.hasNextPage)))
                    } catch {
                        await send(.setAlert(AlertEntity.from(error: error)))
                    }

                    await send(.isPresentedHUD(false))
                    await send(.isPresentedPullToRefresh(false))
                    await send(.isPresentedNextLoading(false))
                }
            case .fetchFollowers(let isRefresh):
                var _pager = state.followers
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
                let userId = state.userId

                return .run { send in
                    do {
                        let itemsWithCursor = try (await gqlClient.query(PologAPI.GetFollowersQuery(userId: userId, cursor: gqlOption(cursor), limit: limit))).user.followers
                        await send(.setFollowers(pager.next(itemsWithCursor.nodes.map { $0.fragments.userOverviewFragment }, cursor: itemsWithCursor.pageInfo.endCursor, hasNext: itemsWithCursor.pageInfo.hasNextPage)))
                    } catch {
                        await send(.setAlert(AlertEntity.from(error: error)))
                    }

                    await send(.isPresentedHUD(false))
                    await send(.isPresentedPullToRefresh(false))
                    await send(.isPresentedNextLoading(false))
                }
            case .toggleFollow(let user):
                guard let following = state.followingMap[user.id] else {
                    return .none
                }
                state.isPresentedHUD = true

                return .run { send in
                    do {
                        if following {
                            let _ = try await gqlClient.mutation(PologAPI.UnFollowUserMutation(toUserId: user.id))
                            await send(.setFollowingMap((user.id, !following)))
                        } else {
                            let _ = try await gqlClient.mutation(PologAPI.FollowUserMutation(toUserId: user.id))
                            if !user.isPublic {
                                await send(.setAlert(AlertEntity(title: "フォローのリクエスト", message: "フォローのリクエストを送信しました")))
                            } else {
                                await send(.setFollowingMap((user.id, !following)))
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
                return .none
            case .setFollowees(let val):
                for user in val.items {
                    state.followingMap[user.id] = user.isFollowing
                    state.blockingMap[user.id] = user.isBlocking
                }
                state.followees = val
                return .none
            case .setFollowers(let val):
                for user in val.items {
                    state.followingMap[user.id] = user.isFollowing
                    state.blockingMap[user.id] = user.isBlocking
                }
                state.followers = val
                return .none
            case .setTabSelection(let val):
                state.tabSelection = val
                return .none
            case .setFollowingMap(let val):
                state.followingMap[val.0] = val.1
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
            case .presentUserDetailView(let user):
                state.destination = .userDetail(UserDetailReducer.State(userId: user.id))
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

extension FollowListReducer.Destination.State: Equatable {}
