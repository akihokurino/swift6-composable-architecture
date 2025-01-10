import ComposableArchitecture
import SwiftUI

public struct ContentView: View {
    public init() {}

    public var body: some View {
        RootView(
            store: Store(initialState: RootReducer.State()) {
                RootReducer()
            }
        )
    }
}
