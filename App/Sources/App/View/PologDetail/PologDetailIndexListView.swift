import ComposableArchitecture
import SwiftUI

extension PologDetailView {
    struct IndexListView: View {
        @Bindable var store: StoreOf<PologDetailReducer>
        
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
                                        
                                    RemoteImageView(url: route.thumbnailURL, size: thumbnailSize, radius: 6, scaleType: .fill)
                                        .frame(width: thumbnailSize.width, height: thumbnailSize.height)
                                        
                                    Spacer12()
                                        
                                    VStack(alignment: .leading) {
                                        Text(route.assetDate.iso8601?.timeDisplayUS ?? "")
                                            .font(.callout)
                                            .fontWeight(.semibold)
                                            .foregroundColor(Color(UIColor.label))
                                        Spacer2()
                                            
                                        Text(route.spot?.name ?? "")
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
                                        
                                    ForEach(Array(route.transportations.filter { $0.value?.icon != nil }), id: \.self) { transportation in
                                        transportation.value!.icon!
                                            .resizable()
                                            .frame(width: 20, height: 20)
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
