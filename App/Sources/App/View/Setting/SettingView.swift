import ComposableArchitecture
import SwiftUI

let reviewUrl = URL(string: "https://itunes.apple.com/app/1614383617?action=write-review")!
let surveyUrl = URL(string: "https://polog.jp/terms")!
let termsUrl = URL(string: "https://polog.jp/terms")!
let privacyPolicyUrl = URL(string: "https://polog.jp/privacy-policy")!

struct SettingView: View {
    @Environment(\.scenePhase) var scenePhase

    @Bindable var store: StoreOf<SettingReducer>

    var body: some View {
        ContentView(store: store)
            .onAppear {
                store.send(.initialize)
            }
            .modifier(NavigationModifier(store: store))
            .modifier(HUDModifier(isPresented: $store.isPresentedHUD.sending(\.isPresentedHUD)))
            .modifier(AlertModifier(entity: store.alert, onTap: {
                store.send(.isPresentedAlert(false))
            }, isPresented: $store.isPresentedAlert.sending(\.isPresentedAlert)))
            .navigationTitle("設定")
            .navigationBarBackButtonHidden(true)
            .navigationBarItems(leading: Group {
                Button(action: {
                    store.send(.dismiss)
                }) {
                    Image(systemName: "chevron.backward")
                        .foregroundColor(Color(UIColor.label))
                }
            })
            .toolbarRole(.editor)
    }
}

extension SettingView {
    struct ContentView: View {
        @Bindable var store: StoreOf<SettingReducer>
        
        var body: some View {
            VStack {
                Divider()
                
                List {
                    Section {
                        NavigationLink("アカウント", destination: {})
                    }
                    .listRowBackground(Color(.secondarySystemBackground))
                            
                    Section("アプリの設定") {
                        NavigationLink("ブロックしたアカウント", destination: {})
                        Toggle(isOn: .constant(true)) {
                            Text("評価・金額")
                        }
                        Button {
                            if let url = URL(string: UIApplication.openNotificationSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        } label: {
                            HStack {
                                Text("通知")
                                    .foregroundStyle(Color(.label))
                                Spacer()
                                if false {
                                    Text("拒否されました")
                                        .foregroundStyle(Color(.systemRed))
                                }
                            }
                        }
                    }
                    .listRowBackground(Color(.secondarySystemBackground))
                            
                    Section("アプリについて") {
                        Button("チュートリアル") {}
                            .buttonStyle(PlainButtonStyle())
                                
                        Button("FAQ") {}
                            .buttonStyle(PlainButtonStyle())
                                
                        Button("要望・お問い合わせ") {}
                            .buttonStyle(PlainButtonStyle())
                                
                        Link(destination: reviewUrl) {
                            Text("レビュー")
                        }
                        .buttonStyle(PlainButtonStyle())
                                
                        Link(destination: surveyUrl) {
                            Text("アンケート")
                        }
                        .buttonStyle(PlainButtonStyle())
                                
                        Link(destination: termsUrl) {
                            Text("利用規約")
                        }
                        .buttonStyle(PlainButtonStyle())
                                
                        Link(destination: privacyPolicyUrl) {
                            Text("プライバシーポリシー")
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .listRowBackground(Color(.secondarySystemBackground))
                            
                    Section {
                        Button("ログアウト") {
                            store.send(.logout)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .foregroundStyle(Color.red)
                    }
                    .listRowBackground(Color(.secondarySystemBackground))
                            
                    Section(header: Text("ver \(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String)").frame(maxWidth: .infinity, alignment: .center).textCase(.lowercase)) {}
                }
                .scrollContentBackground(.hidden)
                .background(Color(.systemBackground))
                .applyContents {
                    if #available(iOS 17.0, *) {
                        $0.contentMargins(.vertical, 20)
                    }
                }
            }
        }
    }
}

extension SettingView {
    struct NavigationModifier: ViewModifier {
        @Bindable var store: StoreOf<SettingReducer>

        func body(content: Content) -> some View {
            WithViewStore(store, observe: { $0 }) { _ in
                content
            }
        }
    }
}
