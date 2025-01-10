import ComposableArchitecture
import SwiftUI

struct PologRegistrationFlowView: View {
    @Bindable var store: StoreOf<PologRegistrationFlowReducer>

    var body: some View {
        Group {
            if let embeded = store.scope(state: \.embededEntrypoint, action: \.embededEntrypoint) {
                PologRouteRegistrationView(store: embeded)
            }
        }
        .onAppear {
            store.send(.initialize)
        }
        .modifier(HUDModifier(isPresented: $store.isPresentedHUD.sending(\.isPresentedHUD)))
        .modifier(AlertModifier(entity: store.alert, onTap: {
            store.send(.isPresentedAlert(false))
        }, isPresented: $store.isPresentedAlert.sending(\.isPresentedAlert)))
    }
}
