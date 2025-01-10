import ComposableArchitecture
import SwiftUI

struct PologRouteIndexRegistrationView: View {
    @Bindable var store: StoreOf<PologRouteIndexRegistrationReducer>

    var body: some View {
        ContentView(store: store)
            .onAppear {
                store.send(.initialize)
            }
            .background(Color(.systemBackground))
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("目次を編集")
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
                store.send(.presentPologRegistrationView)
            }) {
                Text("次へ")
                    .foregroundColor(Color(UIColor.label))
            })
            .modifier(NavigationModifier(store: store))
            .modifier(HUDModifier(isPresented: $store.isPresentedHUD.sending(\.isPresentedHUD)))
            .modifier(AlertModifier(entity: store.alert, onTap: {
                store.send(.isPresentedAlert(false))
            }, isPresented: $store.isPresentedAlert.sending(\.isPresentedAlert)))
            .colorScheme(.light)
            .toolbarColorScheme(.light, for: .navigationBar)
    }
}

extension PologRouteIndexRegistrationView {
    struct ContentView: View {
        @Bindable var store: StoreOf<PologRouteIndexRegistrationReducer>

        @State private var isExpanded: [String: Bool] = [:]

        var body: some View {
            ScrollView {
                VStack(alignment: .leading) {
                    Spacer16()
                    Text(store.inputPolog.title)
                        .bold()
                        .font(.title3)
                        .foregroundColor(Color(UIColor.label))
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Spacer16()
                    HStack {
                        Image("IconCalender")
                            .frame(width: 20, height: 20)
                        Spacer12()
                        Text(store.inputPolog.routes.isEmpty ? "---" : store.inputPolog.routes.first!.assetDate.toUnitString(timeZone: TimeZone.current))
                            .font(.subheadline)
                            .foregroundColor(Color(UIColor.label))
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)

                    Spacer32()
                    ForEach(store.routeIndexList.indices, id: \.self) { i in
                        let index = store.routeIndexList[i]
                        VStack(alignment: .leading) {
                            if store.routeIndexList.count > 1 {
                                Text("\(i + 1)日目")
                                    .font(.subheadline)
                                    .foregroundColor(Color(UIColor.label))
                                    .bold()
                                Spacer8()
                            }

                            ForEach(index.routes, id: \.id) { input in
                                let thumbnailSize = CGSize(width: 40, height: 40)
                                VStack {
                                    DisclosureGroup(isExpanded: Binding<Bool>(
                                        get: {
                                            self.isExpanded[input.id, default: false]
                                        },
                                        set: { newValue in
                                            self.isExpanded[input.id] = newValue
                                        }
                                    )) {
                                        VStack(alignment: .leading) {
                                            Spacer16()
                                            Text("評価")
                                                .font(.subheadline)
                                                .foregroundColor(Color(UIColor.secondaryLabel))
                                                .bold()
                                                .padding(.horizontal, 16)

                                            let starSize = CGSize(width: 30, height: 30)
                                            let spacing: CGFloat = 10
                                            HStack(spacing: spacing) {
                                                Spacer()
                                                ForEach(1 ... 5, id: \.self) { index in
                                                    Image(systemName: index <= input.review ? "star.fill" : "star")
                                                        .resizable()
                                                        .frame(width: starSize.width, height: starSize.height)
                                                        .foregroundColor(.yellow)
                                                        .onTapGesture {
                                                            store.send(.setReview((input, index)))
                                                        }
                                                }
                                                Spacer()
                                            }
                                            .frame(height: 55)
                                            .background(Color(UIColor.tertiarySystemBackground))
                                            .cornerRadius(8)
                                            .gesture(
                                                DragGesture(minimumDistance: 0)
                                                    .onChanged { value in
                                                        let newValue = calcReviewPoint(x: value.location.x, starWidth: starSize.width + spacing)
                                                        store.send(.setReview((input, newValue)))
                                                    }
                                            )

                                            Spacer16()
                                            Text("使用した金額")
                                                .font(.subheadline)
                                                .foregroundColor(Color(UIColor.secondaryLabel))
                                                .bold()
                                                .padding(.horizontal, 16)

                                            ScrollView(.horizontal, showsIndicators: false) {
                                                HStack(spacing: 16) {
                                                    ForEach(priceLabelList, id: \.self) { label in
                                                        let selected = input.priceLabel == label
                                                        Button(action: {
                                                            store.send(.setPriceLabel((input, label)))
                                                        }) {
                                                            Text(label)
                                                                .padding(.vertical, 4)
                                                                .padding(.horizontal, 10)
                                                                .background(RoundedRectangle(cornerRadius: .infinity).fill(selected ? Color.blue : Color(UIColor.tertiarySystemFill)))
                                                                .foregroundColor(selected ? Color.white : Color(UIColor.label))
                                                                .font(.subheadline)
                                                        }
                                                    }
                                                }
                                            }

                                            Spacer16()
                                        }
                                        .padding(.horizontal, 16)
                                    } label: {
                                        HStack {
                                            Spacer12()
                                            Group {
                                                switch input.asset {
                                                case .localAsset(let asset):
                                                    LocalImageView(asset: asset, size: thumbnailSize, scaleType: .fill)
                                                case .remoteAsset(let asset):
                                                    RemoteImageView(url: asset.thumbnailUrl, size: thumbnailSize, scaleType: .fill)
                                                }
                                            }
                                            .frame(width: thumbnailSize.width, height: thumbnailSize.height)
                                            Spacer12()
                                            Text(input.assetDate.timeDisplayUS)
                                                .font(.callout)
                                                .foregroundColor(Color(UIColor.label))
                                            Spacer()
                                        }
                                        .frame(height: 60)
                                    }
                                    .disclosureGroupStyle(DisclosureStyle())
                                    .onTapGesture {
                                        withAnimation {
                                            let current = self.isExpanded[input.id, default: false]
                                            self.isExpanded[input.id] = !current
                                        }
                                    }
                                }
                                .background(Color(UIColor.secondarySystemBackground))
                                .cornerRadius(4.0)

                                if input.id != store.lastRouteIndex?.id {
                                    HStack(spacing: 0) {
                                        Spacer().frame(width: 26)

                                        ZStack(alignment: !(input == index.routes.last && i != store.routeIndexList.count - 1) ? .center : .bottom) {
                                            HStack(spacing: 0) {
                                                Spacer()
                                                Rectangle()
                                                    .frame(width: 1)
                                                    .frame(maxHeight: .infinity)
                                                    .foregroundColor(Color(UIColor.label))
                                                Spacer()
                                            }

                                            HStack(spacing: 0) {
                                                Spacer()
                                                DownwardTriangle()
                                                    .fill(Color(UIColor.label))
                                                    .frame(width: 10, height: 10)
                                                Spacer()
                                            }
                                        }
                                        .frame(width: 10, height: 64)

                                        Spacer12()

                                        ScrollView(.horizontal, showsIndicators: false) {
                                            let iconSize = CGSize(width: 26, height: 26)
                                            HStack(spacing: 8) {
                                                ForEach(transportationList, id: \.self) { transportation in
                                                    let selected = input.transportations.contains(transportation)
                                                    if let icon = transportation.icon {
                                                        Button(action: {
                                                            store.send(.setTransportation((input, transportation)))
                                                        }) {
                                                            icon
                                                                .resizable()
                                                                .frame(width: 16, height: 16)
                                                                .foregroundColor(.white)
                                                                .background(Circle().fill(selected ? Color.blue : Color.gray).frame(width: iconSize.width, height: iconSize.height))
                                                        }
                                                        .frame(width: iconSize.width, height: iconSize.height)
                                                    }
                                                }
                                                Spacer()
                                            }
                                            .frame(height: iconSize.height)
                                        }
                                    }
                                }
                            }

                            Spacer32()
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 16)
            }
        }

        private func calcReviewPoint(x: CGFloat, starWidth: CGFloat) -> Int {
            let newRating = Int(x / starWidth)
            return max(0, min(5, newRating))
        }
    }
}

extension PologRouteIndexRegistrationView {
    struct NavigationModifier: ViewModifier {
        @Bindable var store: StoreOf<PologRouteIndexRegistrationReducer>

        func body(content: Content) -> some View {
            WithViewStore(store, observe: { $0 }) { _ in
                content
                    .navigationDestination(
                        item: $store.scope(state: \.destination?.pologRegistration, action: \.destination.pologRegistration)
                    ) { store in
                        PologRegistrationView(store: store)
                    }
            }
        }
    }
}
