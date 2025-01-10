import ComposableArchitecture
import SwiftUI

struct PologCommentListView: View {
    @Bindable var store: StoreOf<PologCommentListReducer>

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

extension PologCommentListView {
    struct ContentView: View {
        @Bindable var store: StoreOf<PologCommentListReducer>
        @FocusState var isActiveInput: Bool

        var body: some View {
            GeometryReader { geometry in
                VStack(spacing: 0) {
                    Spacer16()
                    HStack {
                        Text("コメント")
                            .bold()
                            .font(.title3)
                            .foregroundColor(Color(UIColor.label))
                        Spacer()
                        Button(action: {
                            store.send(.dismiss)
                        }) {
                            Image(systemName: "xmark")
                                .background(Circle().fill(Color(UIColor.secondarySystemFill)).frame(width: 30, height: 30))
                        }
                    }
                    .padding(.horizontal, 16)
                    Spacer16()
                    
                    ZStack {
                        PagingListView<PologComment>(
                            itemView: { comment in
                                AnyView(CommentView(comment: comment))
                            },
                            emptyView: {
                                AnyView(
                                    VStack {
                                        Spacer()
                                        Text("コメントはまだありません")
                                            .bold()
                                            .font(.title3)
                                            .foregroundColor(Color(UIColor.label))
                                        Spacer16()
                                        Text("コメントを追加して感想を伝えましょう")
                                            .font(.subheadline)
                                            .foregroundColor(Color(UIColor.secondaryLabel))
                                        Spacer()
                                    }
                                )
                            },
                            onTap: { _ in
                                
                            },
                            onNext: {
                                store.send(.fetchComments(false))
                            },
                            onRefresh: {
                                store.send(.fetchComments(true))
                            },
                            data: store.comments,
                            isLoading: $store.isPresentedNextLoading.sending(\.isPresentedNextLoading),
                            isRefreshing: $store.isPresentedPullToRefresh.sending(\.isPresentedPullToRefresh)
                        )
                        .listStyle(PlainListStyle())
                        .padding(.horizontal, 16)
                        .scrollDismissesKeyboard(.immediately)
                        
                        VStack {
                            Spacer()
                            
                            VStack {
                                let iconSize = CGSize(width: 32, height: 32)
                                let buttonWidth: CGFloat = 40
                                let buttonAreaWidth: CGFloat = isActiveInput ? 16 + buttonWidth : 0
                                let inputWidth: CGFloat = geometry.size.width - (16 * 2) - iconSize.width - 8 - buttonAreaWidth
                                Divider()
                                
                                Spacer12()
                                
                                HStack(alignment: .bottom) {
                                    RemoteImageView(url: store.loginUser?.me.user.iconSignedUrl.url, size: iconSize, isCircle: true)
                                    
                                    Spacer8()
                                    TextField(
                                        "コメントを入力",
                                        text: $store.comment.sending(\.setComment),
                                        axis: .vertical
                                    )
                                    .frame(width: inputWidth)
                                    .textFieldStyle(.plain)
                                    .focused($isActiveInput)
                                    
                                    if isActiveInput {
                                        Spacer16()
                                        Button(action: {
                                            store.send(.sendComment)
                                            isActiveInput = false
                                        }) {
                                            Text("送信")
                                                .bold()
                                                .font(.callout)
                                                .foregroundColor(Color(UIColor.label))
                                                .frame(width: buttonWidth)
                                        }
                                    }
                                }
                                .padding(.horizontal, 16)
                                
                                Spacer12()
                            }
                            .background(Color(UIColor.systemBackground))
                        }
                    }
                }
            }
        }
    }
}

extension PologCommentListView {
    struct CommentView: View {
        let comment: PologComment

        var body: some View {
            HStack {
                RemoteImageView(url: comment.user.iconSignedUrl.url, size: CGSize(width: 32, height: 32), isCircle: true)
                Spacer8()
                VStack(alignment: .leading) {
                    HStack {
                        Text(comment.user.fullName)
                            .font(.footnote)
                            .foregroundColor(Color(UIColor.label))
                        Spacer4()
                        Text(comment.createdAt.iso8601?.dateTimeDisplayJST ?? "")
                            .font(.footnote)
                            .foregroundColor(Color(UIColor.secondaryLabel))
                        Spacer()
                    }
                    Spacer4()
                    Text(comment.text)
                        .font(.callout)
                        .foregroundColor(Color(UIColor.label))
                }
            }
            .padding(.bottom, 12)
        }
    }
}
