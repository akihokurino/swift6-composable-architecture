import ComposableArchitecture
import SwiftUI

struct PologCompanionRegistrationView: View {
    @Bindable var store: StoreOf<PologCompanionRegistrationReducer>

    var body: some View {
        ContentView(store: store)
            .onAppear {
                store.send(.initialize)
            }
            .background(Color(.systemBackground))
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("同行者を追加")
                        .fontWeight(.semibold)
                        .foregroundColor(Color(.label))
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .navigationBarItems(leading: Group {
                Button(action: {
                    store.send(.dismiss)
                }) {
                    Image(systemName: "chevron.backward")
                        .foregroundColor(Color(UIColor.label))
                }
            }, trailing: Button(action: {
                store.send(.confirm)
            }) {
                Text("確定")
                    .foregroundColor(store.companions.isEmpty ? Color(UIColor.tertiaryLabel) : Color(UIColor.label))
            }
            .disabled(store.companions.isEmpty))
            .modifier(HUDModifier(isPresented: $store.isPresentedHUD.sending(\.isPresentedHUD)))
            .modifier(AlertModifier(entity: store.alert, onTap: {
                store.send(.isPresentedAlert(false))
            }, isPresented: $store.isPresentedAlert.sending(\.isPresentedAlert)))
            .modifier(NavigationModifier(store: store))
            .colorScheme(.light)
            .toolbarColorScheme(.light, for: .automatic)
    }
}

extension PologCompanionRegistrationView {
    struct ContentView: View {
        @Bindable var store: StoreOf<PologCompanionRegistrationReducer>

        var body: some View {
            let companionIconSize = CGSize(width: 50, height: 50)
            let companionDeleteIconSize = CGSize(width: 24, height: 24)

            VStack {
                TextFieldView(
                    value: $store.query.sending(\.setQuery),
                    placeholder: "相互フォロワー、グループ参加者を検索",
                    keyboardType: .default,
                    height: 36,
                    submitLabel: .search,
                    leftIcon: Image(systemName: "magnifyingglass"),
                    hasCloseButton: true
                ) { _ in
                }
                .padding(.horizontal, 16)

                Spacer16()

                HStack {
                    Text("同行者\(store.companions.count)")
                        .font(.footnote)
                        .foregroundColor(Color(UIColor.secondaryLabel))
                        .bold()
                    Spacer()
                    Button(action: {
                        store.send(.isPresentedInputOuterCompanionView(true))
                    }) {
                        Text("+polog利用してない同行者を追加")
                            .font(.subheadline)
                            .foregroundColor(Color(UIColor.label))
                    }
                }
                .padding(.horizontal, 16)

                Spacer20()

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(Array(store.companions), id: \.id) { item in
                            ZStack {
                                VStack(spacing: 0) {
                                    if let url = item.iconUrl {
                                        RemoteImageView(url: url, size: companionIconSize, isCircle: true)
                                    } else {
                                        VStack {
                                            Image(systemName: "photo")
                                                .background(Circle().fill(Color.gray).frame(width: companionIconSize.width, height: companionIconSize.height))
                                        }
                                        .frame(width: companionIconSize.width, height: companionIconSize.height)
                                    }

                                    Spacer4()

                                    Text(item.name)
                                        .lineLimit(2)
                                        .fixedSize(horizontal: false, vertical: true)
                                        .font(.caption)
                                        .foregroundColor(Color(UIColor.label))

                                    Spacer()
                                }

                                VStack {
                                    HStack {
                                        Spacer()
                                        Button(action: {
                                            store.send(.deleteInnerCompanion(item.id))
                                        }) {
                                            Image(systemName: "xmark")
                                                .resizable()
                                                .frame(width: 10, height: 10)
                                                .foregroundColor(Color(UIColor.label))
                                        }
                                        .frame(width: companionDeleteIconSize.width, height: companionDeleteIconSize.height)
                                        .background(Circle().fill(.regularMaterial).frame(width: companionDeleteIconSize.width, height: companionDeleteIconSize.height))
                                    }
                                    Spacer()
                                }
                            }
                            .frame(width: companionIconSize.width, height: companionIconSize.height + 60)
                        }

                        Spacer()
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 16)

                Spacer24()

                SlideTabView(contents: [
                    SlideTabContent(id: 0, title: "相互フォロワー", inner: AnyView(MutualFollowsSelectView(store: store))),
                    SlideTabContent(id: 1, title: "グループ参加者", inner: AnyView(GroupMemberSelectView(store: store))),
                ], selection: $store.tabSelection.sending(\.setTabSelection))
            }
        }
    }
}

extension PologCompanionRegistrationView {
    struct NavigationModifier: ViewModifier {
        @Bindable var store: StoreOf<PologCompanionRegistrationReducer>

        func body(content: Content) -> some View {
            WithViewStore(store, observe: { $0 }) { _ in
                content
                    .sheet(isPresented: $store.isPresentedInputOuterCompanionView.sending(\.isPresentedInputOuterCompanionView)) {
                        InputOuterCompanionView(store: store)
                            .presentationDetents([.medium])
                    }
            }
        }
    }
}
