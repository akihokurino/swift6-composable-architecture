import ComposableArchitecture
import Foundation

@Reducer
struct SearchReducer {
    @Dependency(\.gqlClient) var gqlClient
    @Dependency(\.swiftDataClient) var swiftDataClient

    @Reducer
    enum Destination {
        case userDetail(UserDetailReducer)
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
        var users: WithCursor<UserOverview>?
        var recommendedUsers: WithCursor<UserOverview>?
        var pologs: WithCursor<PologOverview>?
        var searchHistory: SD_SearchHistory?
        var tabSelection = 0
        var query = ""
        var isEditingSearchBar = false
        var isSearching = false
        var followingMap: [String: Bool] = [:]
        var blockingMap: [String: Bool] = [:]

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
        case search
        case searchPologs(Bool)
        case searchUsers(Bool)
        case fetchRecommendedUsers(Bool)
        case selectSearchHistory(String)
        case deleteSearchHistory(String)
        case toggleFollow(UserOverview)

        // setter
        case setPologs(WithCursor<PologOverview>)
        case setUsers(WithCursor<UserOverview>)
        case setRecommendedUsers(WithCursor<UserOverview>)
        case setSearchHistory(SD_SearchHistory)
        case setTabSelection(Int)
        case setQuery(String)
        case setIsEditingSearchBar(Bool)
        case setIsSearching(Bool)
        case setFollowingMap((String, Bool))

        // presentation
        case isPresentedNextLoading(Bool)
        case isPresentedPullToRefresh(Bool)
        case presentUserDetailView(UserOverview)
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

                return .run { send in
                    do {
                        let history: SD_SearchHistory? = try swiftDataClient.fetchOne()
                        await send(.setSearchHistory(history ?? SD_SearchHistory.empty()))
                    } catch {
                        await send(.setAlert(AlertEntity.from(error: error)))
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
            case .search:
                guard state.query.isNotEmpty else {
                    return .none
                }
                guard let history = state.searchHistory else {
                    return .none
                }

                state.isPresentedHUD = true
                state.isSearching = true

                let newHistory = history.add(query: state.query)
                return .run { send in
                    do {
                        try swiftDataClient.save(item: newHistory)
                        await send(.setSearchHistory(newHistory))
                    } catch {
                        await send(.setAlert(AlertEntity.from(error: error)))
                    }

                    await send(.searchPologs(true))
                    await send(.searchUsers(true))
                }
            case .searchPologs(let isRefresh):
                guard state.query.isNotEmpty else {
                    return .none
                }
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
                let q = state.query

                return .run { send in
                    do {
                        let itemsWithCursor = try (await gqlClient.query(PologAPI.SearchPologsQuery(cursor: gqlOption(cursor), limit: limit, q: q))).pologs
                        await send(.setPologs(pager.next(itemsWithCursor.nodes.map { $0.fragments.pologOverviewFragment }, cursor: itemsWithCursor.pageInfo.endCursor, hasNext: itemsWithCursor.pageInfo.hasNextPage)))
                    } catch {
                        await send(.setAlert(AlertEntity.from(error: error)))
                    }

                    await send(.isPresentedHUD(false))
                    await send(.isPresentedPullToRefresh(false))
                    await send(.isPresentedNextLoading(false))
                }
            case .searchUsers(let isRefresh):
                guard state.query.isNotEmpty else {
                    return .none
                }
                var _pager = state.users
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
                let q = state.query

                return .run { send in
                    do {
                        let itemsWithCursor = try (await gqlClient.query(PologAPI.SearchUsersQuery(cursor: gqlOption(cursor), limit: limit, username: q))).users
                        await send(.setUsers(pager.next(itemsWithCursor.nodes.map { $0.fragments.userOverviewFragment }, cursor: itemsWithCursor.pageInfo.endCursor, hasNext: itemsWithCursor.pageInfo.hasNextPage)))
                    } catch {
                        await send(.setAlert(AlertEntity.from(error: error)))
                    }

                    await send(.isPresentedHUD(false))
                    await send(.isPresentedPullToRefresh(false))
                    await send(.isPresentedNextLoading(false))
                }
            case .fetchRecommendedUsers(let isRefresh):
                var _pager = state.recommendedUsers
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
                let meId = state.loginUser?.me.user.id ?? ""

                return .run { send in
                    do {
                        let itemsWithCursor = try (await gqlClient.query(PologAPI.GetFolloweesQuery(userId: meId, cursor: gqlOption(cursor), limit: limit))).user.followees
                        await send(.setRecommendedUsers(pager.next(itemsWithCursor.nodes.map { $0.fragments.userOverviewFragment }, cursor: itemsWithCursor.pageInfo.endCursor, hasNext: itemsWithCursor.pageInfo.hasNextPage)))
                    } catch {
                        await send(.setAlert(AlertEntity.from(error: error)))
                    }

                    await send(.isPresentedHUD(false))
                    await send(.isPresentedPullToRefresh(false))
                    await send(.isPresentedNextLoading(false))
                }
            case .selectSearchHistory(let query):
                state.query = query
                return .run { send in
                    await send(.searchUsers(true))
                    await send(.searchPologs(true))
                }
            case .deleteSearchHistory(let query):
                guard let history = state.searchHistory else {
                    return .none
                }

                let newHistory = history.delete(query: query)
                return .run { send in
                    do {
                        try swiftDataClient.save(item: newHistory)
                        await send(.setSearchHistory(newHistory))
                    } catch {
                        await send(.setAlert(AlertEntity.from(error: error)))
                    }
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
            case .setPologs(let val):
                state.pologs = val
                return .none
            case .setUsers(let val):
                for user in val.items {
                    state.followingMap[user.id] = user.isFollowing
                    state.blockingMap[user.id] = user.isBlocking
                }
                state.users = val
                return .none
            case .setRecommendedUsers(let val):
                for user in val.items {
                    state.followingMap[user.id] = user.isFollowing
                    state.blockingMap[user.id] = user.isBlocking
                }
                state.recommendedUsers = val
                return .none
            case .setSearchHistory(let val):
                state.searchHistory = val
                return .none
            case .setTabSelection(let val):
                state.tabSelection = val
                return .none
            case .setQuery(let val):
                state.query = val
                return .none
            case .setIsEditingSearchBar(let val):
                state.isEditingSearchBar = val
                return .none
            case .setIsSearching(let val):
                state.isSearching = val
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

extension SearchReducer.Destination.State: Equatable {}
