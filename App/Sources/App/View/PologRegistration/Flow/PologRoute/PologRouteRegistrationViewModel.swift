import ComposableArchitecture
import Foundation

@Reducer
struct PologRouteRegistrationReducer {
    @Dependency(\.dismiss) var dismiss
    @Dependency(\.photosClient) var photosClient
    @Dependency(\.storageClient) var storageClient
    @Dependency(\.gqlClient) var gqlClient
    @Dependency(\.imagePrefetcher) var imagePrefetcher

    @Reducer
    enum Destination {
        case assetSelect(AssetSelectReducer)
        case videoTrimmer(PologRouteVideoTrimmerReducer)
        case indexRegistration(PologRouteIndexRegistrationReducer)
    }

    @ObservableState
    struct State: Equatable {
        // common
        var isInitialized = false
        var alert: AlertEntity?
        var isPresentedHUD = false
        var isPresentedAlert = false

        // data
        var globalSelection = 0
        var inputPolog: InputPolog
        var inputForewordHtml: String = ""
        var inputAfterwordHtml: String = ""
        var actionSheetType: ActionSheetType = .deleteAsset

        var routeIndexList: [PologRouteIndex<InputPologRoute>] {
            return PologRouteIndex.from(routes: inputPolog.routes.filter { $0.isIncludeIndex })
        }

        var lastRouteIndex: InputPologRoute? {
            return inputPolog.routes.filter { $0.isIncludeIndex }.last
        }

        var currentRoute: InputPologRoute? {
            guard let selection = routeSelection else {
                return nil
            }
            guard selection >= 0 && selection < inputPolog.routes.count else {
                return nil
            }
            return inputPolog.routes[selection]
        }

        var routeSelection: Int? {
            if isHtmlEditorView {
                return nil
            }

            return globalSelection - routeSelectionOffset
        }

        var isHtmlEditorView: Bool {
            if htmlType != nil {
                return true
            }

            return false
        }

        var htmlType: HtmlType? {
            if isPresentedForewordHtmlInputView && isPresentedAfterwordHtmlInputView {
                if globalSelection == 0 {
                    return .foreword
                }
                if globalSelection == inputPolog.routes.count + 1 {
                    return .afterword
                }
            } else if isPresentedForewordHtmlInputView {
                if globalSelection == 0 {
                    return .foreword
                }
            } else if isPresentedAfterwordHtmlInputView {
                if globalSelection == inputPolog.routes.count {
                    return .afterword
                }
            }

            return nil
        }

        var routeSelectionOffset: Int {
            return isPresentedForewordHtmlInputView ? 1 : 0
        }

        mutating func playVideoOnlySelected() {
            stopAllVideo()

            guard let selection = routeSelection else {
                return
            }
            guard selection >= 0 && selection < inputPolog.routes.count else {
                return
            }
            guard inputPolog.routes[selection].asset.isVideo else {
                return
            }

            inputPolog.routes[selection].isVideoPlaying = true
        }

        mutating func stopAllVideo() {
            for i in 0 ..< inputPolog.routes.count {
                inputPolog.routes[i].isVideoPlaying = false
            }
        }

        mutating func syncHtml() {
            if inputForewordHtml.isNotEmpty {
                inputPolog.forewordHtml = inputForewordHtml
            }
            if inputAfterwordHtml.isNotEmpty {
                inputPolog.afterwordHtml = inputAfterwordHtml
            }
        }

        // presentation
        var isPresentedInputDescriptionView = false
        var isPresentedInputSpotView = false
        var isPresentedInputVideoView = false
        var isPresentedIndexView = false
        var isPresentedForewordHtmlInputView = false
        var isPresentedAfterwordHtmlInputView = false
        var isPresentedActionSheet = false
        var isPresentedTabViewer = false

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
        case indexPologRoute
        case deletePologRoute
        case addPologRoute([InputPologRoute])
        case movePologRoute(InputPologRoute)
        case addForewordHtml
        case addAfterwordHtml
        case draft(InputPolog)

        // setter
        case setGlobalSelection(Int)
        case setPologRoutes([InputPologRoute])
        case setForewordHtml(String)
        case setAfterwordHtml(String)
        case setPologRouteDescription(String)
        case setPologRouteAssetDate(Date)
        case setPologRouteVideo(InputPologVideoSettings)
        case setPologRouteVideoIsPlaying(Bool)

