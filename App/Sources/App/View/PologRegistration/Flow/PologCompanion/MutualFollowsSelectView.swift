import ComposableArchitecture
import SwiftUI

extension PologCompanionRegistrationView {
    struct MutualFollowsSelectView: View {
        @Bindable var store: StoreOf<PologCompanionRegistrationReducer>

        var body: some View {
            List {
                ForEach(filteredUsers(users: store.mutualFollows, q: store.query), id: \.id) { item in
                    HStack(spacing: 12) {
                        RemoteImageView(url: item.iconSignedUrl.url, size: CGSize(width: 54, height: 54), isCircle: true)

                        VStack(alignment: .leading) {
                            Text(item.fullName)
                                .font(.body)
                                .foregroundColor(Color(UIColor.label))
                            Text(item.username)
                                .font(.footnote)
                                .foregroundColor(Color(UIColor.secondaryLabel))
                        }

                        Spacer()

                        if store.companions.firstIndex(where: { $0.id == item.id }) != nil {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(Color(UIColor.label))
                        } else {
                            Image(systemName: "circle")
                        }
                    }
                    .listRowSeparator(.hidden)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        store.send(.setInnerCompanion(item))
                    }
                }
            }
            .listStyle(PlainListStyle())
            .scrollContentBackground(.hidden)
            .background(Color(.systemBackground))
        }
    }
}
