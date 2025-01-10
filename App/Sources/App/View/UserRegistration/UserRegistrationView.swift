import ComposableArchitecture
import SwiftUI

struct UserRegistrationView: View {
    @Bindable var store: StoreOf<UserRegistrationReducer>

    var body: some View {
        ContentView(store: store)
            .onAppear {
                store.send(.initialize)
            }
            .navigationBarBackButtonHidden(true)
            .modifier(NavigationModifier(store: store))
            .modifier(ActionSheetModifier(store: store))
            .modifier(HUDModifier(isPresented: $store.isPresentedHUD.sending(\.isPresentedHUD)))
            .modifier(AlertModifier(entity: store.alert, onTap: {
                store.send(.isPresentedAlert(false))
            }, isPresented: $store.isPresentedAlert.sending(\.isPresentedAlert)))
    }
}

extension UserRegistrationView {
    struct ContentView: View {
        @Bindable var store: StoreOf<UserRegistrationReducer>

        var body: some View {
            Group {
                switch store.viewType {
                case .inputFullName:
                    InputFullNameView(store: store)
                case .inputUsername:
                    InputUsernameView(store: store)
                case .inputProfileIcon:
                    InputProfileIconView(store: store)
                case .done:
                    DoneView(store: store)
                }
            }
        }
    }
}

extension UserRegistrationView {
    struct InputFullNameView: View {
        @Bindable var store: StoreOf<UserRegistrationReducer>
        @FocusState private var isTextFieldFocused: Bool

        var body: some View {
            VStack {
                Spacer80()
                Text("プロフィール設定")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color(.label))
                Spacer32()
                Text("あなたのプロフィール名を入力して下さい\n（後から変更が可能です）")
                    .font(.callout)
                    .fontWeight(.medium)
                    .foregroundStyle(Color(.label))
                    .multilineTextAlignment(.center)
                Spacer32()

                TextFieldView(value: $store.fullName.sending(\.setFullName), focus: _isTextFieldFocused, placeholder: "プロフィール名", keyboardType: .default)
                    .padding(.horizontal, 36)
                    .onAppear {
                        isTextFieldFocused = true
                    }
                Spacer46()

                ActionButtonView(text: "次へ", buttonType: store.fullName.isEmpty ? .disable : .primary) {
                    if store.fullName.isNotEmpty {
                        store.send(.setViewType(.inputUsername))
                    }
                }
                .padding(.horizontal, 60)

                Spacer80()
                Text("1/3")
                Spacer()
            }
        }
    }
}

extension UserRegistrationView {
    struct InputUsernameView: View {
        @Bindable var store: StoreOf<UserRegistrationReducer>
        @FocusState private var isTextFieldFocused: Bool

        var body: some View {
            VStack {
                Spacer80()
                Text("プロフィール設定")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color(.label))
                Spacer32()
                Text("ユーザー名を入力して下さい")
                    .font(.callout)
                    .fontWeight(.medium)
                    .foregroundStyle(Color(.label))
                Spacer32()

                TextFieldView(value: $store.username.sending(\.setUsername), focus: _isTextFieldFocused, placeholder: "ユーザー名", keyboardType: .default)
                    .padding(.horizontal, 36)
                    .onAppear {
                        isTextFieldFocused = true
                    }
                Spacer46()

                ActionButtonView(text: "次へ", buttonType: store.username.isEmpty ? .disable : .primary) {
                    if store.username.isNotEmpty {
                        store.send(.setViewType(.inputProfileIcon))
                    }
                }
                .padding(.horizontal, 60)

                Spacer80()
                Text("2/3")
                Spacer()
            }
        }
    }
}

extension UserRegistrationView {
    struct InputProfileIconView: View {
        @Bindable var store: StoreOf<UserRegistrationReducer>

        var body: some View {
            VStack {
                Spacer80()
                Text("プロフィール設定")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color(.label))
                Spacer32()
                Text("プロフィール写真を選択してください\n（後から変更が可能です）")
                    .font(.callout)
                    .fontWeight(.medium)
                    .foregroundStyle(Color(.label))
                    .multilineTextAlignment(.center)
                Spacer20()
                Group {
                    if let icon = store.profileIcon {
                        Image(uiImage: icon)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                    } else {
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                Image("IconPerson")
                                    .resizable()
                                    .frame(width: 56, height: 56)
                                Spacer()
                            }
                            Spacer()
                        }
                        .background(.gray)
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                    }
                }
                .onTapGesture {
                    store.send(.isPresentedActionSheet(true))
                }

                Spacer24()

                ActionButtonView(text: "次へ", buttonType: store.profileIcon == nil ? .disable : .primary) {
                    store.send(.register)
                }
                .padding(.horizontal, 60)

                Spacer80()
                Text("3/3")
                Spacer()
            }
        }
    }
}

extension UserRegistrationView {
    struct DoneView: View {
        @Bindable var store: StoreOf<UserRegistrationReducer>

        var body: some View {
            VStack {
                Spacer()
                Text("登録完了")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(Color(.label))
                Spacer40()
                Text("早速つかってみましょう")
                    .font(.callout)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color(.label))
                Spacer40()
                Spacer()
                ActionButtonView(text: "はじめる", buttonType: .primary) {
                    store.send(.finish)
                }
                .padding(.horizontal, 60)
                Spacer32()
            }
        }
    }
}

extension UserRegistrationView {
    struct NavigationModifier: ViewModifier {
        @Bindable var store: StoreOf<UserRegistrationReducer>

        func body(content: Content) -> some View {
            content
                .sheet(isPresented: $store.isPresentedCamera.sending(\.isPresentedCamera)) {
                    ImagePickerView(selectedImage: $store.profileIcon.sending(\.setProfileIcon), sourceType: .camera)
                }
                .sheet(isPresented: $store.isPresentedCameraRoll.sending(\.isPresentedCameraRoll)) {
                    ImagePickerView(selectedImage: $store.profileIcon.sending(\.setProfileIcon), sourceType: .photoLibrary)
                }
        }
    }
}

extension UserRegistrationView {
    struct ActionSheetModifier: ViewModifier {
        @Bindable var store: StoreOf<UserRegistrationReducer>

        func body(content: Content) -> some View {
            content
                .actionSheet(isPresented: $store.isPresentedActionSheet.sending(\.isPresentedActionSheet)) {
                    ActionSheet(
                        title: Text(""),
                        buttons: [
                            .default(Text("カメラで撮影")) {
                                store.send(.isPresentedCamera(true))
                            },
                            .default(Text("ライブラリから選択")) {
                                store.send(.isPresentedCameraRoll(true))
                            },
                            .cancel(Text("キャンセル")) {
                                store.send(.isPresentedActionSheet(false))
                            }
                        ]
                    )
                }
        }
    }
}
