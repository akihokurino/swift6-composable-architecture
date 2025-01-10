import ComposableArchitecture
import SwiftUI

struct PologRouteRegistrationView: View {
    @Bindable var store: StoreOf<PologRouteRegistrationReducer>

    var body: some View {
        ContentView(store: store)
            .onAppear {
                store.send(.initialize)
            }
            .background(Color(.systemBackground))
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(leading: Button(action: {
                store.send(.presentCloseMenuActionSheet)
            }) {
                Image(systemName: "xmark")
                    .foregroundColor(Color(UIColor.label))
            }, trailing: Button(action: {
                store.send(.presentIndexRegistrationView)
            }) {
                Text("次へ")
                    .foregroundColor(Color(UIColor.label))
            })
            .modifier(NavigationModifier(store: store))
            .modifier(ActionSheetModifier(store: store))
            .modifier(ToolbarModifier(store: store))
            .modifier(HUDModifier(isPresented: $store.isPresentedHUD.sending(\.isPresentedHUD)))
            .modifier(AlertModifier(entity: store.alert, onTap: {
                store.send(.isPresentedAlert(false))
            }, isPresented: $store.isPresentedAlert.sending(\.isPresentedAlert)))
            .colorScheme(.dark)
            .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

extension PologRouteRegistrationView {
    struct ContentView: View {
        @Bindable var store: StoreOf<PologRouteRegistrationReducer>

        var body: some View {
            GeometryReader { geometry in
                let tabViewSize = CGSize(width: geometry.size.width, height: geometry.size.width * (4.0 / 3.0))
                let thumbnailSize = CGSize(width: 40, height: 40 * (4.0 / 3.0))
                let actionAreaSize = CGSize(width: geometry.size.width, height: 60)
                let tabViewAndActionAreaHeight = tabViewSize.height + actionAreaSize.height
                let contentHeight = tabViewAndActionAreaHeight + thumbnailSize.height

                ZStack {
                    VStack(alignment: .leading, spacing: 0) {
                        TabView(selection: $store.globalSelection.sending(\.setGlobalSelection)) {
                            if store.isPresentedForewordHtmlInputView {
                                VStack(spacing: 0) {
                                    VStack {
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
                                    GeometryReader { _ in
                                    }
                                }
                                .tag(0)
                            }

                            ForEach(store.inputPolog.routes.indices, id: \.self) { index in
                                VStack(spacing: 0) {
                                    ZStack {
                                        if store.inputPolog.routes[index].asset.isVideo {
                                            Group {
                                                switch store.inputPolog.routes[index].asset {
                                                case .localAsset(let asset):
                                                    LoopVideoPlayerView(
                                                        asset: asset,
                                                        size: tabViewSize,
                                                        start: store.inputPolog.routes[index].videoStartSeconds,
                                                        end: store.inputPolog.routes[index].videoEndSeconds,
                                                        isMuted: store.inputPolog.routes[index].isVideoMuted,
                                                        isPlaying: $store.inputPolog.routes[index].isVideoPlaying.sending(\.setPologRouteVideoIsPlaying)
                                                    )
                                                case .remoteAsset(let asset):
                                                    LoopVideoPlayerView(
                                                        url: asset.url,
                                                        size: tabViewSize,
                                                        start: store.inputPolog.routes[index].videoStartSeconds,
                                                        end: store.inputPolog.routes[index].videoEndSeconds,
                                                        isMuted: store.inputPolog.routes[index].isVideoMuted,
                                                        isPlaying: $store.inputPolog.routes[index].isVideoPlaying.sending(\.setPologRouteVideoIsPlaying)
                                                    )
                                                }
                                            }
                                        } else {
                                            Group {
                                                switch store.inputPolog.routes[index].asset {
                                                case .localAsset(let asset):
                                                    LocalImageView(asset: asset, size: tabViewSize, scaleType: .fit)
                                                case .remoteAsset(let asset):
                                                    RemoteImageView(url: asset.thumbnailUrl, size: tabViewSize, scaleType: .fit)
                                                }
                                            }
                                        }

                                        VStack {
                                            Spacer()

                                            HStack {
                                                if store.inputPolog.routes[index].description.isEmpty {
                                                    Button(action: {
                                                        store.send(.isPresentedInputDescriptionView(true))
                                                    }) {
                                                        Text("コメントを入力")
                                                            .font(.callout)
                                                            .foregroundColor(Color(UIColor.label))
                                                    }
                                                } else {
                                                    if !store.isPresentedInputDescriptionView {
                                                        TrancatedTextView(
                                                            store.inputPolog.routes[index].description,
                                                            lineLimit: 2,
                                                            padding: 16,
                                                            ellipsis: .init(text: "続きをみる", color: Color(UIColor.label)),
                                                            onTapEllipsis: { _ in
                                                                store.send(.isPresentedInputDescriptionView(true))
                                                            }
                                                        )
                                                        .frame(maxWidth: .infinity, alignment: .leading)
                                                    }
                                                }

                                                Spacer()
                                            }

                                            Spacer16()
                                        }
                                        .padding(.horizontal, 16)

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

                            if store.isPresentedAfterwordHtmlInputView {
                                VStack {
                                    VStack {
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
                                }
                                .tag(store.inputPolog.routes.count + store.routeSelectionOffset)
                            }
                        }
                        .frame(width: tabViewSize.width, height: tabViewAndActionAreaHeight)
                        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))

                        ScrollViewReader { proxy in
                            ScrollView(.horizontal, showsIndicators: false) {
                                let horizontalPadding = (geometry.size.width / 2) - (thumbnailSize.width / 2) - thumbnailSize.width

                                HStack(spacing: 0) {
                                    Spacer(minLength: horizontalPadding)

                                    VStack {
                                        Spacer()
                                        HStack {
                                            Spacer()
                                            if !store.isPresentedForewordHtmlInputView {
                                                Image("IconPenAdd")
                                            } else {
                                                Image("IconDocument")
                                            }
                                            Spacer()
                                        }
                                        Spacer()
                                    }
                                    .frame(width: thumbnailSize.width, height: thumbnailSize.height)
                                    .background(Color(UIColor.systemFill))
                                    .onTapGesture {
                                        if !store.isPresentedForewordHtmlInputView {
                                            store.send(.presentAddForewordHtmlActionSheet)
                                        } else {
                                            store.send(.setGlobalSelection(0))
                                        }
                                    }
                                    .applyId(id: store.isPresentedForewordHtmlInputView ? 0 : nil)

                                    ForEach(store.inputPolog.routes.indices, id: \.self) { index in
                                        let selected = store.globalSelection == index + store.routeSelectionOffset

                                        ZStack {
                                            HStack {
                                                Spacer()

                                                switch store.inputPolog.routes[index].asset {
                                                case .localAsset(let asset):
                                                    LocalImageView(asset: asset, size: thumbnailSize)
                                                case .remoteAsset(let asset):
                                                    RemoteImageView(url: asset.thumbnailUrl, size: thumbnailSize)
                                                }

                                                Spacer()
                                            }
                                            .id(store.inputPolog.idForViewRendering)

                                            if store.inputPolog.routes[index].isIncludeIndex {
                                                HStack {
                                                    Spacer()

                                                    VStack {
                                                        Spacer4()
                                                        HStack {
                                                            Spacer4()
                                                            Image(systemName: "bookmark.fill")
                                                                .resizable()
                                                                .frame(width: 10, height: 15)
                                                                .scaledToFit()

                                                            Spacer()
                                                        }

                                                        Spacer()
                                                    }
                                                    .frame(width: thumbnailSize.width, height: thumbnailSize.height)

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

                                    VStack {
                                        Spacer()
                                        HStack {
                                            Spacer()
                                            if !store.isPresentedAfterwordHtmlInputView {
                                                Image("IconPenAdd")
                                            } else {
                                                Image("IconDocument")
                                            }
                                            Spacer()
                                        }
                                        Spacer()
                                    }
                                    .frame(width: thumbnailSize.width, height: thumbnailSize.height)
                                    .background(Color(UIColor.systemFill))
                                    .onTapGesture {
                                        if !store.isPresentedAfterwordHtmlInputView {
                                            store.send(.presentAddAfterwordHtmlActionSheet)
                                        } else {
                                            store.send(.setGlobalSelection(store.inputPolog.routes.count + store.routeSelectionOffset))
                                        }
                                    }
                                    .applyId(id: store.isPresentedAfterwordHtmlInputView ? store.inputPolog.routes.count + store.routeSelectionOffset : nil)

                                    Spacer(minLength: horizontalPadding)
                                }
                            }
                            .onChange(of: store.globalSelection) { newValue in
                                proxy.scrollTo(newValue, anchor: .center)
                            }
                        }
                        .frame(height: thumbnailSize.height)
                    }

                    if let input = store.currentRoute, let selection = store.routeSelection {
                        VStack(spacing: 0) {
                            Spacer16()

                            HStack {
                                Spacer()
                                HStack {
                                    if input.isIncludeIndex {
                                        Image(systemName: "bookmark.fill")
                                            .foregroundColor(.white)
                                            .font(.footnote)
                                        Spacer4()
                                    }
                                    Text("\(selection + 1) / \(store.inputPolog.routes.count)")
                                        .font(.footnote)
                                        .foregroundColor(.white)
                                }
                                .padding(.vertical, 4)
                                .padding(.horizontal, 12)
                                .background(RoundedRectangle(cornerRadius: .infinity).fill(.regularMaterial))
                                .foregroundColor(.white)

                                Spacer16()
                            }

                            Spacer()
                        }

                        VStack(spacing: 0) {
                            Spacer()

                            VStack(spacing: 0) {
                                HStack {
                                    Button(action: {
                                        store.send(.isPresentedInputSpotView(true))
                                    }) {
                                        VStack(alignment: .leading) {
                                            Text(input.assetDate.dateTimeDisplayJST)
                                                .font(.footnote)
                                                .foregroundColor(Color(UIColor.secondaryLabel))
                                            Text("スポットを指定")
                                                .font(.footnote)
                                                .foregroundColor(Color(UIColor.label))
                                        }
                                    }
                                    Spacer()

                                    let iconSize = CGSize(width: 35, height: 35)

                                    if input.asset.isVideo {
                                        Button(action: {
                                            store.send(.presentVideoTrimmerView(input))
                                        }) {
                                            Image("IconMovieEdit")
                                                .foregroundColor(.white)
                                                .background(Circle().fill(Color(UIColor.systemFill)).frame(width: iconSize.width, height: iconSize.height))
                                        }
                                        .frame(width: iconSize.width, height: iconSize.height)

                                        Spacer8()
                                    }

                                    Button(action: {
                                        store.send(.indexPologRoute)
                                    }) {
                                        if input.isIncludeIndex {
                                            Image("IconBookmarkAdded")
                                                .foregroundColor(.white)
                                                .background(Circle().fill(Color(UIColor.systemFill)).frame(width: iconSize.width, height: iconSize.height))
                                        } else {
                                            Image("IconBookmarkAdd")
                                                .foregroundColor(.white)
                                                .background(Circle().fill(Color(UIColor.systemFill)).frame(width: iconSize.width, height: iconSize.height))
                                        }
                                    }
                                    .frame(width: iconSize.width, height: iconSize.height)

                                    Spacer8()

                                    Button(action: {
                                        store.send(.presentDeleteAssetActionSheet)
                                    }) {
                                        Image("IconDelete")
                                            .foregroundColor(.white)
                                            .background(Circle().fill(Color(UIColor.systemFill)).frame(width: iconSize.width, height: iconSize.height))
                                    }
                                    .frame(width: iconSize.width, height: iconSize.height)
                                }
                                .padding(.horizontal, 16)
                            }
                            .frame(height: actionAreaSize.height)

                            Spacer().frame(height: thumbnailSize.height)
                        }
                    }
                }
                .frame(height: contentHeight)
                .fullScreenCover(isPresented: $store.isPresentedTabViewer.sending(\.isPresentedTabViewer), content: {
                    NavigationStack {
                        GeometryReader(content: { proxy in
                            TabViewer<InputPologRoute>(
                                items: store.inputPolog.routes,
                                current: store.currentRoute,
                                controlingToolbars: [.navigationBar, .tabBar],
                                isFullScreen: true,
                                isFullScreenAlways: true,
                                itemView: { item, _ in
                                    AnyView(Group {
                                        switch item.asset {
                                        case .localAsset(let asset):
                                            if asset.isVideo {
                                                LoopVideoPlayerView(asset: asset, size: proxy.size, suppressLoop: true, isShowControl: false, autoHeight: true)
                                                    .ignoresSafeArea()
                                            } else {
                                                GeometryReader { g in
                                                    Group {
                                                        ZoomableScrollView {
                                                            LocalImageView(asset: asset, size: proxy.size, autoHeight: true)
                                                                .ignoresSafeArea()
                                                        }
                                                    }
                                                    .position(x: g.frame(in: .local).midX, y: g.frame(in: .local).midY)
                                                }
                                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                            }
                                        case .remoteAsset(let asset):
                                            if asset.isVideo {
                                                LoopVideoPlayerView(url: asset.url, size: proxy.size, suppressLoop: true, isShowControl: false, autoHeight: true)
                                                    .ignoresSafeArea()
                                            } else {
                                                GeometryReader { g in
                                                    Group {
                                                        ZoomableScrollView {
                                                            RemoteImageView(
                                                                url: asset.url,
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

extension PologRouteRegistrationView {
    struct NavigationModifier: ViewModifier {
        @Bindable var store: StoreOf<PologRouteRegistrationReducer>

        func body(content: Content) -> some View {
            WithViewStore(store, observe: { $0 }) { _ in
                content
                    .sheet(isPresented: $store.isPresentedInputDescriptionView.sending(\.isPresentedInputDescriptionView)) {
                        InputPologRouteDescriptionView(store: store, value: store.currentRoute!.description)
                    }
                    .sheet(isPresented: $store.isPresentedInputSpotView.sending(\.isPresentedInputSpotView)) {
                        InputPologRouteSpotView(store: store, value: store.currentRoute!.assetDate)
                            .presentationDetents([.medium])
                    }
                    .sheet(isPresented: $store.isPresentedIndexView.sending(\.isPresentedIndexView)) {
                        IndexView(store: store)
                    }
                    .sheet(
                        item: $store.scope(state: \.destination?.assetSelect, action: \.destination.assetSelect)
                    ) { store in
                        NavigationStack {
                            AssetSelectView(store: store)
                        }
                    }
                    .sheet(
                        item: $store.scope(state: \.destination?.videoTrimmer, action: \.destination.videoTrimmer)
                    ) { store in
                        NavigationStack {
                            PologRouteVideoTrimmerView(store: store)
                        }
                    }
                    .navigationDestination(
                        item: $store.scope(state: \.destination?.indexRegistration, action: \.destination.indexRegistration)
                    ) { store in
                        PologRouteIndexRegistrationView(store: store)
                    }
            }
        }
    }
}

extension PologRouteRegistrationView {
    struct ActionSheetModifier: ViewModifier {
        @Bindable var store: StoreOf<PologRouteRegistrationReducer>

        func body(content: Content) -> some View {
            content
                .actionSheet(isPresented: $store.isPresentedActionSheet.sending(\.isPresentedActionSheet)) {
                    switch store.actionSheetType {
                    case .deleteAsset:
                        return ActionSheet(
                            title: Text(""),
                            buttons: [
                                .destructive(Text("削除")) {
                                    store.send(.deletePologRoute)
                                },
                                .cancel(Text("キャンセル")) {
                                    store.send(.isPresentedActionSheet(false))
                                }
                            ]
                        )
                    case .addForewordHtml:
                        return ActionSheet(
                            title: Text(""),
                            buttons: [
                                .default(Text("追加")) {
                                    store.send(.addForewordHtml)
                                },
                                .cancel(Text("キャンセル")) {
                                    store.send(.isPresentedActionSheet(false))
                                }
                            ]
                        )
                    case .addAfterwordHtml:
                        return ActionSheet(
                            title: Text(""),
                            buttons: [
                                .default(Text("追加")) {
                                    store.send(.addAfterwordHtml)
                                },
                                .cancel(Text("キャンセル")) {
                                    store.send(.isPresentedActionSheet(false))
                                }
                            ]
                        )
                    case .closeMenuForCreate:
                        return ActionSheet(
                            title: Text(""),
                            buttons: [
                                .default(Text("下書きに保存する")) {
                                    store.send(.draft(store.inputPolog))
                                },
                                .destructive(Text("編集を破棄する")) {
                                    store.send(.dismiss)
                                },
                                .cancel(Text("キャンセル")) {
                                    store.send(.isPresentedActionSheet(false))
                                }
                            ]
                        )
                    case .closeMenuForDraft:
                        return ActionSheet(
                            title: Text(""),
                            buttons: [
                                .default(Text("下書きに保存する")) {
                                    store.send(.draft(store.inputPolog))
                                },
                                .destructive(Text("編集を破棄する")) {
                                    store.send(.dismiss)
                                },
                                .cancel(Text("キャンセル")) {
                                    store.send(.isPresentedActionSheet(false))
                                }
                            ]
                        )
                    case .closeMenuForEdit:
                        return ActionSheet(
                            title: Text(""),
                            buttons: [
                                .destructive(Text("編集を破棄する")) {
                                    store.send(.dismiss)
                                },
                                .cancel(Text("キャンセル")) {
                                    store.send(.isPresentedActionSheet(false))
                                }
                            ]
                        )
                    }
                }
        }
    }
}

extension PologRouteRegistrationView {
    struct ToolbarModifier: ViewModifier {
        @Bindable var store: StoreOf<PologRouteRegistrationReducer>

        func body(content: Content) -> some View {
            content
                .toolbar {
                    ToolbarItem(placement: .bottomBar) {
                        HStack {
                            Spacer16()
                            Button(action: {
                                store.send(.presentAssetSelectView)
                            }) {
                                Image("IconCameraAdd")
                                    .foregroundColor(Color(UIColor.label))
                            }
                            Spacer()
                            Button(action: {
                                store.send(.isPresentedIndexView(true))
                            }) {
                                Image("IconList")
                                    .foregroundColor(Color(UIColor.label))
                            }
                            Spacer()
                            Button(action: {}) {
                                Image("IconMap")
                                    .foregroundColor(Color(UIColor.label))
                            }
                            Spacer()
                            Button(action: {}) {
                                Image("IconHelp")
                                    .foregroundColor(Color(UIColor.label))
                            }
                            Spacer16()
                        }
                    }
                }
        }
    }
}
