import ComposableArchitecture
import Foundation

@Reducer
struct PologDetailReducer {
    @Dependency(\.dismiss) var dismiss
    @Dependency(\.gqlClient) var gqlClient
    @Dependency(\.imagePrefetcher) var imagePrefetcher

    @Reducer
    enum Destination {
        case userDetail(UserDetailReducer)
        case commentList(PologCommentListReducer)
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
        let pologId: String
        var polog: Polog?
        var pologRouteState: [String: PologRouteState] = [:]
        var globalSelection = 0

        var isOwner: Bool {
            return polog?.user.id == loginUser?.me.user.id
        }

        var routeIndexList: [PologRouteIndex<PologRoute>] {
            guard let polog = polog else {
                return []
            }
            return PologRouteIndex.from(routes: polog.routes.map { $0.fragments.pologRouteFragment }.filter { $0.isIncludeIndex })
        }

        var lastRouteIndex: PologRoute? {
            return polog?.routes.map { $0.fragments.pologRouteFragment }.filter { $0.isIncludeIndex }.last
        }

        var currentRoute: PologRoute? {
            guard let polog = polog else {
                return nil
            }
            guard let selection = routeSelection else {
                return nil
            }
            guard selection >= 0 && selection < polog.routes.count else {
                return nil
            }
            return polog.routes.map { $0.fragments.pologRouteFragment }[selection]
        }

        var routeSelection: Int? {
            guard let polog = polog else {
                return nil
            }
            if polog.forewordHtml != nil && polog.afterwordHtml != nil {
                if globalSelection == 0 || globalSelection == 1 || globalSelection == polog.routes.count + routeSelectionOffset {
                    return nil
                }
            } else if polog.forewordHtml != nil {
                if globalSelection == 0 || globalSelection == 1 {
                    return nil
                }
            } else if polog.afterwordHtml != nil {
                if globalSelection == polog.routes.count + routeSelectionOffset {
                    return nil
                }
            }

            return globalSelection - routeSelectionOffset
        }

        var routeSelectionOffset: Int {
            return polog?.forewordHtml != nil ? 2 : 1
        }

        mutating func playVideoOnlySelected() {
            guard let polog = polog else {
                return
            }

            stopAllVideo()
            guard let selection = routeSelection else {
                return
            }
            guard selection >= 0 && selection < polog.routes.count else {
                return
            }
            let route = polog.routes[selection]

            pologRouteState[route.id]?.isVideoPlaying = true
        }

        mutating func stopAllVideo() {
            for elem in pologRouteState {
                pologRouteState[elem.key]?.isVideoPlaying = false
            }
        }

        // presentation
        var isPresentedIndexView = false
        var isPresentedDeleteAlert = false
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
        case movePologRoute(PologRoute)
        case toggleLike
        case toggleClip
        case delete

        // setter
        case setGlobalSelection(Int)
        case setPolog(Polog)
        case setPologRouteState(Polog)
        case setTruncated((PologRoute, Bool))
        case setVideoIsPlaying((PologRoute, Bool))

        // presentation
        case isPresentedIndexView(Bool)
        case isPresentedDeleteAlert(Bool)
        case isPresentedTabViewer(Bool)
        case presentUserDetailView(String)
        case presentCommentListView
        case presentPologRegistrationFlowView

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

                let pologId = state.pologId