        // presentation
        case presentAssetSelectView
        case presentVideoTrimmerView(InputPologRoute)
        case presentIndexRegistrationView
        case presentDeleteAssetActionSheet
        case presentAddForewordHtmlActionSheet
        case presentAddAfterwordHtmlActionSheet
        case presentCloseMenuActionSheet
        case isPresentedInputDescriptionView(Bool)
        case isPresentedInputSpotView(Bool)
        case isPresentedIndexView(Bool)
        case isPresentedActionSheet(Bool)
        case isPresentedTabViewer(Bool)

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
            case .indexPologRoute:
                guard let selection = state.routeSelection else {
                    return .none
                }
                let input = state.inputPolog.routes[selection]
                state.inputPolog.routes[selection].isIncludeIndex = !input.isIncludeIndex
                state.inputPolog.idForViewRendering = UUID()
                return .none
            case .deletePologRoute:
                guard let input = state.currentRoute else {
                    return .none
                }
                let next = state.inputPolog.routes.filter { $0.asset.id != input.asset.id }
                state.inputPolog.routes = next
                var newGlobalSelection = state.globalSelection
                if newGlobalSelection != 0 {
                    newGlobalSelection -= 1
                }
                return Effect.send(.setGlobalSelection(newGlobalSelection))
            case .addPologRoute(let inputs):
                imagePrefetcher.startPrefetching(with: inputs
                    .filter {
                        switch $0.asset {
                        case .localAsset:
                            return false
                        case .remoteAsset(let asset):
                            return !asset.isVideo
                        }
                    }
                    .map {
                        switch $0.asset {
                        case .localAsset:
                            return nil
                        case .remoteAsset(let asset):
                            return asset.url
                        }
                    }
                    .filter { $0 != nil }
                    .map { $0! }
                )

                var next = state.inputPolog.routes
                next.append(contentsOf: inputs)
                let sorted = next.sorted { $0.asset.date < $1.asset.date }
                state.inputPolog.routes = sorted
                state.inputPolog.idForViewRendering = UUID()
                return Effect.send(.setGlobalSelection(1))
            case .movePologRoute(let input):
                guard let index = state.inputPolog.routes.firstIndex(where: { $0.id == input.id }) else {
                    return .none
                }
                return Effect.send(.setGlobalSelection(index + state.routeSelectionOffset))
            case .addForewordHtml:
                state.isPresentedForewordHtmlInputView = true
                return Effect.send(.setGlobalSelection(0))
            case .addAfterwordHtml:
                state.isPresentedAfterwordHtmlInputView = true
                return Effect.send(.setGlobalSelection(state.inputPolog.routes.count + state.routeSelectionOffset))
            case .draft:
                // delegate
                return .none
            // ----------------------------------------------------------------
            // setter
            // ----------------------------------------------------------------
            case .setGlobalSelection(let selection):
                if state.globalSelection != selection {
                    state.syncHtml()
                }

                state.globalSelection = selection
                state.playVideoOnlySelected()
                return .none
            case .setPologRoutes(let val):
                state.inputPolog.routes = val
                return .none
            case .setForewordHtml(let val):
                state.inputForewordHtml = val
                return .none
            case .setAfterwordHtml(let val):
                state.inputAfterwordHtml = val
                return .none
            case .setPologRouteDescription(let val):
                guard let selection = state.routeSelection else {
                    return .none
                }

                state.inputPolog.routes[selection].description = val
                return .none
            case .setPologRouteAssetDate(let val):
                guard let selection = state.routeSelection else {
                    return .none
                }
                state.inputPolog.routes[selection].updatedAssetDate = val

                let sorted = state.inputPolog.routes.sorted { $0.assetDate < $1.assetDate }
                var newGlobalSelection = state.globalSelection
                if let newSelection = sorted.firstIndex(where: { $0.id == state.inputPolog.routes[selection].id }) {
                    newGlobalSelection = newSelection + state.routeSelectionOffset
                }
                state.inputPolog.routes = sorted

