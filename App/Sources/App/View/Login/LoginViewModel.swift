import AuthenticationServices
import ComposableArchitecture
import Foundation

@Reducer
struct LoginReducer {
    @Dependency(\.authClient) var authClient
    @Dependency(\.gqlClient) var gqlClient

    @Reducer
    enum Destination {
        case userRegistration(UserRegistrationReducer)
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
        var viewType: ViewType = .login
        var appleNonce: String?
        var smsVerificationId: String?
        var phoneNumber: String = ""
        var smsCode: String = ""

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
        case sendSMSCode
        case loginByPhoneNumber
        case loginByApple(Result<ASAuthorization, Error>)
        case loginByGoogle(UIViewController)
        case login(LoginProviderInfo)
        case finish(Me)

        // setter
        case setViewType(ViewType)
        case setAppleNonce(String)
        case setSMSVerificationId(String)
        case setPhoneNumber(String)
        case setSMSCode(String)

        // presentation
        case presentUserRegistrationView

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
            case .sendSMSCode:
                guard let phoneNumber = state.phoneNumber.e164 else {
                    return .none
                }
                state.isPresentedHUD = true

                return .run { send in
                    do {
                        let verificationId = try await authClient.sendSMSPinCode(phoneNumber: phoneNumber)
                        await send(.setSMSVerificationId(verificationId))
                        await send(.setViewType(.inputCode))
                    } catch {
                        await send(.setAlert(AlertEntity.from(error: error)))
                    }

                    await send(.isPresentedHUD(false))
                }
            case .loginByPhoneNumber:
                guard let verificationId = state.smsVerificationId, state.smsCode.isNotEmpty else {
                    return .none
                }
                let code = state.smsCode
                state.isPresentedHUD = true

                return .run { send in
                    do {
                        let providerInfo = try await authClient.loginByPhoneNumber(code: code, verificationId: verificationId)
                        await send(.login(providerInfo))
                    } catch {
                        await send(.setAlert(AlertEntity.from(error: error)))
                        await send(.isPresentedHUD(false))
                    }
                }
            case .loginByApple(let authResult):
                switch authResult {
                case .success(let authResult):
                    guard let appleIDCredential = authResult.credential as? ASAuthorizationAppleIDCredential else {
                        return Effect.send(.setAlert(AlertEntity(title: "エラーが発生しました", message: "不正なパラメータです。")))
                    }
                    guard let nonce = state.appleNonce else {
                        return Effect.send(.setAlert(AlertEntity(title: "エラーが発生しました", message: "不正なパラメータです。")))
                    }
                    state.isPresentedHUD = true

                    return .run { send in
                        do {
                            let providerInfo = try await authClient.loginByApple(appleIDCredential: appleIDCredential, nonce: nonce)
                            await send(.login(providerInfo))
                        } catch {
                            await send(.setAlert(AlertEntity.from(error: error)))
                            await send(.isPresentedHUD(false))
                        }
                    }
                case .failure(let error):
                    return Effect.send(.setAlert(AlertEntity.from(error: error)))
                }
            case .loginByGoogle(let controller):
                state.isPresentedHUD = true

                return .run { send in
                    do {
                        let providerInfo = try await authClient.loginByGoogle(withPresenting: controller)
                        await send(.login(providerInfo))
                    } catch {
                        await send(.setAlert(AlertEntity.from(error: error)))
                        await send(.isPresentedHUD(false))
                    }
                }
            case .login:
                state.isPresentedHUD = true

                return .run { send in
                    do {
                        let isExist = try (await gqlClient.query(PologAPI.ExistUserQuery())).userExist
                        if isExist {
                            let me = try (await gqlClient.query(PologAPI.GetMeQuery())).me.fragments.meFragment
                            await send(.finish(me))
                        } else {
                            await send(.presentUserRegistrationView)
                        }
                    } catch {
                        await send(.setAlert(AlertEntity.from(error: error)))
                    }

                    await send(.isPresentedHUD(false))
                }
            case .finish(let me):
                state.loginUser = SharedUserInfo(me: me)
                // delegate
                return .none
            // ----------------------------------------------------------------
            // setter
            // ----------------------------------------------------------------
            case .setViewType(let viewType):
                state.viewType = viewType
                return .none
            case .setAppleNonce(let nonce):
                state.appleNonce = nonce
                return .none
            case .setSMSVerificationId(let id):
                state.smsVerificationId = id
                return .none
            case .setPhoneNumber(let val):
                state.phoneNumber = val
                return .none
            case .setSMSCode(let val):
                state.smsCode = val
                return .none
            // ----------------------------------------------------------------
            // presentation
            // ----------------------------------------------------------------
            case .presentUserRegistrationView:
                state.destination = .userRegistration(UserRegistrationReducer.State())
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
        case login
        case inputPhoneNumber
        case inputCode
    }
}

extension LoginReducer.Destination.State: Equatable {}
