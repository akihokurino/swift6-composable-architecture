import ComposableArchitecture
import SwiftUI

struct PologRouteVideoTrimmerView: View {
    @Bindable var store: StoreOf<PologRouteVideoTrimmerReducer>

    var body: some View {
        ContentView(store: store)
            .navigationTitle("動画の編集")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(leading: Button(action: {
                store.send(.dismiss)
            }) {
                Text("キャンセル")
                    .foregroundColor(Color(UIColor.label))
            }, trailing: Button(action: {
                store.send(.confirm)
            }) {
                Text("確定")
                    .foregroundColor(Color(UIColor.label))
                    .fontWeight(.bold)
            })
            .modifier(HUDModifier(isPresented: $store.isPresentedHUD.sending(\.isPresentedHUD)))
            .modifier(AlertModifier(entity: store.alert, onTap: {
                store.send(.isPresentedAlert(false))
            }, isPresented: $store.isPresentedAlert.sending(\.isPresentedAlert)))
            .preferredColorScheme(.dark)
    }
}

extension PologRouteVideoTrimmerView {
    struct ContentView: View {
        @Bindable var store: StoreOf<PologRouteVideoTrimmerReducer>

        var body: some View {
            GeometryReader { geometry in
                let videoSize = CGSize(width: geometry.size.width, height: geometry.size.width * (4.0 / 3.0))
                let widthRatio: CGFloat = 0.7
                let aspectRatio: CGFloat = 49 / 270
                let trimmerViewSize = CGSize(
                    width: geometry.size.width * widthRatio,
                    height: geometry.size.width * widthRatio * aspectRatio
                )

                VStack(alignment: .leading, spacing: 0) {
                    Group {
                        switch store.asset {
                        case .localAsset(let asset):
                            VideoEditView(
                                asset: asset,
                                videoSize: videoSize,
                                start: $store.startTime.sending(\.setStartTime),
                                end: $store.endTime.sending(\.setEndTime),
                                isMuted: store.isMuted
                            )
                        case .remoteAsset(let asset):
                            VideoEditView(
                                url: asset.url,
                                videoSize: videoSize,
                                start: $store.startTime.sending(\.setStartTime),
                                end: $store.endTime.sending(\.setEndTime),
                                isMuted: store.isMuted
                            )
                        }
                    }
                    .frame(height: abs(videoSize.height + trimmerViewSize.height))
                    Spacer12()

                    HStack {
                        Spacer()
                        Text("クリップの長さ(最大15秒):")
                            .font(.footnote)
                            .foregroundColor(Color(UIColor.secondaryLabel))
                        Text(store.duration)
                            .font(.footnote)
                            .foregroundColor(Color(UIColor.label))
                        Spacer()
                    }
                    Spacer16()

                    VStack {
                        Toggle("ミュート", isOn: $store.isMuted.sending(\.setIsMuted))
                            .padding(.horizontal, 16)
                    }
                    .frame(height: 60)
                    .background(Color(UIColor.tertiarySystemBackground))
                    .cornerRadius(4.0)
                    .padding(.horizontal, 16)

                    Spacer()
                }
                .background(Color(UIColor.secondarySystemBackground))
            }
        }
    }
}
