import ComposableArchitecture
import SwiftUI

struct PologDetailView: View {
    @Bindable var store: StoreOf<PologDetailReducer>

    var body: some View {
        ContentView(store: store)
            .onAppear {
                store.send(.initialize)
            }
            .background(Color(.systemBackground))
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .navigationBarItems(leading: HStack(spacing: 8) {
                Button(action: {
                    store.send(.dismiss)
                }) {
                    Image(systemName: "xmark")
                        .foregroundColor(Color(UIColor.label))
                }

                RemoteImageView(url: store.polog?.user.iconSignedUrl.url, size: CGSize(width: 32, height: 32), isCircle: true)

                VStack(alignment: .leading, spacing: 2) {
                    Text(store.polog?.title ?? "")
                        .bold()
                        .font(.subheadline)
                        .foregroundColor(Color(UIColor.label))

                    Text(store.polog?.user.fullName ?? "")
                        .font(.caption)
                        .foregroundColor(Color(UIColor.secondaryLabel))
                }

                Spacer()
            }, trailing: Menu {
                if store.isOwner {
                    Button(action: {
                        store.send(.presentPologRegistrationFlowView)
                    }) {
                        Text("編集")
                        Spacer()
                        Image("IconEdit")
                    }
                    Button {} label: {
                        HStack {
                            Text("ストーリー画像書き出し")
                            Spacer()
                            Image("IconExportImg")
                        }
                    }
                    Button(role: .destructive, action: {
                        store.send(.isPresentedDeleteAlert(true))
                    }) {
                        Text("投稿を削除")
                    }
                }
                Button(action: {}) {
                    Text("シェア")
                    Spacer()
                    Image(systemName: "square.and.arrow.up")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .foregroundColor(Color(UIColor.label))
            })
            .modifier(NavigationModifier(store: store))
            .modifier(HUDModifier(isPresented: $store.isPresentedHUD.sending(\.isPresentedHUD)))
            .modifier(AlertModifier(entity: store.alert, onTap: {
                store.send(.isPresentedAlert(false))
            }, isPresented: $store.isPresentedAlert.sending(\.isPresentedAlert)))
            .modifier(CustomAlertModifier(store: store))
            .modifier(ToolbarModifier(store: store))
            .colorScheme(.dark)
            .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

extension PologDetailView {
    struct ContentView: View {
        @Bindable var store: StoreOf<PologDetailReducer>

        var body: some View {
            GeometryReader { geometry in
                let tabViewSize = CGSize(width: geometry.size.width, height: geometry.size.width * (4.0 / 3.0))
                let thumbnailSize = CGSize(width: 40, height: 40 * (4.0 / 3.0))

                if let polog = store.polog {
                    ZStack {
                        TabView(selection: $store.globalSelection.sending(\.setGlobalSelection)) {
                            FirstView(store: store)
                                .frame(maxWidth: .infinity)
                                .tag(0)

                            if polog.forewordHtml?.isNotEmpty ?? false {
                                VStack(spacing: 0) {
                                    Spacer12()

                                    HStack {
                                        Spacer()
                                        Text("まえがき")
                                            .font(.footnote)
                                            .foregroundColor(Color(UIColor.label))
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Capsule().fill(.regularMaterial))
                                        Spacer16()
                                    }

                                    Spacer16()
                                }
                                .padding(.horizontal, 16)
                                .frame(maxWidth: .infinity)
                                .tag(1)
                            }

                            ForEach(polog.routes.indices, id: \.self) { index in
                                let route = polog.routes.map { $0.fragments.pologRouteFragment }[index]
                                VStack(spacing: 0) {
                                    ZStack {
                                        if route.isVideo {
                                            LoopVideoPlayerView(
                                                url: route.assetSignedUrl.url,
                                                size: tabViewSize,
                                                start: Double(route.videoStartSecond ?? 0),
                                                end: Double(route.videoEndSecond ?? 15),
                                                isMuted: route.videoIsMute ?? true,
                                                isPlaying: Binding(
                                                    get: { store.pologRouteState[route.id]?.isVideoPlaying ?? false },
                                                    set: { newValue in
                                                        _ = PologDetailReducer.Action.setVideoIsPlaying((route, newValue))
                                                    }
                                                )
                                            )
                                        } else {
                                            RemoteImageView(url: route.assetSignedUrl.url, size: tabViewSize, scaleType: .fit)
                                        }

                                        if let state = store.pologRouteState[route.id], state.isTruncated, let description = route.description, !description.isEmpty {
                                            VStack(alignment: .leading) {
                                                Spacer()

                                                Group {
                                                    TrancatedTextView(
                                                        route.description ?? "",
                                                        lineLimit: 2,
                                                        padding: 16,
                                                        ellipsis: .init(text: "続きをみる", color: Color(UIColor.label)),
                                                        onTapEllipsis: { truncated in
                                                            store.send(.setTruncated((route, !truncated)))
                                                        }
                                                    )
                                                    .padding(16)
                                                    .frame(maxWidth: .infinity, alignment: .leading)
                                                }
                                                .background(.black.opacity(0.48))
                                            }
                                            .frame(height: tabViewSize.height)
                                            .frame(maxWidth: .infinity)
                                        } else if let description = route.description, !description.isEmpty {
                                            VStack(alignment: .leading) {
                                                Text(description)
                                                    .frame(maxWidth: .infinity, alignment: .leading)
                                                    .padding(16)

                                                Spacer()
                                            }
                                            .frame(height: tabViewSize.height)
                                            .frame(maxWidth: .infinity)
                                            .background(.black.opacity(0.48))
                                            .onTapGesture {
                                                store.send(.setTruncated((route, true)))
                                            }
                                        }

                                        Button(action: {
                                            store.send(.isPresentedTabViewer(true))
                                        }) {
                                            Rectangle()
                                                .frame(width: 50, height: 50)
                                                .foregroundColor(.clear)
                                        }
                                    }
                                    .frame(height: tabViewSize.height)

                                    Spacer()
                                }
                                .tag(index + store.routeSelectionOffset)
                            }

                            if polog.afterwordHtml?.isNotEmpty ?? false {
                                VStack(spacing: 0) {
                                    Spacer12()

                                    HStack {
                                        Spacer()
                                        Text("あとがき")
                                            .font(.footnote)
                                            .foregroundColor(Color(UIColor.label))
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Capsule().fill(.regularMaterial))
                                        Spacer16()
                                    }

                                    Spacer16()
                                }
                                .padding(.horizontal, 16)
                                .frame(maxWidth: .infinity)
                                .tag(polog.routes.count + store.routeSelectionOffset)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))

                        if let route = store.currentRoute, let selection = store.routeSelection {
                            VStack(spacing: 0) {
                                Spacer16()

                                if let state = store.pologRouteState[route.id], state.isTruncated {
                                    HStack {
                                        Spacer()
                                        HStack {
                                            if route.isIncludeIndex {
                                                Image(systemName: "bookmark.fill")
                                                    .foregroundColor(.white)
                                                    .font(.footnote)
                                                Spacer4()
                                            }
                                            Text("\(selection + 1) / \(polog.routes.count)")
                                                .font(.footnote)
                                                .foregroundColor(.white)
                                        }
                                        .padding(.vertical, 4)
                                        .padding(.horizontal, 12)
                                        .background(RoundedRectangle(cornerRadius: .infinity).fill(.regularMaterial))
                                        .foregroundColor(.white)

                                        Spacer16()
                                    }
                                }

                                Spacer()
                            }

                            VStack(spacing: 0) {
                                Spacer().frame(height: tabViewSize.height)

                                Spacer12()

                                HStack {
                                    Spacer16()

                                    VStack(alignment: .leading) {
                                        Text(route.assetDate.iso8601?.dateTimeDisplayJST ?? "")
                                            .font(.footnote)
                                            .foregroundColor(Color(UIColor.secondaryLabel))

                                        if route.isIncludeIndex {
                                            Text(route.spot?.name ?? "")
                                                .font(.footnote)
                                                .foregroundColor(Color(UIColor.label))
                                        }
                                    }

                                    Spacer()

                                    let iconSize = CGSize(width: 35, height: 35)
                                    Button(action: {}) {
                                        Image("IconFlag")
                                            .resizable()
                                            .frame(width: 20, height: 20)
                                            .foregroundColor(.white)
                                            .background(Circle().fill(.regularMaterial).frame(width: iconSize.width, height: iconSize.height))
                                    }
                                    .frame(width: iconSize.width, height: iconSize.height)

                                    Spacer16()
                                }

                                Spacer()
                            }
                        }

                        VStack(spacing: 0) {
                            Spacer()

                            Divider()

                            ScrollViewReader { proxy in
                                ScrollView(.horizontal, showsIndicators: false) {
                                    let horizontalPadding = (geometry.size.width / 2) - (thumbnailSize.width / 2) - thumbnailSize.width

                                    HStack(spacing: 0) {
                                        Spacer(minLength: horizontalPadding)

                                        VStack {
                                            Spacer()
                                            HStack {
                                                Spacer()
                                                Image("IconGuide")
                                                Spacer()
                                            }
                                            Spacer()
                                        }
                                        .frame(width: thumbnailSize.width, height: thumbnailSize.height)
                                        .background(Color(.systemFill))
                                        .onTapGesture {
                                            print("test \(thumbnailSize.height)")
                                            store.send(.setGlobalSelection(0))
                                        }
                                        .applyId(id: 0)

                                        if polog.forewordHtml?.isNotEmpty ?? false {
                                            VStack {
                                                Spacer()
                                                HStack {
                                                    Spacer()
                                                    Image("IconDocument")
                                                    Spacer()
                                                }
                                                Spacer()
                                            }
                                            .frame(width: thumbnailSize.width, height: thumbnailSize.height)
                                            .background(Color(.systemFill))
                                            .onTapGesture {
                                                store.send(.setGlobalSelection(1))
                                            }
                                            .applyId(id: 1)
                                        }

                                        ForEach(polog.routes.indices, id: \.self) { index in
                                            let route = polog.routes.map { $0.fragments.pologRouteFragment }[index]
                                            let selected = store.globalSelection == index + store.routeSelectionOffset

                                            ZStack {
                                                HStack {
                                                    Spacer()
                                                    RemoteImageView(url: route.thumbnailURL, size: thumbnailSize)
                                                    Spacer()
                                                }

                                                if route.isIncludeIndex {
                                                    VStack {
                                                        HStack {
                                                            Spacer10()
                                                            Image(systemName: "bookmark.fill")
                                                                .resizable()
                                                                .frame(width: 10, height: 15)
                                                                .scaledToFit()

                                                            Spacer()
                                                        }
                                                        .padding(.top, 3)

                                                        Spacer()
                                                    }
                                                }
                                            }
                                            .frame(width: thumbnailSize.width + (selected ? 16 : 0), height: thumbnailSize.height)
                                            .clipped()
                                            .contentShape(Rectangle())
                                            .onTapGesture {
                                                store.send(.setGlobalSelection(index + store.routeSelectionOffset))
                                            }
                                            .id(index + store.routeSelectionOffset)
                                        }

                                        if polog.afterwordHtml?.isNotEmpty ?? false {
                                            VStack {
                                                Spacer()
                                                HStack {
                                                    Spacer()
                                                    Image("IconDocument")
                                                    Spacer()
                                                }
                                                Spacer()
                                            }
                                            .frame(width: thumbnailSize.width, height: thumbnailSize.height)
                                            .background(Color(.systemFill))
                                            .onTapGesture {
                                                store.send(.setGlobalSelection(polog.routes.count + store.routeSelectionOffset))
                                            }
                                            .applyId(id: polog.routes.count + store.routeSelectionOffset)
                                        }

                                        Spacer(minLength: horizontalPadding)
                                    }
                                }
                                .onChange(of: store.globalSelection) { newValue in
                                    proxy.scrollTo(newValue, anchor: .center)
                                }
                                .background(Color(UIColor.systemBackground))
                            }
                            .frame(height: thumbnailSize.height + 1)
                        }
                    }
                    .fullScreenCover(isPresented: $store.isPresentedTabViewer.sending(\.isPresentedTabViewer), content: {
                        NavigationStack {
                            GeometryReader(content: { proxy in
                                TabViewer<PologRoute>(
                                    items: polog.routes.map { $0.fragments.pologRouteFragment },
                                    current: store.currentRoute,
                                    controlingToolbars: [.navigationBar, .tabBar],
                                    isFullScreen: true,
                                    isFullScreenAlways: true,
                                    itemView: { item, _ in
                                        AnyView(Group {
                                            if item.isVideo {
                                                LoopVideoPlayerView(url: item.assetSignedUrl.url, size: proxy.size, suppressLoop: true, isShowControl: false, autoHeight: true)
                                                    .ignoresSafeArea()
                                            } else {
                                                GeometryReader { g in
                                                    Group {
                                                        ZoomableScrollView {
                                                            RemoteImageView(
                                                                url: item.assetSignedUrl.url,
                                                                size: proxy.size,
                                                                scaleType: .fit,
                                                                autoHeight: true
                                                            )
                                                            .ignoresSafeArea()
                                                        }
                                                    }
                                                    .position(x: g.frame(in: .local).midX, y: g.frame(in: .local).midY)
                                                }
                                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                            }
                                        })
                                    },
                                    onChangeIndex: { _, item in
                                        store.send(.movePologRoute(item))
                                    }
                                ) { _ in
                                    store.send(.isPresentedTabViewer(false))
                                }
                            })
                        }
                    })
                    .transaction { transaction in
                        transaction.disablesAnimations = true
                    }
                }
            }
        }
    }
}

extension PologDetailView {
    struct NavigationModifier: ViewModifier {
        @Bindable var store: StoreOf<PologDetailReducer>

