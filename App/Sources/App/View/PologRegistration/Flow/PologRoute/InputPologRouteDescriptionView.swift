import ComposableArchitecture
import SwiftUI

extension PologRouteRegistrationView {
    struct InputPologRouteDescriptionView: View {
        @Bindable var store: StoreOf<PologRouteRegistrationReducer>

        @State var value: String

        var body: some View {
            NavigationStack {
                VStack(alignment: .leading) {
                    TextAreaView(
                        maxLength: 1000,
                        placeholder: "コメント",
                        value: $value
                    )
                    .padding(.horizontal, 16)
                }
                .navigationTitle("コメント")
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarItems(leading: Button(action: {
                    store.send(.isPresentedInputDescriptionView(false))
                }) {
                    Text("キャンセル")
                        .foregroundColor(Color(UIColor.label))
                }, trailing: Button(action: {
                    store.send(.setPologRouteDescription(value))
                    store.send(.isPresentedInputDescriptionView(false))
                }) {
                    Text("確定")
                        .foregroundColor(Color(UIColor.label))
                })
                .preferredColorScheme(.dark)
            }
        }
    }
}
