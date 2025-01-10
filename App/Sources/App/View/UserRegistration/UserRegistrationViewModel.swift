import ComposableArchitecture
import Foundation
import UIKit

@Reducer
struct UserRegistrationReducer {
    @Dependency(\.storageClient) var storageClient
    @Dependency(\.authClient) var authClient
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
        @Shared(.inMemory("sharedUserInfo")) var loginUser: SharedUserInfo?
        var viewType: ViewType = .inputFullName
        var fullName: String = ""
        var username: String = ""
        var profileIcon: UIImage?

        // presentation
        var isPresentedActionSheet = false
        var isPresentedCamera = false
        var isPresentedCameraRoll = false

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
        case register
        case finish

        // setter
        case setMe(Me)
        case setViewType(ViewType)
        case setFullName(String)
        case setUsername(String)
        case setProfileIcon(UIImage?)

        // presentation
        case isPresentedActionSheet(Bool)
        case isPresentedCamera(Bool)
        case isPresentedCameraRoll(Bool)

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
            case .register:
                let fullName = state.fullName
                let username = state.username

                guard fullName.isNotEmpty, username.isNotEmpty, let iconData = state.profileIcon?.jpegData(compressionQuality: 0.8) else {
                    return .none
                }
                guard let uid = authClient.currentUserId else {
                    return .none
                }
                state.isPresentedHUD = true

                return .run { send in
                    do {
                        let path = "\(userProfilePath)/\(uid).jpeg"
                        let gsPath = try await storageClient.upload(data: iconData, contentType: "image/jpeg", filePath: path)
                        let me = try (await gqlClient.mutation(PologAPI.CreateUserMutation(
                            username: username,
                            fullName: fullName,
                            iconGsUrl: gsPath.absoluteString))).userCreate.fragments.meFragment

                        await send(.setMe(me))
                        await send(.setViewType(.done))
                    } catch {
                        await send(.setAlert(AlertEntity.from(error: error)))
                    }

                    await send(.isPresentedHUD(false))
                }
            case .finish:
                // delegate
                return .none
            // ----------------------------------------------------------------
            // setter
            // ----------------------------------------------------------------
            case .setMe(let val):
                state.loginUser = SharedUserInfo(me: val)
                return .none
            case .setViewType(let val):
                state.viewType = val
                return .none
            case .setFullName(let val):
                state.fullName = val
                return .none
            case .setUsername(let val):
                state.username = val
                return .none
            case .setProfileIcon(let val):
                state.profileIcon = val
                return .none
            // ----------------------------------------------------------------
            // presentation
            // ----------------------------------------------------------------
            case .isPresentedActionSheet(let val):
                state.isPresentedActionSheet = val
                return .none
            case .isPresentedCamera(let val):
                state.isPresentedCamera = val
                return .none
            case .isPresentedCameraRoll(let val):
                state.isPresentedCameraRoll = val
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

    enum ViewType: Equatable {
        case inputFullName
        case inputUsername
        case inputProfileIcon
        case done
    }
}

extension UserRegistrationReducer.Destination.State: Equatable {}
