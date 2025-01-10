import ComposableArchitecture
import Foundation

@Reducer
struct UserEditReducer {
    @Dependency(\.dismiss) var dismiss
    @Dependency(\.gqlClient) var gqlClient
    @Dependency(\.storageClient) var storageClient
    @Dependency(\.photosClient) var photosClient

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
        @Shared(.inMemory("sharedUserInfo")) var loginUser: SharedUserInfo?
        var icon: Asset?
        var fullName: String = ""
        var profile: String = ""

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
        case update

        // setter
        case setIcon(Asset)
        case setFullName(String)
        case setProfile(String)
        case setMe(Me)

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

                guard let loginUser = state.loginUser else {
                    return .none
                }
                state.fullName = loginUser.me.user.fullName
                state.profile = loginUser.me.user.profile

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
            case .update:
                guard let loginUser = state.loginUser else {
                    return .none
                }

                let icon = state.icon
                let fullName = state.fullName
                let profile = state.profile

                state.isPresentedHUD = true

                return .run { send in
                    do {
                        var data: Data?
                        if case .localAsset(let asset) = icon, let _data = try await photosClient.requestFullImage(asset: asset).jpegData(compressionQuality: 0.8) {
                            data = _data
                        } else if case .remoteAsset(let asset) = icon, let _url = asset.url {
                            data = try Data(contentsOf: _url)
                        }
                        var gsPath: URL?
                        if let data = data {
                            let path = "\(userProfilePath)/\(loginUser.me.user.id).jpeg"
                            gsPath = try await storageClient.upload(data: data, contentType: "image/jpeg", filePath: path)
                        }
                        let me = try (await gqlClient.mutation(PologAPI.UpdateUserMutation(
                            fullName: fullName,
                            iconGsUrl: gsPath?.absoluteString ?? loginUser.me.user.iconGsUrl,
                            profile: profile,
                            gender: loginUser.me.user.gender,
                            birthdate: "1991-01-01",
                            isPublic: loginUser.me.user.isPublic,
                            isPublicLikedSpot: loginUser.me.user.isPublicLikedSpot))).userUpdate.fragments.meFragment
                        await send(.setMe(me))

                        await dismiss()
                    } catch {
                        await send(.setAlert(AlertEntity.from(error: error)))
                    }

                    await send(.isPresentedHUD(false))
                }
            // ----------------------------------------------------------------
            // setter
            // ----------------------------------------------------------------
            case .setIcon(let val):
                state.icon = val
                return .none
            case .setFullName(let val):
                state.fullName = val
                return .none
            case .setProfile(let val):
                state.profile = val
                return .none
            case .setMe(let val):
                state.loginUser = SharedUserInfo(me: val)
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
                    case .dismiss:
                        return .none
                    case .finish(let selected):
                        guard let asset = selected.first else {
                            return .none
                        }
                        return Effect.send(.setIcon(asset))
                    default:
                        return .none
                    }
                }
            }
        }
        .ifLet(\.$destination, action: \.destination)
    }
}

extension UserEditReducer.Destination.State: Equatable {}
