import SwiftUI

struct SlideTabContent<Content: View>: Identifiable {
    var id: Int
    var title: String
    var inner: Content
}

struct SlideTabView<Content: View>: View {
    var contents: [SlideTabContent<Content>]
    
    @Binding var selection: Int
    @State private var indicatorPosition: CGFloat = 0
    
    var body: some View {
        GeometryReader { geometry in
            let screenWidth = geometry.size.width
            
            VStack(spacing: 0) {
                SlideTabBarView(
                    tabs: contents.map { ($0.id, $0.title) },
                    selection: $selection,
                    indicatorPosition: $indicatorPosition
                )
                .frame(height: 48)
                
                TabView(selection: $selection) {
                    ForEach(contents) { content in
                        content.inner
                            .overlay {
                                GeometryReader { proxy in
                                    Color.clear
                                        .onChange(of: proxy.frame(in: .global)) { newValue in
                                            guard selection == content.id else { return }
                                            
                                            let offset = -(newValue.minX - (screenWidth * CGFloat(selection))) / CGFloat(contents.count)
                                            
                                            if selection == contents.first?.id {
                                                if offset >= 0 {
                                                    indicatorPosition = offset
                                                } else {
                                                    return
                                                }
                                            }
                                            
                                            if selection == contents.last?.id {
                                                if offset + screenWidth / CGFloat(contents.count) <= screenWidth {
                                                    indicatorPosition = offset
                                                } else {
                                                    return
                                                }
                                            }
                                            
                                            indicatorPosition = offset
                                        }
                                }
                            }
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
        }
    }
}

struct SlideTabBarView: View {
    let tabs: [(id: Int, title: String)]
    
    @Binding var selection: Int
    @Binding var indicatorPosition: CGFloat
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                ForEach(tabs, id: \.id) { tab in
                    Button {
                        selection = tab.id
                    } label: {
                        Text(tab.title)
                            .font(.body)
                            .foregroundColor(Color(UIColor.label))
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .padding(8)
                    }
                }
            }
            .overlay(alignment: .bottomLeading) {
                Rectangle()
                    .foregroundColor(Color(UIColor(named: "AccentColor")!))
                    .frame(width: geometry.size.width / CGFloat(tabs.count), height: 4)
                    .offset(x: indicatorPosition, y: 0)
            }
            .onAppear {
                indicatorPosition = geometry.size.width / CGFloat(tabs.count) * CGFloat(selection)
            }
            .onChange(of: selection) { newValue in
                withAnimation(.easeInOut) {
                    indicatorPosition = geometry.size.width / CGFloat(tabs.count) * CGFloat(newValue)
                }
            }
        }
    }
}
