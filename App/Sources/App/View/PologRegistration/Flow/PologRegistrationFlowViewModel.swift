import ComposableArchitecture
import Foundation

@Reducer
struct PologRegistrationFlowReducer {
    @Dependency(\.dismiss) var dismiss
    @Dependency(\.swiftDataClient) var swiftDataClient

    @Reducer
    enum Destination {}

    @ObservableState
    struct State: Equatable {
        // common
        var isInitialized = false
        var alert: AlertEntity?
        var isPresentedHUD = false
        var isPresentedAlert = false

        // embed
        var embededEntrypoint: PologRouteRegistrationReducer.State?

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
        case register(InputPolog)
        case draft(InputPolog)

        // embed
        case embededEntrypoint(PologRouteRegistrationReducer.Action)

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
            case .register(let input):
                let draftedPolog = SD_DraftedPolog(polog: input)
                let stagingPolog = SD_StagingPolog(polog: input)
                return .run { send in
                    do {
                        try swiftDataClient.save(item: stagingPolog)
                        try swiftDataClient.delete(item: draftedPolog)
                        await dismiss()
                    } catch {
                        await send(.setAlert(AlertEntity.from(error: error)))
                    }
                }
            case .draft(let input):
                let draftedPolog = SD_DraftedPolog(polog: input)
                return .run { send in
                    do {
                        try swiftDataClient.save(item: draftedPolog)
                        await dismiss()
                    } catch {
                        await send(.setAlert(AlertEntity.from(error: error)))
                    }
                }
            // ----------------------------------------------------------------
            // embed
            // ----------------------------------------------------------------
            case .embededEntrypoint(let action):
                switch action {
                case .draft(let input):
                    return Effect.send(.draft(input))
                case .destination(let action):
                    guard let action = action.presented else {
                        return .none
                    }
                    switch action {
                    case .indexRegistration(let action):
                        switch action {
                        case .destination(let action):
                            guard let action = action.presented else {
                                return .none
                            }

                            switch action {
                            case .pologRegistration(let action):
                                switch action {
                                case .register(let input):
                                    return Effect.send(.register(input))
                                case .draft(let input):
                                    return Effect.send(.draft(input))
                                case .cancel:
                                    return Effect.send(.dismiss)
                                default:
                                    return .none
                                }
                            }
                        default:
                            return .none
                        }
                    default:
                        return .none
                    }
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
                default:
                    return .none
                }
            }
        }
        .ifLet(\.embededEntrypoint, action: \.embededEntrypoint) {
            PologRouteRegistrationReducer()
        }
        .ifLet(\.$destination, action: \.destination)
    }
}

extension PologRegistrationFlowReducer.Destination.State: Equatable {}
