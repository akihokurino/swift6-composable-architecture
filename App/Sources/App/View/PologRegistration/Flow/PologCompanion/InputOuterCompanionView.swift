import ComposableArchitecture
import SwiftUI

extension PologCompanionRegistrationView {
    struct InputOuterCompanionView: View {
        @Bindable var store: StoreOf<PologCompanionRegistrationReducer>

        @State var name: String = ""

        var body: some View {
            NavigationStack {
                VStack(alignment: .leading) {
                    Spacer20()
                    Text("名前")
                        .font(.footnote)
                        .foregroundColor(Color(UIColor.secondaryLabel))
                        .padding(.horizontal, 16)
                        .bold()

                    HStack(spacing: 0) {
                        Spacer16()
                        Image(systemName: "person.crop.circle").font(.largeTitle)
                        Spacer12()
                        TextField("名前を入力", text: $name)
                            .keyboardType(.default)
                            .textFieldStyle(PlainTextFieldStyle())
                            .frame(height: 70)
                            .padding(EdgeInsets(top: 0, leading: 15, bottom: 0, trailing: 15))
                        Spacer16()
                    }
                    .background(Color(UIColor.quaternarySystemFill))
                    .cornerRadius(10)

                    Spacer8()

                    Text("このフォームで追加された同行者の顔写真はアイコンで表示されます")
                        .font(.footnote)
                        .foregroundColor(Color(UIColor.secondaryLabel))
                        .padding(.horizontal, 16)

                    Spacer()
                }
                .background(Color(.systemBackground))
                .padding(.horizontal, 16)
                .navigationTitle("同行者を追加")
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarItems(leading: Button(action: {
                    store.send(.isPresentedInputOuterCompanionView(false))
                }) {
                    Text("キャンセル")
                        .foregroundColor(Color(UIColor.label))
                }, trailing: Button(action: {
                    store.send(.setOuterCompanion(name))
                    store.send(.isPresentedInputOuterCompanionView(false))
                }) {
                    Text("確定")
                        .foregroundColor(Color(UIColor.label))
                }
                .disabled(name.isRealEmpty))
                .colorScheme(.light)
                .toolbarColorScheme(.light, for: .automatic)
            }
        }
    }
}
