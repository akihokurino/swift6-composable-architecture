import ComposableArchitecture
import SwiftUI

extension PologCompanionRegistrationView {
    struct GroupMemberSelectView: View {
        @Bindable var store: StoreOf<PologCompanionRegistrationReducer>

        @State private var isExpanded: [String: Bool] = [:]

        var body: some View {
            ScrollView {
                ForEach(store.groups, id: \.id) { item in
                    DisclosureGroup(isExpanded: Binding<Bool>(
                        get: {
                            self.isExpanded[item.id, default: false]
                        },
                        set: { newValue in
                            self.isExpanded[item.id] = newValue
                        }
                    )) {
                        VStack(alignment: .leading) {
                            ForEach(filteredUsers(users: item.members.map { $0.fragments.userOverviewFragment }, q: store.query), id: \.id) { item in
                                HStack {
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
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    store.send(.setInnerCompanion(item))
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                    } label: {
                        VStack {
                            Text("\(item.name) (\(item.members.count))")
                                .font(.body)
                                .bold()
                                .foregroundColor(Color(UIColor.label))
                        }
                        .padding(.horizontal, 16)
                        .frame(height: 50)
                    }
                    .disclosureGroupStyle(DisclosureStyle())
                    .onTapGesture {
                        withAnimation {
                            let current = self.isExpanded[item.id, default: false]
                            self.isExpanded[item.id] = !current
                        }
                    }
                }
            }
            .listStyle(PlainListStyle())
        }
    }
}
