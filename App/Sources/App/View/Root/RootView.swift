import ComposableArchitecture
import SwiftUI

struct RootView: View {
    @Bindable var store: StoreOf<RootReducer>
    
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
            .onReceive(NotificationCenter.default.publisher(for: .forceLogout)) { _ in
                store.send(.logout)
            }
    }
}

extension RootView {
    struct ContentView: View {
        @Bindable var store: StoreOf<RootReducer>
        
        var body: some View {
            HStack {
                Group {
                    switch store.viewType {
                    case .loading:
                        Group {}
                    case .walkThrough:
                        if let embeded = store.scope(state: \.embededWalkThrough, action: \.embededWalkThrough) {
                            WalkThroughView(store: embeded)
                        }
                    case .login:
                        NavigationStack {
                            if let embeded = store.scope(state: \.embededLogin, action: \.embededLogin) {
                                LoginView(store: embeded)
                            }
                        }
                    case .app:
                        TabView(selection: $store.tabSelection.sending(\.setTabSelection)) {
                            NavigationStack {
                                if let embeded = store.scope(state: \.embededHome, action: \.embededHome) {
                                    HomeView(store: embeded)
                                }
                            }
                            .tabItem {
                                VStack {
                                    Image("IconGlobe")
                                        .resizable()
                                        .frame(width: 24, height: 24, alignment: .center)
                                    Text("ホーム")
                                }
                            }.tag(RootReducer.Tab.home)
                            
                            NavigationStack {
                                if let embeded = store.scope(state: \.embededSearch, action: \.embededSearch) {
                                    SearchView(store: embeded)
                                }
                            }
                            .tabItem {
                                VStack {
                                    Image("IconSearch")
                                        .resizable()
                                        .frame(width: 24, height: 24, alignment: .center)
                                    Text("検索")
                                }
                            }.tag(RootReducer.Tab.search)
                            
                            Group {
                                Text("")
                            }
                            .tabItem {
                                VStack {
                                    Image("IconPenInk")
                                        .resizable()
                                        .frame(width: 32, height: 24, alignment: .center)
                                    
                                    Text("作成")
                                }
                            }.tag(RootReducer.Tab.createPolog)
                            
                            NavigationStack {
                                if let embeded = store.scope(state: \.embededGroup, action: \.embededGroup) {
                                    GroupView(store: embeded)
                                }
                            }
                            .tint(Color(.label))
                            .tabItem {
                                VStack {
                                    Image("IconGroup")
                                        .resizable()
                                        .frame(width: 24, height: 24, alignment: .center)
                                    Text("グループ")
                                }
                            }.tag(RootReducer.Tab.group)
                            
                            NavigationStack {
                                if let embeded = store.scope(state: \.embededMyPage, action: \.embededMyPage) {
                                    MyPageView(store: embeded)
                                }
                            }
                            .tint(Color(.secondaryLabel))
                            .tabItem {
                                VStack {
                                    Image("IconMypage")
                                        .resizable()
                                        .frame(width: 24, height: 24, alignment: .center)
                                    Text("マイページ")
                                }
                            }.tag(RootReducer.Tab.myPage)
                        }
                    }
                }
            }
        }
    }
}

extension RootView {
    struct NavigationModifier: ViewModifier {
        @Bindable var store: StoreOf<RootReducer>

        func body(content: Content) -> some View {
            content
                .sheet(
                    item: $store.scope(state: \.destination?.pologRegistrationPrepare, action: \.destination.pologRegistrationPrepare)
                ) { store in
                    PologRegistrationPrepareView(store: store)
                        .presentationDetents([.medium])
                }
                .fullScreenCover(
                    item: $store.scope(state: \.destination?.pologRegistrationFlow, action: \.destination.pologRegistrationFlow)
                ) { store in
                    NavigationStack {
                        PologRegistrationFlowView(store: store)
                    }
                }
        }
    }
}
