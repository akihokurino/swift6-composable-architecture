import ComposableArchitecture
import Foundation

@Reducer
struct PologCompanionRegistrationReducer {
    @Dependency(\.dismiss) var dismiss
    @Dependency(\.gqlClient) var gqlClient

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
        var tabSelection = 0
        var groups: [SelectGroupMember] = []
        var mutualFollows: [UserOverview] = []
        var companions: [InputCompanion] = []
        var query: String = ""

        // presentation
        var isPresentedInputOuterCompanionView = false

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
        case finish([InputCompanion])

        // setter
        case setTabSelection(Int)
        case setQuery(String)
        case setOuterCompanion(String)
        case setInnerCompanion(UserOverview)
        case deleteInnerCompanion(String)
        case setGroups([SelectGroupMember])
        case setMutualFollows([UserOverview])

        // presentation
        case isPresentedInputOuterCompanionView(Bool)

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
                    await withTaskGroup(of: Void.self) { group in
                        group.addTask {
                            do {
                                let groups = try (await gqlClient.query(PologAPI.GetAllGroupMembersQuery())).me.groups.nodes.map { $0.fragments.selectGroupMemberFragment }
                                await send(.setGroups(groups))
                            } catch {
                                await send(.setAlert(AlertEntity.from(error: error)))
                            }
                        }

                        group.addTask {
                            do {
                                let users = try (await gqlClient.query(PologAPI.GetMutualFollowsQuery())).me.mutualFollows.map { $0.fragments.userOverviewFragment }
                                await send(.setMutualFollows(users))
                            } catch {
                                await send(.setAlert(AlertEntity.from(error: error)))
                            }
                        }
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
            case .confirm:
                return Effect.send(.finish(state.companions))
            case .finish:
                return .run { _ in
                    await dismiss()
                }
            // ----------------------------------------------------------------
            // setter
            // ----------------------------------------------------------------
            case .setTabSelection(let val):
                state.tabSelection = val
                return .none
            case .setQuery(let val):
                state.query = val
                return .none
            case .setOuterCompanion(let val):
                state.companions.append(.outer(InputOuterCompanion(name: val)))
                return .none
            case .setInnerCompanion(let val):
                if let index = state.companions.firstIndex(where: { $0.id == val.id }) {
                    state.companions.remove(at: index)
                } else {
                    state.companions.append(.inner(InputInnerCompanion(id: val.id, name: val.fullName, iconUrl: val.iconSignedUrl.url)))
                }
                return .none
            case .deleteInnerCompanion(let id):
                if let index = state.companions.firstIndex(where: { $0.id == id }) {
                    state.companions.remove(at: index)
                }
                return .none
            case .setGroups(let val):
                state.groups = val
                return .none
            case .setMutualFollows(let val):
                state.mutualFollows = val
                return .none
            // ----------------------------------------------------------------
            // presentation
            // ----------------------------------------------------------------
            case .isPresentedInputOuterCompanionView(let val):
                state.isPresentedInputOuterCompanionView = val
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

func filteredUsers(users: [UserOverview], q: String) -> [UserOverview] {
    if q.isEmpty {
        return users
    }
    return users.filter { $0.fullName.contains(q) || $0.username.contains(q) }
}

extension PologCompanionRegistrationReducer.Destination.State: Equatable {}
