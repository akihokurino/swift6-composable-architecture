import ComposableArchitecture
import Foundation

@Reducer
struct PologRouteIndexRegistrationReducer {
    @Dependency(\.dismiss) var dismiss

    @Reducer
    enum Destination {
        case pologRegistration(PologRegistrationReducer)
    }

    @ObservableState
    struct State: Equatable {
        // common
        var isInitialized = false
        var alert: AlertEntity?
        var isPresentedHUD = false
        var isPresentedAlert = false

        // data
        var inputPolog: InputPolog

        var routeIndexList: [PologRouteIndex<InputPologRoute>] {
            return PologRouteIndex.from(routes: inputPolog.routes.filter { $0.isIncludeIndex })
        }

        var lastRouteIndex: InputPologRoute? {
            return inputPolog.routes.filter { $0.isIncludeIndex }.last
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
        case syncInput(InputPolog)

        // setter
        case setPriceLabel((InputPologRoute, String))
        case setReview((InputPologRoute, Int))
        case setTransportation((InputPologRoute, Transportation))

        // presentation
        case presentPologRegistrationView

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
                let input = state.inputPolog
                return .run { send in
                    await send(.syncInput(input))
                    await dismiss()
                }
            case .syncInput:
                // delegate
                return .none
            // ----------------------------------------------------------------
            // setter
            // ----------------------------------------------------------------
            case .setPriceLabel(let val):
                guard let selectIndex = state.inputPolog.routes.firstIndex(where: { $0.id == val.0.id }) else {
                    return .none
                }

                if state.inputPolog.routes[selectIndex].priceLabel == val.1 {
                    state.inputPolog.routes[selectIndex].priceLabel = ""
                } else {
                    state.inputPolog.routes[selectIndex].priceLabel = val.1
                }

                return .none
            case .setReview(let val):
                guard let selectIndex = state.inputPolog.routes.firstIndex(where: { $0.id == val.0.id }) else {
                    return .none
                }

                state.inputPolog.routes[selectIndex].review = val.1

                return .none
            case .setTransportation(let val):
                guard let selectIndex = state.inputPolog.routes.firstIndex(where: { $0.id == val.0.id }) else {
                    return .none
                }

                if state.inputPolog.routes[selectIndex].transportations.contains(val.1) {
                    state.inputPolog.routes[selectIndex].transportations.remove(val.1)
                } else {
                    state.inputPolog.routes[selectIndex].transportations.insert(val.1)
                }

                return .none
            // ----------------------------------------------------------------
            // presentation
            // ----------------------------------------------------------------
            case .presentPologRegistrationView:
                state.destination = .pologRegistration(PologRegistrationReducer.State(inputPolog: state.inputPolog))
                return .none
            // ----------------------------------------------------------------
            // destination
            // ----------------------------------------------------------------
            case .destination(let action):
                guard let action = action.presented else {
                    return .none
                }
                switch action {
                case .pologRegistration(let action):
                    switch action {
                    case .syncInput(let input):
                        state.inputPolog = input
                        return .none
                    default:
                        return .none
                    }
                }
            }
        }
        .ifLet(\.$destination, action: \.destination)
    }
}

extension PologRouteIndexRegistrationReducer.Destination.State: Equatable {}
