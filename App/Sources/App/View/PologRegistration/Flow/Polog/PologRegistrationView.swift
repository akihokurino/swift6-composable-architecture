import ComposableArchitecture
import SwiftUI

struct PologRegistrationView: View {
    @Bindable var store: StoreOf<PologRegistrationReducer>

    var body: some View {
        ContentView(store: store)
            .onAppear {
                store.send(.initialize)
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("投稿設定")
                        .fontWeight(.semibold)
                        .foregroundColor(Color(.label))
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .navigationBarItems(leading: Group {
                Button(action: {
                    store.send(.dismiss)
                }) {
                    Image(systemName: "chevron.backward")
                        .foregroundColor(Color(UIColor.label))
                }
            }, trailing: HStack {
                Button(action: {
                    store.send(.presentMenuActionSheet)
                }) {
                    Image(systemName: "ellipsis")
                        .foregroundColor(Color(UIColor.label))
                }
                Button(action: {
                    store.send(.confirm)
                }) {
                    Text(store.inputPolog.isEdit ? "更新" : "投稿")
                        .foregroundColor(Color(UIColor.label))
                }
            })
            .modifier(NavigationModifier(store: store))
            .modifier(CustomAlertModifier(store: store))
            .modifier(ActionSheetModifier(store: store))
            .modifier(HUDModifier(isPresented: $store.isPresentedHUD.sending(\.isPresentedHUD)))
            .modifier(AlertModifier(entity: store.alert, onTap: {
                store.send(.isPresentedAlert(false))
            }, isPresented: $store.isPresentedAlert.sending(\.isPresentedAlert)))
            .colorScheme(.light)
            .toolbarColorScheme(.light, for: .automatic)
    }
}

extension PologRegistrationView {
    struct ContentView: View {
        @Bindable var store: StoreOf<PologRegistrationReducer>
        
        @State var inputTag: String = ""

