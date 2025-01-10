import ComposableArchitecture
import SwiftUI

struct GroupView: View {
    @Bindable var store: StoreOf<GroupReducer>

    var body: some View {
        ContentView(store: store)
            .onAppear {
                store.send(.initialize)
            }
            .modifier(HUDModifier(isPresented: $store.isPresentedHUD.sending(\.isPresentedHUD)))
            .modifier(AlertModifier(entity: store.alert, onTap: {
                store.send(.isPresentedAlert(false))
            }, isPresented: $store.isPresentedAlert.sending(\.isPresentedAlert)))
    }
}

extension GroupView {
    struct ContentView: View {
        @Bindable var store: StoreOf<GroupReducer>

        var body: some View {
            VStack {
                Text("Group")
            }
            .padding(.horizontal, 16)
        }
    }
}
