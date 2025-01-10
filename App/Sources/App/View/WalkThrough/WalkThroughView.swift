import ComposableArchitecture
import SwiftUI

struct WalkThroughView: View {
    @Bindable var store: StoreOf<WalkThroughReducer>

    var body: some View {
        ContentView(store: store)
            .onAppear {
                store.send(.initialize)
            }
            .modifier(HUDModifier(isPresented: $store.isPresentedHUD.sending(\.isPresentedHUD)))
            .modifier(AlertModifier(entity: store.alert, onTap: {
                store.send(.isPresentedAlert(false))
            }, isPresented: $store.isPresentedAlert.sending(\.isPresentedAlert)))
    }
}

extension WalkThroughView {
    struct ContentView: View {
        @Bindable var store: StoreOf<WalkThroughReducer>
        @Environment(\.colorScheme) var colorScheme

        var body: some View {
            VStack {
                Spacer32()
                Image("AppIconLabel")
                    .resizable()
                    .frame(width: 105, height: 72)
                    .aspectRatio(contentMode: .fit)
                    .foregroundStyle(colorScheme == .light ? .black : .white)
                Spacer24()
                Text("ようこそ")
                    .font(.callout)
                    .fontWeight(.medium)
                    .foregroundStyle(Color(.label))
                Spacer8()
                TabView(selection: $store.selection.sending(\.setSelection)) {
                    ForEach(0 ..< 4) { index in
                        Group {
                            if index == 0 {
                                VStack {
                                    Text("大切な思い出の”きおく”と”きろく”を整理するためのアプリです")
                                        .font(.callout)
                                        .fontWeight(.medium)
                                        .foregroundStyle(Color(.label))
                                        .multilineTextAlignment(.center)
                                    Spacer24()
                                    Image("WalkThrough1")
                                        .resizable()
                                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                                        .aspectRatio(contentMode: .fit)
                                    Spacer().frame(width: 87, height: 87)
                                }
                            }

                            if index == 1 {
                                VStack {
                                    Text("写真を選ぶだけで”自動”で整理されます")
                                        .font(.callout)
                                        .fontWeight(.medium)
                                        .foregroundStyle(Color(.label))
                                        .multilineTextAlignment(.center)
                                    Spacer24()
                                    Image("WalkThrough2")
                                        .resizable()
                                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                                        .aspectRatio(contentMode: .fit)
                                    Spacer().frame(width: 87, height: 87)
                                }
                            }

                            if index == 2 {
                                VStack {
                                    Text("位置情報が有効の状態で写真を撮ることでかんたんにMapと連携してみることができます")
                                        .font(.callout)
                                        .fontWeight(.medium)
                                        .foregroundStyle(Color(.label))
                                        .multilineTextAlignment(.center)
                                    Spacer24()
                                    Image("WalkThrough3")
                                        .resizable()
                                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                                        .aspectRatio(contentMode: .fit)
                                    Spacer().frame(width: 87, height: 87)
                                }
                            }

                            if index == 3 {
                                VStack {
                                    Text("みんなと共有して楽しむこともできます")
                                        .font(.callout)
                                        .fontWeight(.medium)
                                        .foregroundStyle(Color(.label))
                                        .multilineTextAlignment(.center)
                                    Spacer24()
                                    Image("WalkThrough4")
                                        .resizable()
                                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                                        .aspectRatio(contentMode: .fit)
                                    Spacer().frame(width: 87, height: 87)
                                }
                            }
                        }
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .animation(.easeInOut, value: store.selection)
                .overlay(
                    VStack {
                        Spacer()
                        HStack(spacing: 10) {
                            ForEach(0 ..< 4) { index in
                                if index == store.selection {
                                    Circle()
                                        .fill(Color(.label))
                                        .frame(width: 8, height: 8)
                                } else {
                                    Circle()
                                        .fill(Color(.secondaryLabel))
                                        .frame(width: 8, height: 8)
                                }
                            }
                        }
                        Spacer24()
                    }
                )
                Spacer16()
                ActionButtonView(text: store.selection == 3 ? "始める" : "次へ", buttonType: .primary) {
                    if store.selection == 3 {
                        store.send(.finish)
                    } else {
                        store.send(.setSelection(store.selection + 1))
                    }
                }
                Spacer32()
            }
            .padding(.horizontal, 16)
        }
    }
}