                return Effect.send(.setGlobalSelection(newGlobalSelection))
            case .setPologRouteVideo(let val):
                guard let selection = state.routeSelection else {
                    return .none
                }
                state.inputPolog.routes[selection].isVideoMuted = val.isMuted
                state.inputPolog.routes[selection].videoStartSeconds = val.startSeconds
                state.inputPolog.routes[selection].videoEndSeconds = val.endSeconds
                return .none
            case .setPologRouteVideoIsPlaying(let val):
                guard let selection = state.routeSelection else {
                    return .none
                }
                state.inputPolog.routes[selection].isVideoPlaying = val
                return .none
            // ----------------------------------------------------------------
            // presentation
            // ----------------------------------------------------------------
            case .presentAssetSelectView:
                state.syncHtml()
                state.stopAllVideo()
                state.destination = .assetSelect(AssetSelectReducer.State())
                return .none
            case .presentVideoTrimmerView(let input):
                guard input.asset.isVideo else {
                    return .none
                }
                state.syncHtml()
                state.stopAllVideo()
                state.destination = .videoTrimmer(PologRouteVideoTrimmerReducer.State(
                    isMuted: input.isVideoMuted,
                    asset: input.asset,
                    startTime: input.videoStartSeconds,
                    endTime: input.videoEndSeconds
                ))
                return .none
            case .presentIndexRegistrationView:
                state.syncHtml()
                state.stopAllVideo()
                state.destination = .indexRegistration(PologRouteIndexRegistrationReducer.State(
                    inputPolog: state.inputPolog
                ))
                return .none
            case .presentDeleteAssetActionSheet:
                state.actionSheetType = .deleteAsset
                state.isPresentedActionSheet = true
                return .none
            case .presentAddForewordHtmlActionSheet:
                state.actionSheetType = .addForewordHtml
                state.isPresentedActionSheet = true
                return .none
            case .presentAddAfterwordHtmlActionSheet:
                state.actionSheetType = .addAfterwordHtml
                state.isPresentedActionSheet = true
                return .none
            case .presentCloseMenuActionSheet:
                if state.inputPolog.isEdit {
                    state.actionSheetType = .closeMenuForEdit
                } else if state.inputPolog.isDraft {
                    state.actionSheetType = .closeMenuForDraft
                } else {
                    state.actionSheetType = .closeMenuForCreate
                }
                state.isPresentedActionSheet = true
                return .none
            case .isPresentedInputDescriptionView(let val):
                state.isPresentedInputDescriptionView = val
                if val {
                    state.stopAllVideo()
                } else {
                    state.playVideoOnlySelected()
                }
                return .none
            case .isPresentedInputSpotView(let val):
                state.isPresentedInputSpotView = val
                if val {
                    state.stopAllVideo()
                } else {
                    state.playVideoOnlySelected()
                }
                return .none
            case .isPresentedIndexView(let val):
                if val {
                    state.stopAllVideo()
                } else {
                    state.playVideoOnlySelected()
                }
                state.isPresentedIndexView = val
                return .none
            case .isPresentedActionSheet(let val):
                state.isPresentedActionSheet = val
                return .none
            case .isPresentedTabViewer(let val):
                state.isPresentedTabViewer = val
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
                    case .dismiss:
                        state.playVideoOnlySelected()
                        return .none
                    case .finish(let selected):
                        return Effect.send(.addPologRoute(selected.map { InputPologRoute(asset: $0) }))
                    default:
                        return .none
                    }
                case .videoTrimmer(let action):
                    switch action {
                    case .dismiss:
                        state.playVideoOnlySelected()
                        return .none
                    case .finish(let data):
                        return Effect.send(.setPologRouteVideo(data))
                    default:
                        return .none
                    }
                case .indexRegistration(let action):
                    switch action {
                    case .dismiss:
                        state.playVideoOnlySelected()
                        return .none
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

    enum ActionSheetType {
        case deleteAsset
        case addForewordHtml
        case addAfterwordHtml
        case closeMenuForCreate
        case closeMenuForDraft
        case closeMenuForEdit
    }

    enum HtmlType {
        case foreword
        case afterword
    }
}

extension PologRouteRegistrationReducer.Destination.State: Equatable {}

struct InputPologVideoSettings: Equatable {
    let startSeconds: Double
    let endSeconds: Double
    let isMuted: Bool
}
