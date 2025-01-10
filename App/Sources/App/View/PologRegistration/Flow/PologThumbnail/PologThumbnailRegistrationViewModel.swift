import ComposableArchitecture
import Foundation

@Reducer
struct PologThumbnailRegistrationReducer {
    @Dependency(\.dismiss) var dismiss

    @Reducer
    enum Destination {
        case assetSelect(AssetSelectReducer)
    }

    @ObservableState
    struct State: Equatable {
        // common
        var isInitialized = false
        var alert: AlertEntity?
        var isPresentedHUD = false
        var isPresentedAlert = false

        // data
        var thumbnail: Asset?
        var topLabel: String = ""
        var middleLabel: String = ""
        var bottomLabel: String = ""

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
        case finish((Asset, InputPologLabel))

        // setter
        case setThumbnail(Asset)
        case setTopLabel(String)
        case setMiddleLabel(String)
        case setBottomLabel(String)

        // presentation
        case presentAssetSelectView

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
                guard let thumbnail = state.thumbnail else {
                    return .none
                }

                return Effect.send(.finish((
                    thumbnail,
                    InputPologLabel(
                        label1: String(state.topLabel.prefix(8)),
                        label2: String(state.middleLabel.prefix(16)),
                        label3: String(state.bottomLabel.prefix(8))
                    )
                )))
            case .finish:
                return .run { _ in
                    await dismiss()
                }
            // ----------------------------------------------------------------
            // setter
            // ----------------------------------------------------------------
            case .setThumbnail(let val):
                state.thumbnail = val
                return .none
            case .setTopLabel(let val):
                state.topLabel = val
                return .none
            case .setMiddleLabel(let val):
                state.middleLabel = val
                return .none
            case .setBottomLabel(let val):
                state.bottomLabel = val
                return .none
            // ----------------------------------------------------------------
            // presentation
            // ----------------------------------------------------------------
            case .presentAssetSelectView:
                state.destination = .assetSelect(AssetSelectReducer.State())
                return .none
            // ----------------------------------------------------------------
            // destination
            // ----------------------------------------------------------------
            case .destination(let action):
                guard let action = action.presented else {
                    return .none
                }
                switch action {
                case .assetSelect(let action):
                    switch action {
                    case .finish(let selected):
                        guard let asset = selected.first else {
                            return .none
                        }
                        return Effect.send(.setThumbnail(asset))
                    default:
                        return .none
                    }
                }
            }
        }
        .ifLet(\.$destination, action: \.destination)
    }
}

extension PologThumbnailRegistrationReducer.Destination.State: Equatable {}