        var body: some View {
            GeometryReader { geometry in
                let thumbnailWidth = abs(geometry.size.width - 150)
                let thumbnailSize = CGSize(width: thumbnailWidth, height: thumbnailWidth)
                let companionIconSize = CGSize(width: 50, height: 50)
                    
                ScrollView {
                    VStack(spacing: 0) {
                        Spacer20()
                            
                        HStack {
                            Text("タイトル")
                                .font(.footnote)
                                .foregroundColor(Color(UIColor.secondaryLabel))
                                .padding(.horizontal, 16)
                                .bold()
                            Spacer()
                            Text("\(store.inputPolog.title.count)/24")
                                .font(.footnote)
                                .foregroundColor(Color(UIColor.secondaryLabel))
                                .padding(.horizontal, 16)
                        }
                        .frame(maxWidth: .infinity)
                            
                        Spacer8()
                            
                        TextFieldView(value: $store.inputPolog.title.sending(\.setTitle), placeholder: "タイトルを入力", keyboardType: .default) { value in
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                store.send(.setTitle(String(value.prefix(24))))
                            }
                        }
                            
                        Spacer20()
                            
                        HStack {
                            Text("表紙")
                                .font(.footnote)
                                .foregroundColor(Color(UIColor.secondaryLabel))
                                .padding(.horizontal, 16)
                                .bold()
                            Spacer()
                        }
                        .frame(maxWidth: .infinity)
                            
                        Spacer8()
                            
                        VStack {
                            Spacer20()
                                
                            ZStack {
                                if let thumbnail = store.inputPolog.thumbnail {
                                    switch thumbnail {
                                    case .localAsset(let asset):
                                        LocalImageView(asset: asset, size: thumbnailSize, radius: 8)
                                    case .remoteAsset(let asset):
                                        RemoteImageView(url: asset.thumbnailUrl, size: thumbnailSize, radius: 8)
                                    }
                                } else {
                                    Button(action: {
                                        store.send(.presentPologThumbnailRegistrationView)
                                    }) {
                                        VStack {
                                            Spacer()
                                            HStack {
                                                Spacer()
                                                Image(systemName: "photo")
                                                    .foregroundColor(.gray)
                                                Spacer()
                                            }
                                            Spacer()
                                        }
                                    }
                                }
                                    
                                VStack {
                                    Spacer16()
                                    HStack {
                                        Spacer16()
                                        Text(store.inputPolog.label?.label1 ?? "")
                                            .foregroundColor(.white)
                                        Spacer()
                                    }
                                    Spacer()
                                    HStack {
                                        Spacer()
                                        Text(store.inputPolog.label?.label2 ?? "")
                                            .foregroundColor(.white)
                                        Spacer()
                                    }
                                    Spacer()
                                    HStack {
                                        Spacer()
                                        Text(store.inputPolog.label?.label3 ?? "")
                                            .foregroundColor(.white)
                                        Spacer16()
                                    }
                                    Spacer16()
                                }
                            }
                            .frame(width: thumbnailSize.width, height: thumbnailSize.height)
                                
                            Spacer20()
                            Divider()
                            Spacer20()
                                
                            Button(action: {
                                store.send(.presentPologThumbnailRegistrationView)
                            }) {
                                HStack {
                                    Text("表紙の変更")
                                        .font(.body)
                                        .foregroundColor(Color(UIColor.label))
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(Color(UIColor.tertiaryLabel))
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .padding(.horizontal, 16)
                                
                            Spacer20()
                        }
                        .background(Color(UIColor.quaternarySystemFill))
                        .cornerRadius(10.0)
                            
                        Spacer20()
                            
                        HStack {
                            Text("公開範囲")
                                .font(.footnote)
                                .foregroundColor(Color(UIColor.secondaryLabel))
                                .padding(.horizontal, 16)
                                .bold()
                            Spacer()
                        }
                        .frame(maxWidth: .infinity)
                            
                        Spacer8()
                            
                        VStack(spacing: 0) {
                            HStack {
                                Image("IconGlobeAsia")
                                    .resizable()
                                    .frame(width: 24, height: 24)
                                Spacer16()
                                Text("誰でも")
                                    .font(.body)
                                    .foregroundColor(Color(UIColor.label))
                                Spacer()
                                Button(action: {
                                    store.send(.setVisibility(.public))
                                }) {
                                    if store.inputPolog.visibility == .public {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(Color(UIColor.label))
                                    } else {
                                        Image(systemName: "circle")
                                            .foregroundColor(Color(UIColor.label))
                                    }
                                }
                            }
                            .padding()
                                
                            Divider()
                                
                            HStack {
                                Image("IconGroupMini")
                                    .resizable()
                                    .frame(width: 24, height: 24)
                                Spacer16()
                                Text("相互フォロワー")
                                    .font(.body)
                                    .foregroundColor(Color(UIColor.label))
                                Spacer()
                                Button(action: {
                                    store.send(.setVisibility(.onlyMutualFollow))
                                }) {
                                    if store.inputPolog.visibility == .onlyMutualFollow {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(Color(UIColor.label))
                                    } else {
                                        Image(systemName: "circle")
                                            .foregroundColor(Color(UIColor.label))
                                    }
                                }
                            }
                            .padding()
                                
                            Divider()
                                
                            HStack {
                                Image("IconAccompanied")
                                    .resizable()
                                    .frame(width: 24, height: 24)
                                Spacer16()
                                VStack(alignment: .leading) {
                                    Text("同行者に設定したユーザーのみ")
                                        .font(.body)
                                        .foregroundColor(Color(UIColor.label))
                                    Text("この記事の同行者の設定に追加されたユーザーのみ表示")
                                        .font(.body)
                                        .foregroundColor(Color(UIColor.label))
                                        .multilineTextAlignment(.leading)
                                }
                                Spacer()
                                Button(action: {
                                    store.send(.setVisibility(.onlyCompanion))
                                }) {
                                    if store.inputPolog.visibility == .onlyCompanion {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(Color(UIColor.label))
                                    } else {
                                        Image(systemName: "circle")
                                            .foregroundColor(Color(UIColor.label))
                                    }
                                }
                            }
                            .padding()
                                
                            Divider()
                                
                            HStack {
                                Image("IconLock")
                                    .resizable()
                                    .frame(width: 24, height: 24)
                                Spacer16()
                                Text("自分のみ")
                                    .font(.body)
                                    .foregroundColor(Color(UIColor.label))
                                Spacer()
                                Button(action: {
                                    store.send(.setVisibility(.private))
                                }) {
                                    if store.inputPolog.visibility == .private {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(Color(UIColor.label))
                                    } else {
                                        Image(systemName: "circle")
                                            .foregroundColor(Color(UIColor.label))
                                    }
                                }
                            }
                            .padding()
                        }
                        .background(Color(UIColor.quaternarySystemFill))
                        .cornerRadius(10.0)
                            
                        Spacer20()
                            
                        HStack {
                            Text("タグ")
                                .font(.footnote)
                                .foregroundColor(Color(UIColor.secondaryLabel))
                                .padding(.horizontal, 16)
                                .bold()
                            Spacer()
                            Text("任意")
                                .font(.caption)
                                .bold()
                                .foregroundColor(.white)
                                .padding(.vertical, 2)
                                .padding(.horizontal, 8)
                                .background(RoundedRectangle(cornerRadius: 4).foregroundColor(.gray))
                        }
                        .frame(maxWidth: .infinity)
                            
                        Spacer8()
                            
                        TextFieldView(value: $inputTag, placeholder: "例）旅行", keyboardType: .default) { value in
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                guard !value.isRealEmpty else {
                                    inputTag = ""
                                    return
                                }
                                    
                                store.send(.setTag(InputTag(value: value)))
                                inputTag = ""
                            }
                        }
                            
                        Spacer12()
                            
                        FlowLayoutView<InputTag>(
                            items: store.inputPolog.tags,
                            spacing: 4,
                            itemView: { item in
                                AnyView(ChipView(
                                    value: item.value,
                                    onTap: {
                                        store.send(.deleteTag(item))
                                    },
                                    backgroundColor: Color(UIColor.tertiarySystemFill),
                                    textColor: Color(UIColor.label),
                                    isDeletable: true
                                ))
                            }
                        )
                        
                        Spacer20()
                            
                        HStack {
                            Text("同行者")
                                .font(.footnote)
                                .foregroundColor(Color(UIColor.secondaryLabel))
                                .padding(.horizontal, 16)
                                .bold()
                            Spacer()
                            Text("任意")
                                .font(.caption)
                                .bold()
                                .foregroundColor(.white)
                                .padding(.vertical, 2)
                                .padding(.horizontal, 8)
                                .background(RoundedRectangle(cornerRadius: 4).foregroundColor(.gray))
                        }
                        .frame(maxWidth: .infinity)
                            
                        Spacer8()
                            
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                VStack(spacing: 0) {
                                    Button(action: {
                                        store.send(.presentPologCompanionRegistrationView)
                                    }) {
                                        Image(systemName: "plus")
                                            .font(.title3)
                                            .bold()
                                            .foregroundColor(Color(UIColor.label))
                                            .background(Circle().fill(Color(UIColor.tertiarySystemFill)).frame(width: companionIconSize.width, height: companionIconSize.height))
                                    }
                                    .frame(width: companionIconSize.width, height: companionIconSize.height)
                                        
                                    Spacer4()
                                        
                                    Text("追加")
                                        .font(.caption)
                                        .foregroundColor(Color(UIColor.label))
                                        
                                    Spacer()
                                }
                                .frame(width: companionIconSize.width)
                                   
                                ForEach(store.inputPolog.companions, id: \.id) { item in
                                    VStack(spacing: 0) {
                                        if let url = item.iconUrl {
                                            RemoteImageView(url: url, size: companionIconSize, isCircle: true)
                                        } else {
                                            VStack {
                                                Image(systemName: "photo")
                                                    .background(Circle().fill(Color.gray).frame(width: companionIconSize.width, height: companionIconSize.height))
                                            }
                                            .frame(width: companionIconSize.width, height: companionIconSize.height)
                                        }
                                            
                                        Spacer4()
                                            
                                        Text(item.name)
                                            .lineLimit(2)
                                            .fixedSize(horizontal: false, vertical: true)
                                            .font(.caption)
                                            .foregroundColor(Color(UIColor.label))
                                            
                                        Spacer()
                                    }
                                    .frame(width: companionIconSize.width)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .padding(.horizontal, 16)
                        .background(Color(UIColor.quaternarySystemFill))
                        .cornerRadius(10)
                            
                        Spacer20()
                            
                        HStack {
                            Text("コメント")
                                .font(.footnote)
                                .foregroundColor(Color(UIColor.secondaryLabel))
                                .padding(.horizontal, 16)
                                .bold()
                            Spacer()
                        }
                        .frame(maxWidth: .infinity)
                            
                        Spacer8()
                            
                        VStack(spacing: 0) {
                            Toggle("コメントを受け付ける", isOn: $store.inputPolog.isCommentable.sending(\.setIsCommentable))
                                .padding()
                        }
                        .background(Color(UIColor.quaternarySystemFill))
                        .cornerRadius(10.0)
                            
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                }
                .background(Color(UIColor.systemBackground))
                .scrollDismissesKeyboard(.immediately)
            }
        }
    }
}

extension PologRegistrationView {
    struct NavigationModifier: ViewModifier {
        @Bindable var store: StoreOf<PologRegistrationReducer>

