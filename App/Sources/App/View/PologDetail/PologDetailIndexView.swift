import ComposableArchitecture
import SwiftUI

extension PologDetailView {
    struct IndexView: View {
        @Bindable var store: StoreOf<PologDetailReducer>

        var body: some View {
            VStack(spacing: 0) {
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
                            .background(Circle().fill(Color(UIColor.secondarySystemFill)).frame(width: 30, height: 30))
                    }
                }
                .padding(.horizontal, 16)
                Spacer16()

                if let polog = store.polog {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 0) {
                            Spacer16()
                            Text(polog.title)
                                .bold()
                                .font(.title3)
                                .foregroundColor(Color(UIColor.label))
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Spacer16()
                            HStack {
                                Image("IconCalender")
                                    .resizable()
                                    .frame(width: 20, height: 20)
                                Spacer12()
                                Text(polog.routes.isEmpty ? "---" : polog.routes.first!.assetDate.iso8601!.toUnitString(timeZone: TimeZone.current))
                                    .font(.subheadline)
                                    .foregroundColor(Color(UIColor.label))
                            }

                            Spacer32()

                            IndexListView(store: store)
                        }
                        .padding(.horizontal, 16)
                    }
                }
            }
            .preferredColorScheme(.dark)
        }
    }
}
