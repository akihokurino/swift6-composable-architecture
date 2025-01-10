import ComposableArchitecture
import Foundation

@Reducer
struct SettingReducer {
    @Dependency(\.dismiss) var dismiss
    @Dependency(\.authClient) var authClient

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
        case logout

        // setter

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
            case .dismiss:
                return .run { _ in
                    await dismiss()
                }
            case .logout:
                let alert = AlertEntity(title: "サインアウトしてもよろしいですか？", message: "トップ画面に戻ります", type: .unAuthorize)
                return Effect.send(.setAlert(alert))
            // ----------------------------------------------------------------
            // setter
            // ----------------------------------------------------------------
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

extension WalkThroughReducer.Destination.State: Equatable {}