        func body(content: Content) -> some View {
            WithViewStore(store, observe: { $0 }) { _ in
                content
                    .navigationDestination(
                        item: $store.scope(state: \.destination?.thumbnailRegistration, action: \.destination.thumbnailRegistration)
                    ) { store in
                        PologThumbnailRegistrationView(store: store)
                    }
                    .navigationDestination(
                        item: $store.scope(state: \.destination?.companionRegistration, action: \.destination.companionRegistration)
                    ) { store in
                        PologCompanionRegistrationView(store: store)
                    }
            }
        }
    }
}

extension PologRegistrationView {
    struct CustomAlertModifier: ViewModifier {
        @Bindable var store: StoreOf<PologRegistrationReducer>

        func body(content: Content) -> some View {
            WithViewStore(store, observe: { $0 }) { viewStore in
                content
                    .alert(
                        "\(store.inputPolog.isEdit ? "更新" : "投稿")前の確認",
                        isPresented: $store.isPresentedCreateConfirmAlert.sending(\.isPresentedCreateConfirmAlert)
                    ) {
                        HStack {
                            Button("キャンセル", role: .cancel) {
                                store.send(.isPresentedCreateConfirmAlert(false))
                            }
                            Button(viewStore.inputPolog.isEdit ? "更新" : "投稿") {
                                store.send(.register(store.inputPolog))
                            }
                        }
                    } message: {
                        Text("写真は位置情報を使用しています。位置情報から個人の居住地等を特定できる情報をログに含んでから投稿してください")
                    }
                    .alert(
                        "下書きを削除しますか",
                        isPresented: $store.isPresentedDeleteDraftAlert.sending(\.isPresentedDeleteDraftAlert)
                    ) {
                        HStack {
                            Button("キャンセル", role: .cancel) {
                                store.send(.isPresentedDeleteDraftAlert(false))
                            }
                            Button("削除する", role: .destructive) {
                                store.send(.deleteDraft)
                            }
                        }
                    } message: {}
            }
        }
    }
}

extension PologRegistrationView {
    struct ActionSheetModifier: ViewModifier {
        @Bindable var store: StoreOf<PologRegistrationReducer>

