import ComposableArchitecture
import Foundation

@Reducer
struct MyPageReducer {
    @Dependency(\.gqlClient) var gqlClient
    @Dependency(\.swiftDataClient) var swiftDataClient
    @Dependency(\.continuousClock) var clock

    @Reducer
    enum Destination {
        case followList(FollowListReducer)
        case userEdit(UserEditReducer)
        case setting(SettingReducer)
        case clippedPologList(ClippedPologListReducer)
        case pologDetail(PologDetailReducer)
        case pologRegistrationFlow(PologRegistrationFlowReducer)
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
        var pologListType: PologListType = .myPologs
        var pologSummary: PologSummary?
        var pologs: WithCursor<PologOverview>?
        var pologRegistrationProgress: Double?

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
        case fetchPologSummary
        case fetchPologs(Bool)
        case editPolog(PologOverview)
        case syncPologRegistrationProgress

        // setter
        case setPologListType(PologListType)
        case setPologSummary(PologSummary)
        case setPologs(WithCursor<PologOverview>)
        case setPologRegistrationProgress(Double?)

        // presentation
        case isPresentedNextLoading(Bool)
        case isPresentedPullToRefresh(Bool)
        case presentFollowListView(Int)
        case presentUserEditView
        case presentSettingView
        case presentClippedPologListView
        case presentPologDetailView(PologOverview)
        case presentPologRegistrationFlowView(Polog)

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
                    await send(.fetchPologSummary)
                    await send(.fetchPologs(true))
                    await send(.syncPologRegistrationProgress)
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
            case .fetchPologSummary:
                let meId = state.loginUser?.me.user.id ?? ""
                return .run { send in
                    do {
                        let summary = try (await gqlClient.query(PologAPI.GetPologSummaryQuery(userId: meId))).user.pologSummary.fragments.pologSummaryFragment
                        await send(.setPologSummary(summary))
                    } catch {
                        await send(.setAlert(AlertEntity.from(error: error)))
                    }
                }
            case .fetchPologs(let isRefresh):
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
                            let itemsWithCursor = try (await gqlClient.query(PologAPI.GetMyPologsQuery(
                                cursor: gqlOption(cursor),
                                limit: limit,
                                q: gqlOption(nil),
                                sortType: gqlEnum(PologAPI.PologSortType.createdAt),
                                filter: gqlOption(nil)))).me.pologs
                            await send(.setPologs(pager.next(itemsWithCursor.nodes.map { $0.fragments.pologOverviewFragment }, cursor: itemsWithCursor.pageInfo.endCursor, hasNext: itemsWithCursor.pageInfo.hasNextPage)))
                        case .accompaniedPolog:
                            let itemsWithCursor = try (await gqlClient.query(PologAPI.GetMyAccompaniedPologsQuery(
                                cursor: gqlOption(cursor),
                                limit: limit,
                                q: gqlOption(nil),
                                sortType: gqlEnum(PologAPI.PologSortType.createdAt),
                                filter: gqlOption(nil)))).me.accompaniedPologs
                            await send(.setPologs(pager.next(itemsWithCursor.nodes.map { $0.fragments.pologOverviewFragment }, cursor: itemsWithCursor.pageInfo.endCursor, hasNext: itemsWithCursor.pageInfo.hasNextPage)))
                        }
                    } catch {
                        await send(.setAlert(AlertEntity.from(error: error)))
                    }

                    await send(.isPresentedHUD(false))
                    await send(.isPresentedPullToRefresh(false))
                    await send(.isPresentedNextLoading(false))
                }
            case .editPolog(let pologOverview):
                state.isPresentedHUD = true
                return .run { send in
                    do {
                        let polog = try (await gqlClient.query(PologAPI.GetPologQuery(pologId: pologOverview.id))).polog.fragments.pologFragment
                        await send(.presentPologRegistrationFlowView(polog))
                    } catch {
                        await send(.setAlert(AlertEntity.from(error: error)))
                    }

                    await send(.isPresentedHUD(false))
                }
            case .syncPologRegistrationProgress:
                return .run { send in
                    Task {
                        while true {
                            do {
                                let stagings: [SD_StagingPolog] = try swiftDataClient.fetch()
                                var totalCount = 0
                                var finishedCount = 0
                                for staging in stagings {
                                    totalCount += staging.polog?.routes.count ?? 0
                                    totalCount += 1
                                    finishedCount += staging.uploadedRoutes.count
                                    if staging.finishedAt != nil {
                                        finishedCount += 1
                                    }
                                }

                                if totalCount > 0 {
                                    await send(.setPologRegistrationProgress(Double(finishedCount) / Double(totalCount)))
                                } else {
                                    await send(.setPologRegistrationProgress(nil))
                                }
                            } catch {
                                await send(.setAlert(AlertEntity.from(error: error)))
                            }
                            try! await Task.sleep(nanoseconds: 500_000_000)
                        }
                    }

                    for await _ in clock.timer(interval: .seconds(1)) {}
                }
            // ----------------------------------------------------------------
            // setter
            // ----------------------------------------------------------------
            case .setPologListType(let val):
                state.pologListType = val
                return .none
            case .setPologSummary(let val):
                state.pologSummary = val
                return .none
            case .setPologs(let val):
                state.pologs = val
                return .none
            case .setPologRegistrationProgress(let val):
                state.pologRegistrationProgress = val
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
                guard let loginUser = state.loginUser else {
                    return .none
                }
                state.destination = .followList(FollowListReducer.State(userId: loginUser.me.user.id, tabSelection: tabSelection))
                return .none
            case .presentUserEditView:
                state.destination = .userEdit(UserEditReducer.State())
                return .none
            case .presentSettingView:
                state.destination = .setting(SettingReducer.State())
                return .none
            case .presentClippedPologListView:
                state.destination = .clippedPologList(ClippedPologListReducer.State())
                return .none
            case .presentPologDetailView(let polog):
                state.destination = .pologDetail(PologDetailReducer.State(pologId: polog.id))
                return .none
            case .presentPologRegistrationFlowView(let polog):
                let entrypoint = PologRouteRegistrationReducer.State(inputPolog: InputPolog.from(polog: polog))
                state.destination = .pologRegistrationFlow(PologRegistrationFlowReducer.State(
                    embededEntrypoint: entrypoint
                ))
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

extension MyPageReducer.Destination.State: Equatable {}
