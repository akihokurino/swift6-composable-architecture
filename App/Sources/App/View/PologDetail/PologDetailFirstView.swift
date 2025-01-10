import ComposableArchitecture
import SwiftUI

extension PologDetailView {
    struct FirstView: View {
        @Bindable var store: StoreOf<PologDetailReducer>

        var body: some View {
            if let polog = store.polog {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        Spacer40()
                        Text(polog.title)
                            .bold()
                            .font(.title)
                            .foregroundColor(Color(UIColor.label))
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Spacer24()
                            
                        Group {
                            HStack {
                                Image("IconCalender")
                                    .resizable()
                                    .frame(width: 20, height: 20)
                                Spacer12()
                                Text(polog.routes.isEmpty ? "---" : polog.routes.first!.assetDate.iso8601!.toUnitString(timeZone: TimeZone.current))
                                    .font(.subheadline)
                                    .foregroundColor(Color(UIColor.label))
                            }
                            Spacer12()
                            HStack {
                                Image("IconSpot")
                                    .resizable()
                                    .frame(width: 20, height: 20)
                                Spacer12()
                                Text("東京都、神奈川県") // TODO: 都道府県変換
                                    .font(.subheadline)
                                    .foregroundColor(Color(UIColor.label))
                            }
                            Spacer12()
                            HStack {
                                Image("IconGroupMini")
                                    .resizable()
                                    .frame(width: 20, height: 20)
                                Spacer12()
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack {
                                        ForEach(polog.companions.map { $0.fragments.userOverviewFragment }, id: \.self.id) { user in
                                            Button(action: {
                                                store.send(.presentUserDetailView(user.id))
                                            }) {
                                                HStack(spacing: 2) {
                                                    RemoteImageView(url: user.iconSignedUrl.url, size: CGSize(width: 20, height: 20), isCircle: true)
                                                    Text(user.fullName)
                                                        .font(.footnote)
                                                        .foregroundColor(Color(UIColor.label))
                                                }
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 4)
                                                .background(Capsule().foregroundColor(Color(UIColor.tertiarySystemFill)))
                                            }
                                        }
                                    }
                                }
                            }
                            Spacer12()
                            HStack {
                                Image("IconTag")
                                    .resizable()
                                    .frame(width: 20, height: 20)
                                Spacer12()
                                FlowLayoutView<InputTag>(
                                    items: polog.tags.map { InputTag(value: $0) },
                                    spacing: 4,
                                    itemView: { item in
                                        AnyView(ChipView(
                                            value: "#\(item.value)",
                                            onTap: {},
                                            backgroundColor: Color(UIColor.tertiarySystemFill),
                                            textColor: Color(UIColor.label),
                                            isDeletable: false
                                        ))
                                    }
                                )
                            }
                        }
                            
                        Group {
                            Spacer32()
                            Divider()
                            Spacer32()
                        }
                            
                        IndexListView(store: store)
                            
                        Spacer60()
                            
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                }
            }
        }
    }
}