        func body(content: Content) -> some View {
            content
                .actionSheet(isPresented: $store.isPresentedActionSheet.sending(\.isPresentedActionSheet)) {
                    switch store.actionSheetType {
                    case .menuForCreate:
                        return ActionSheet(
                            title: Text(""),
                            buttons: [
                                .default(Text("下書きに保存する")) {
                                    store.send(.draft(store.inputPolog))
                                },
                                .destructive(Text("編集を破棄する")) {
                                    store.send(.cancel)
                                },
                                .cancel(Text("キャンセル")) {
                                    store.send(.isPresentedActionSheet(false))
                                }
                            ]
                        )
                    case .menuForDraft:
                        return ActionSheet(
                            title: Text(""),
                            buttons: [
                                .default(Text("下書きに保存する")) {
                                    store.send(.draft(store.inputPolog))
                                },
                                .destructive(Text("下書きを削除する")) {
                                    store.send(.isPresentedDeleteDraftAlert(true))
                                },
                                .cancel(Text("キャンセル")) {
                                    store.send(.isPresentedActionSheet(false))
                                }
                            ]
                        )
                    case .menuForEdit:
                        return ActionSheet(
                            title: Text(""),
                            buttons: [
                                .destructive(Text("編集を破棄する")) {
                                    store.send(.cancel)
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