        func body(content: Content) -> some View {
            WithViewStore(store, observe: { $0 }) { _ in
                content
                    .sheet(isPresented: $store.isPresentedIndexView.sending(\.isPresentedIndexView)) {
                        IndexView(store: store)
                    }
                    .navigationDestination(
                        item: $store.scope(state: \.destination?.userDetail, action: \.destination.userDetail)
                    ) { store in
                        UserDetailView(store: store)
                    }
                    .sheet(
                        item: $store.scope(state: \.destination?.commentList, action: \.destination.commentList)
                    ) { store in
                        PologCommentListView(store: store)
                    }
                    .fullScreenCover(
                        item: $store.scope(state: \.destination?.pologRegistrationFlow, action: \.destination.pologRegistrationFlow)
                    ) { store in
                        NavigationStack {
                            PologRegistrationFlowView(store: store)
                        }
                    }
            }
        }
    }
}

extension PologDetailView {
    struct CustomAlertModifier: ViewModifier {
        @Bindable var store: StoreOf<PologDetailReducer>

        func body(content: Content) -> some View {
            content
                .alert(
                    "投稿を削除しますか",
                    isPresented: $store.isPresentedDeleteAlert.sending(\.isPresentedDeleteAlert)
                ) {
                    HStack {
                        Button("キャンセル", role: .cancel) {
                            store.send(.isPresentedDeleteAlert(false))
                        }
                        Button("削除する", role: .destructive) {
                            store.send(.delete)
                        }
                    }
                } message: {}
        }
    }
}

extension PologDetailView {
    struct ToolbarModifier: ViewModifier {
        @Bindable var store: StoreOf<PologDetailReducer>

