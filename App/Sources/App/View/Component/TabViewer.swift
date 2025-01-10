import SwiftUI

struct TabViewer<T: Identifiable & Hashable>: View {
    let items: [T]
    let controlingToolbars: [ToolbarPlacement]
    let isSelectable: Bool
    let isFullScreenAlways: Bool
    let itemView: (T, _ isFullScreen: Bool) -> AnyView
    let onChangeIndex: (_ index: Int, _ item: T) -> Void
    let onClose: (_ selectedItems: Set<T>) -> Void

    @State private var index: Int
    @State private var isFullScreen = false
    @State private var selectedItems: Set<T>

    init(items: [T],
         current: T?,
         controlingToolbars: [ToolbarPlacement] = [],
         isFullScreen: Bool = false,
         isFullScreenAlways: Bool = false,
         isSelectable: Bool = false,
         selectedItems: Set<T> = Set(),
         itemView: @escaping (T, _ isFullScreen: Bool) -> AnyView,
         onChangeIndex: @escaping (_ index: Int, _ item: T) -> Void,
         onClose: @escaping (_ selectedItems: Set<T>) -> Void)
    {
        self.items = items
        self.index = items.firstIndex(where: { $0.id == current?.id }) ?? 0
        self.controlingToolbars = controlingToolbars
        self.isFullScreen = isFullScreen
        self.isFullScreenAlways = isFullScreenAlways
        self.isSelectable = isSelectable
        self.selectedItems = selectedItems
        self.itemView = itemView
        self.onChangeIndex = onChangeIndex
        self.onClose = onClose

        if isFullScreenAlways {
            self.isFullScreen = true
        }
    }

    var currentItem: T {
        return items[index]
    }

    var body: some View {
        ZStack {
            ZStack {
                Color(UIColor.systemBackground)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .ignoresSafeArea()

                TabView(selection: $index) {
                    ForEach(Array(items.enumerated()), id: \.element.id) { i, item in
                        itemView(item, isFullScreen)
                            .ignoresSafeArea()
                            .tag(i)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .gesture(tapGesture)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea()

            ForEach(controlingToolbars) {
                if !isFullScreen {
                    if $0.id == ToolbarPlacement.navigationBar.id {
                        Color.clear
                            .toolbarBackground(.visible, for: .navigationBar)
                    } else if $0.id == ToolbarPlacement.tabBar.id {
                        Color.clear
                            .toolbarBackground(.visible, for: .tabBar)
                    }
                }

                Color.clear
                    .toolbar(isFullScreen ? .hidden : .visible, for: $0)
            }
        }
        .statusBar(hidden: isFullScreen)
        .colorScheme(.dark)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .navigationBarItems(leading: Group {
            Button(action: {
                onChangeIndex(index, items[index])
                onClose(selectedItems)
            }) {
                Image(systemName: "xmark").foregroundColor(Color(UIColor.label))
            }
        }, trailing: Group {
            if isSelectable {
                if selectedItems.contains(currentItem) {
                    Button(action: {
                        selectedItems.remove(currentItem)
                    }) {
                        HStack {
                            Text("選択済み").foregroundColor(Color(UIColor.label)).font(.body)
                            Spacer4()
                            Image(systemName: "checkmark.circle.fill")
                                .resizable()
                                .frame(width: 25, height: 25)
                                .clipShape(Circle())
                                .foregroundColor(.white)
                        }
                    }
                    .foregroundColor(Color.clear)
                } else {
                    Button(action: {
                        selectedItems.insert(currentItem)
                    }) {
                        HStack {
                            Text("選択").foregroundColor(Color(UIColor.label)).font(.body)
                            Spacer4()
                            Circle()
                                .frame(width: 25, height: 25)
                                .clipShape(Circle())
                                .overlay(
                                    Circle().stroke(Color.white, lineWidth: 2)
                                )
                        }
                    }
                    .foregroundColor(Color.clear)
                }
            }
        })
    }

    var tapGesture: some Gesture {
        TapGesture(count: 1)
            .onEnded {
                if isFullScreen && isFullScreenAlways {
                    onChangeIndex(index, items[index])
                    onClose(selectedItems)
                } else {
                    withAnimation(.easeOut(duration: 0.2)) {
                        isFullScreen.toggle()
                    }
                }
            }
    }
}

extension ToolbarPlacement: @retroactive Identifiable {
    public var id: String {
        "\(self)"
    }
}
