import ComposableArchitecture
import Foundation

@Reducer
struct PologRouteVideoTrimmerReducer {
    @Dependency(\.dismiss) var dismiss

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
        var isMuted = false
        var asset: Asset
        var startTime: Double = 0.0
        var endTime: Double = 0.0

        var duration: String {
            return "\(Int(round(endTime - startTime)))秒"
        }

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
        case finish(InputPologVideoSettings)

        // setter
        case setStartTime(Double)
        case setEndTime(Double)
        case setIsMuted(Bool)

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
            case .confirm:
                return Effect.send(.finish(
                    InputPologVideoSettings(
                        startSeconds: state.startTime,
                        endSeconds: state.endTime,
                        isMuted: state.isMuted
                    )
                ))
            case .finish:
                return .run { _ in
                    await dismiss()
                }
            // ----------------------------------------------------------------
            // setter
            // ----------------------------------------------------------------
            case .setStartTime(let val):
                state.startTime = val
                return .none
            case .setEndTime(let val):
                state.endTime = val
                return .none
            case .setIsMuted(let val):
                state.isMuted = val
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

extension PologRouteVideoTrimmerReducer.Destination.State: Equatable {}