                return .run { send in
                    do {
                        let polog = try (await gqlClient.query(PologAPI.GetPologQuery(pologId: pologId))).polog.fragments.pologFragment
                        await send(.setPolog(polog))
                        await send(.setPologRouteState(polog))
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
            case .dismiss:
                return .run { _ in
                    await dismiss()
                }
            case .movePologRoute(let route):
                guard let polog = state.polog else {
                    return .none
                }
                guard let index = polog.routes.firstIndex(where: { $0.id == route.id }) else {
                    return .none
                }
                state.globalSelection = index + state.routeSelectionOffset
                state.playVideoOnlySelected()
                return .none
            case .toggleLike:
                guard let polog = state.polog else {
                    return .none
                }
                guard !state.isOwner else {
                    return .none
                }

                state.isPresentedHUD = true

                if polog.isLiked {
                    return .run { send in
                        do {
                            let updatePolog = try (await gqlClient.mutation(PologAPI.UnLikePologMutation(id: polog.id))).pologUnLike.fragments.pologFragment
                            await send(.setPolog(updatePolog))
                        } catch {
                            await send(.setAlert(AlertEntity.from(error: error)))
                        }

                        await send(.isPresentedHUD(false))
                    }
                } else {
                    return .run { send in
                        do {
                            let updatePolog = try (await gqlClient.mutation(PologAPI.LikePologMutation(id: polog.id))).pologLike.fragments.pologFragment
                            await send(.setPolog(updatePolog))
                        } catch {
                            await send(.setAlert(AlertEntity.from(error: error)))
                        }

                        await send(.isPresentedHUD(false))
                    }
                }
            case .toggleClip:
                guard let polog = state.polog else {
                    return .none
                }
                guard !state.isOwner else {
                    return .none
                }

                state.isPresentedHUD = true

                if polog.isClipped {
                    return .run { send in
                        do {
                            let updatePolog = try (await gqlClient.mutation(PologAPI.UnClipPologMutation(id: polog.id))).pologUnClip.fragments.pologFragment
                            await send(.setPolog(updatePolog))
                        } catch {
                            await send(.setAlert(AlertEntity.from(error: error)))
                        }

                        await send(.isPresentedHUD(false))
                    }
                } else {
                    return .run { send in
                        do {
                            let updatePolog = try (await gqlClient.mutation(PologAPI.ClipPologMutation(id: polog.id))).pologClip.fragments.pologFragment
                            await send(.setPolog(updatePolog))
                        } catch {
                            await send(.setAlert(AlertEntity.from(error: error)))
                        }

                        await send(.isPresentedHUD(false))
                    }
                }
            case .delete:
                guard let polog = state.polog else {
                    return .none
                }
                state.isPresentedHUD = true

                return .run { send in
                    do {
                        let _ = try await gqlClient.mutation(PologAPI.DeletePologMutation(id: polog.id))
                        await dismiss()
                    } catch {
                        await send(.setAlert(AlertEntity.from(error: error)))
                    }

                    await send(.isPresentedHUD(false))
                }
            // ----------------------------------------------------------------
            // setter
            // ----------------------------------------------------------------
            case .setGlobalSelection(let val):
                state.globalSelection = val
                state.playVideoOnlySelected()
                return .none
            case .setPolog(let val):
                state.polog = val
                return .none
            case .setPologRouteState(let val):
                for route in val.routes {
                    state.pologRouteState[route.id] = PologRouteState(isTruncated: true, isVideoPlaying: false)
                }
                return .none
            case .setTruncated(let val):
                state.pologRouteState[val.0.id]?.isTruncated = val.1
                return .none
            case .setVideoIsPlaying(let val):
                state.pologRouteState[val.0.id]?.isVideoPlaying = val.1
                return .none
            // ----------------------------------------------------------------
            // presentation
            // ----------------------------------------------------------------
            case .isPresentedIndexView(let val):
                if val {
                    state.stopAllVideo()
                } else {
                    state.playVideoOnlySelected()
                }
                state.isPresentedIndexView = val
                return .none
            case .isPresentedDeleteAlert(let val):
                state.isPresentedDeleteAlert = val
                return .none
            case .isPresentedTabViewer(let val):
                state.isPresentedTabViewer = val
                return .none
            case .presentUserDetailView(let id):
                state.destination = .userDetail(UserDetailReducer.State(userId: id))
                return .none
            case .presentCommentListView:
                state.destination = .commentList(PologCommentListReducer.State(pologId: state.pologId))
                return .none
            case .presentPologRegistrationFlowView:
                guard let polog = state.polog else {
                    return .none
                }
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

    struct PologRouteState: Equatable {
        var isTruncated: Bool
        var isVideoPlaying: Bool
    }
}

extension PologDetailReducer.Destination.State: Equatable {}
