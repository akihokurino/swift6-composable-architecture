import AuthenticationServices
import ComposableArchitecture
import SwiftUI

struct LoginView: View {
    @Bindable var store: StoreOf<LoginReducer>

    var body: some View {
        ContentView(store: store)
            .onAppear {
                store.send(.initialize)
            }
            .modifier(HUDModifier(isPresented: $store.isPresentedHUD.sending(\.isPresentedHUD)))
            .modifier(AlertModifier(entity: store.alert, onTap: {
                store.send(.isPresentedAlert(false))
            }, isPresented: $store.isPresentedAlert.sending(\.isPresentedAlert)))
            .modifier(NavigationModifier(store: store))
    }
}

extension LoginView {
    struct ContentView: View {
        @Bindable var store: StoreOf<LoginReducer>

        var body: some View {
            Group {
                switch store.viewType {
                case .login:
                    LoginButtonsView(store: store)
                case .inputPhoneNumber:
                    InputPhoneNumberView(store: store)
                case .inputCode:
                    InputPinCodeView(store: store)
                }
            }
        }
    }
}

extension LoginView {
    struct LoginButtonsView: View {
        @Environment(\.colorScheme) var colorScheme
        @Bindable var store: StoreOf<LoginReducer>

        var body: some View {
            VStack {
                Spacer80()
                Text("新規登録・ログイン")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color(.label))
                Spacer80()
                Group {
                    IconButtonView(label: "電話番号で登録", icon: "IconCall", onTap: {
                        store.send(.setViewType(.inputPhoneNumber))
                    })
                    Spacer24()
                    IconButtonView(label: "Googleで登録", icon: "IconGoogle", onTap: {
                        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                              let rootViewController = windowScene.windows.first?.rootViewController
                        else {
                            return
                        }
                        store.send(.loginByGoogle(rootViewController))
                    })
                    Spacer24()

                    SignInWithAppleButton(.continue) { request in
                        request.requestedScopes = [.fullName]
                        let nonce = randomNonceString()
                        store.send(.setAppleNonce(nonce))
                        request.nonce = sha256(nonce)
                    } onCompletion: { authResult in
                        store.send(.loginByApple(authResult))
                    }
                    .signInWithAppleButtonStyle(colorScheme == .light ? .black : .white)
                    .frame(maxWidth: .infinity, minHeight: 44, maxHeight: 44)
                }
                .padding(.horizontal, 60)
                Spacer32()

                Text("※ \(Text("[利用規約](https://example.com)").underline())と\(Text("[プライバシーポリシー](https://example.com)").underline())をお読みいただき、\n同意の上で登録してください。")
                    .font(.footnote)
                    .foregroundColor(Color(.label))
                    .padding(.horizontal, 33)
            }
        }
    }
}

extension LoginView {
    struct InputPhoneNumberView: View {
        @Bindable var store: StoreOf<LoginReducer>
        @FocusState private var isTextFieldFocused: Bool

        var body: some View {
            VStack {
                Spacer80()
                Text("新規登録・ログイン")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color(.label))
                Spacer()
                TextFieldView(value: $store.phoneNumber.sending(\.setPhoneNumber), focus: _isTextFieldFocused, placeholder: "電話番号を入力", keyboardType: .numberPad)
                    .padding(.horizontal, 36)
                    .onAppear {
                        isTextFieldFocused = true
                    }

                Spacer46()
                ActionButtonView(text: "次へ", buttonType: store.phoneNumber.count != 11 ? .disable : .primary) {
                    store.send(.sendSMSCode)
                }
                .padding(.horizontal, 60)

                Spacer()
            }
        }
    }
}

extension LoginView {
    struct InputPinCodeView: View {
        @Bindable var store: StoreOf<LoginReducer>
        @State private var otp: String = ""

        var body: some View {
            VStack {
                Spacer80()
                Text("新規登録・ログイン")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color(.label))
                Spacer32()
                Text("電話番号宛に承認コードを送信しました\n確認してコードを入力して下さい")
                    .font(.callout)
                    .fontWeight(.medium)
                    .foregroundStyle(Color(.label))
                    .multilineTextAlignment(.center)
                Spacer32()

                PinCodeView(value: $store.smsCode.sending(\.setSMSCode))
                    .padding(.horizontal, 40)
                Spacer46()

                ActionButtonView(text: "次へ", buttonType: store.smsCode.isEmpty || store.smsCode.count < 6 ? .disable : .primary) {
                    store.send(.loginByPhoneNumber)
                }
                .padding(.horizontal, 60)

                Spacer()
            }
        }
    }
}

extension LoginView {
    struct NavigationModifier: ViewModifier {
        @Bindable var store: StoreOf<LoginReducer>

        func body(content: Content) -> some View {
            content.navigationDestination(
                item: $store.scope(state: \.destination?.userRegistration, action: \.destination.userRegistration)
            ) { store in
                UserRegistrationView(store: store)
            }
        }
    }
}
