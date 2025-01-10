import ComposableArchitecture
import SwiftUI

struct SearchBarView: View {
    @Bindable var store: StoreOf<SearchReducer>

    var body: some View {
        HStack {
            TextField("ユーザーまたは旅行記を検索", text: $store.query.sending(\.setQuery)) { val in
                store.send(.setIsEditingSearchBar(val))
            } onCommit: {
                store.send(.setIsEditingSearchBar(false))
                store.send(.search)
            }
            .submitLabel(.search)
            .padding(7)
            .padding(.horizontal, 25)
            .background(Color(.systemGray6))
            .cornerRadius(8)
            .overlay(
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                        .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, 8)

                    if store.isEditingSearchBar {
                        Button(action: {
                            withAnimation {
                                _ = store.send(.setQuery(""))
                            }
                        }) {
                            Image(systemName: "multiply.circle.fill")
                                .foregroundColor(.gray)
                                .padding(.trailing, 8)
                        }
                    }
                }
            )
            .transition(.move(edge: .trailing))

            if store.isEditingSearchBar || store.isSearching {
                Button(action: {
                    withAnimation {
                        if store.isSearching, store.isEditingSearchBar {
                            _ = store.send(.setIsEditingSearchBar(false))
                        } else if store.isSearching, !store.isEditingSearchBar {
                            _ = store.send(.setIsSearching(false))
                            _ = store.send(.setQuery(""))
                        } else if !store.isSearching, store.isEditingSearchBar {
                            _ = store.send(.setIsEditingSearchBar(false))
                        }
                    }
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }) {
                    Text("キャンセル")
                        .foregroundStyle(Color(.label))
                }
                .padding(.trailing, 10)
            }
        }
    }
}