        func body(content: Content) -> some View {
            content
                .toolbar {
                    ToolbarItemGroup(placement: .bottomBar) {
                        HStack(spacing: 0) {
                            Button(action: {
                                store.send(.toggleLike)
                            }) {
                                HStack(spacing: 4) {
                                    Image(store.polog?.isLiked ?? false ? "IconHeartFill" : "IconHeart")
                                        .font(.footnote)
                                        .foregroundColor(store.polog?.isLiked ?? false ? .white : Color(UIColor.secondaryLabel))
                                    Text("\(store.polog?.likeCount ?? 0)")
                                        .font(.footnote)
                                        .foregroundColor(Color(UIColor.secondaryLabel))
                                }
                            }
                            .disabled(store.isOwner)

                            Spacer24()

                            Button(action: {
                                store.send(.toggleClip)
                            }) {
                                HStack(spacing: 4) {
                                    Image("IconClip")
                                        .font(.footnote)
                                        .foregroundColor(store.polog?.isClipped ?? false ? .white : Color(UIColor.secondaryLabel))
                                    Text("\(store.polog?.clipCount ?? 0)")
                                        .font(.footnote)
                                        .foregroundColor(Color(UIColor.secondaryLabel))
                                }
                            }
                            .disabled(store.isOwner)

                            Spacer24()

                            Button(action: {
                                store.send(.presentCommentListView)
                            }) {
                                HStack(spacing: 4) {
                                    Image("IconComment")
                                        .font(.footnote)
                                        .foregroundColor(Color(UIColor.secondaryLabel))
                                    Text("\(store.polog?.commentCount ?? 0)")
                                        .font(.footnote)
                                        .foregroundColor(Color(UIColor.secondaryLabel))
                                }
                            }

                            Spacer()
                        }
                    }

                    ToolbarItemGroup(placement: .bottomBar) {
                        HStack(spacing: 0) {
                            Spacer()
                            Button(action: {
                                store.send(.isPresentedIndexView(true))
                            }) {
                                Image("IconList")
                                    .font(.footnote)
                                    .foregroundColor(Color(UIColor.secondaryLabel))
                            }
                            Spacer24()
                            Button(action: {}) {
                                Image("IconMap")
                                    .font(.footnote)
                                    .foregroundColor(Color(UIColor.secondaryLabel))
                            }
                        }
                    }
                }
        }
    }
}
