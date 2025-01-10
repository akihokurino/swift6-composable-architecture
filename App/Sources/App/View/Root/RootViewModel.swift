import ComposableArchitecture
import Foundation

@Reducer
struct RootReducer {
    @Dependency(\.gqlClient) var gqlClient
    @Dependency(\.authClient) var authClient
    @Dependency(\.pologAsyncRegistrator) var pologAsyncRegistrator

    @Reducer
    enum Destination {
        case pologRegistrationPrepare(PologRegistrationPrepareReducer)
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
        var viewType: ViewType = .loading
        var tabSelection: Tab = .home
        var lastTabSelection: Tab = .home

        mutating func toApp() {
            self.viewType = .app
            self.embededWalkThrough = nil
            self.embededLogin = nil
            self.embededHome = HomeReducer.State()
            self.embededSearch = SearchReducer.State()
            self.embededGroup = GroupReducer.State()
            self.embededMyPage = MyPageReducer.State()
        }

        mutating func toWalkThrough() {
            self.viewType = .walkThrough
            self.embededWalkThrough = WalkThroughReducer.State()
            self.embededLogin = nil
            self.embededHome = nil
            self.embededSearch = nil
            self.embededGroup = nil
            self.embededMyPage = nil
        }

        mutating func toLogin() {
            self.viewType = .login
            self.embededWalkThrough = nil
            self.embededLogin = LoginReducer.State()
            self.embededHome = nil
            self.embededSearch = nil
            self.embededGroup = nil
            self.embededMyPage = nil
        }

        // embed
        var embededWalkThrough: WalkThroughReducer.State?
        var embededLogin: LoginReducer.State?
        var embededHome: HomeReducer.State?
        var embededSearch: SearchReducer.State?
        var embededGroup: GroupReducer.State?
        var embededMyPage: MyPageReducer.State?

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
        case startApp
        case logout

        // setter
        case setTabSelection(Tab)
        case setMe(Me)

        // embed
        case embededWalkThrough(WalkThroughReducer.Action)
        case embededLogin(LoginReducer.Action)
        case embededHome(HomeReducer.Action)
        case embededSearch(SearchReducer.Action)
        case embededGroup(GroupReducer.Action)
        case embededMyPage(MyPageReducer.Action)

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

                if self.authClient.isLogin {
                    state.isPresentedHUD = true
                    return .run { send in
                        do {
                            let me = try (await gqlClient.query(PologAPI.GetMeQuery())).me.fragments.meFragment
                            await send(.setMe(me))
                            await send(.startApp)
                        } catch {
                            await send(.setAlert(AlertEntity.from(error: error)))
                        }

                        await send(.isPresentedHUD(false))
                    }
                } else {
                    state.toWalkThrough()
                    return .none
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
            case .startApp:
                state.toApp()
                return .run { _ in
                    await self.pologAsyncRegistrator.start()
                }
            case .logout:
                try! self.authClient.logout()
                state.toLogin()
                return .run { _ in
                    await self.pologAsyncRegistrator.stop()
                }
            // ----------------------------------------------------------------
            // setter
            // ----------------------------------------------------------------
            case .setTabSelection(let val):
                state.tabSelection = val

                switch val {
                case .home, .search, .group, .myPage:
                    state.lastTabSelection = val
                    return .none
                case .createPolog:
                    state.tabSelection = state.lastTabSelection
                    state.destination = .pologRegistrationPrepare(PologRegistrationPrepareReducer.State())
                    return .none
                }
            case .setMe(let val):
                state.loginUser = SharedUserInfo(me: val)
                return .none
            // ----------------------------------------------------------------
            // embed
            // ----------------------------------------------------------------
            case .embededWalkThrough(let action):
                switch action {
                case .finish:
                    state.toLogin()
                    return .none
                default:
                    return .none
                }
            case .embededLogin(let action):
                switch action {
                case .finish:
                    return Effect.send(.startApp)
                case .destination(let action):
                    guard let action = action.presented else {
                        return .none
                    }
                    switch action {
                    case .userRegistration(let action):
                        switch action {
                        case .finish:
                            return Effect.send(.startApp)
                        default:
                            return .none
                        }
                    }
                default:
                    return .none
                }
            case .embededHome(let action):
                switch action {
                default:
                    return .none
                }
            case .embededSearch(let action):
                switch action {
                default:
                    return .none
                }
            case .embededGroup(let action):
                switch action {
                default:
                    return .none
                }
            case .embededMyPage(let action):
                switch action {
                default:
                    return .none
                }
            // ----------------------------------------------------------------
            // destination
            // ----------------------------------------------------------------
            case .destination(let action):
                guard let action = action.presented else {
                    return .none
                }
                switch action {
                case .pologRegistrationPrepare(let action):
                    switch action {
                    case .startRegistration(let input):
                        let entrypoint = PologRouteRegistrationReducer.State(
                            globalSelection: (input.forewordHtml?.isNotEmpty ?? false) ? 1 : 0,
                            inputPolog: input,
                            isPresentedForewordHtmlInputView: (input.forewordHtml?.isNotEmpty ?? false),
                            isPresentedAfterwordHtmlInputView: (input.afterwordHtml?.isNotEmpty ?? false)
                        )
                        state.destination = .pologRegistrationFlow(PologRegistrationFlowReducer.State(
                            embededEntrypoint: entrypoint
                        ))
                        return .none
                    default:
                        return .none
                    }
                case .pologRegistrationFlow(let action):
                    switch action {
                    case .register:
                        return Effect.send(.setTabSelection(.myPage))
                    default:
                        return .none
                    }
                }
            }
        }
        .ifLet(\.embededWalkThrough, action: \.embededWalkThrough) {
            WalkThroughReducer()
        }
        .ifLet(\.embededLogin, action: \.embededLogin) {
            LoginReducer()
        }
        .ifLet(\.embededHome, action: \.embededHome) {
            HomeReducer()
        }
        .ifLet(\.embededSearch, action: \.embededSearch) {
            SearchReducer()
        }
        .ifLet(\.embededGroup, action: \.embededGroup) {
            GroupReducer()
        }
        .ifLet(\.embededMyPage, action: \.embededMyPage) {
            MyPageReducer()
        }
        .ifLet(\.$destination, action: \.destination)
    }

    enum ViewType {
        case loading
        case walkThrough
        case login
        case app
    }

    enum Tab: Equatable {
        case home
        case search
        case createPolog
        case group
        case myPage
    }
}

extension RootReducer.Destination.State: Equatable {}
