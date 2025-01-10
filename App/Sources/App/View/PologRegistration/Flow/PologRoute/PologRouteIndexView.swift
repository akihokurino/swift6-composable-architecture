import ComposableArchitecture
import SwiftUI

extension PologRouteRegistrationView {
    struct IndexView: View {
        @Bindable var store: StoreOf<PologRouteRegistrationReducer>
        
        var body: some View {
            VStack {
                Spacer16()
                HStack {
                    Text("目次")
                        .bold()
                        .font(.title3)
                        .foregroundColor(Color(UIColor.label))
                    Spacer()
                    Button(action: {
                        store.send(.isPresentedIndexView(false))
                    }) {
                        Image(systemName: "xmark")
                            .foregroundColor(Color(UIColor.label))
                            .background(Circle().fill(Color(UIColor.secondarySystemFill)).frame(width: 30, height: 30))
                    }
                }
                .padding(.horizontal, 16)
                Spacer16()
                    
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        if store.inputPolog.isEdit {
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
                                Text(store.inputPolog.routes.isEmpty ? "---" : store.inputPolog.routes.first!.asset.date.toUnitString(timeZone: TimeZone.current))
                                    .font(.subheadline)
                                    .foregroundColor(Color(UIColor.label))
                            }
                        }
                            
                        IndexListView(store: store)
                    }
                    .padding(.horizontal, 16)
                }
            }
            .preferredColorScheme(.dark)
        }
    }
}

extension PologRouteRegistrationView {
    struct IndexListView: View {
        @Bindable var store: StoreOf<PologRouteRegistrationReducer>
        
        var body: some View {
            ForEach(store.routeIndexList.indices, id: \.self) { i in
                let index = store.routeIndexList[i]
                VStack(alignment: .leading, spacing: 0) {
                    if store.routeIndexList.count > 1 {
                        Text("\(i + 1)日目")
                            .font(.subheadline)
                            .foregroundColor(Color(UIColor.label))
                            .bold()
                        Spacer8()
                    }
                                                    
                    ForEach(index.routes.indices, id: \.self) { j in
                        let route = index.routes[j]
                        let thumbnailSize = CGSize(width: 40, height: 40)
                                                        
                        VStack(alignment: .leading, spacing: 0) {
                            Button(action: {
                                store.send(.movePologRoute(route))
                                store.send(.isPresentedIndexView(false))
                            }) {
                                HStack {
                                    Spacer12()
                                                                        
                                    Group {
                                        switch route.asset {
                                        case .localAsset(let asset):
                                            LocalImageView(asset: asset, size: thumbnailSize, scaleType: .fill)
                                        case .remoteAsset(let asset):
                                            RemoteImageView(url: asset.thumbnailUrl, size: thumbnailSize, scaleType: .fill)
                                        }
                                    }
                                    .frame(width: thumbnailSize.width, height: thumbnailSize.height)
                                                                        
                                    Spacer12()
                                                                        
                                    VStack(alignment: .leading) {
                                        Text(route.asset.date.timeDisplayUS)
                                            .font(.callout)
                                            .foregroundColor(Color(UIColor.label))
                                        Spacer2()
                                                                            
                                        Text("TODO: スポット")
                                            .font(.subheadline)
                                            .foregroundColor(Color(UIColor.secondaryLabel))
                                        Spacer2()
                                                                            
                                        Text(route.reviewPriceString)
                                            .font(.footnote)
                                            .foregroundColor(Color(UIColor.secondaryLabel))
                                    }
                                                                        
                                    Spacer12()
                                                                        
                                    Spacer()
                                }
                                .padding(.vertical, 12)
                                .background(Color(UIColor.secondarySystemBackground))
                                .cornerRadius(8.0)
                            }
                                
                            if route.id != store.lastRouteIndex?.id {
                                HStack {
                                    Spacer().frame(width: 26)
                                                                                                        
                                    ZStack(alignment: !(j == index.routes.count - 1 && i != store.routeIndexList.count - 1) ? .center : .bottom) {
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
                                                                                                            
                                    ForEach(Array(route.transportations.filter { $0.icon != nil }), id: \.self) { transportation in
                                        transportation.icon!
                                            .resizable()
                                            .frame(width: 16, height: 16)
                                            .foregroundColor(Color(UIColor.secondaryLabel))
                                    }
                                                                                                            
                                    Spacer()
                                }
                                .frame(height: 64)
                            }
                        }
                    }
                        
                    Spacer32()
                }
            }
        }
    }
}
