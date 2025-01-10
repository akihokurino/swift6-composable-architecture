import ComposableArchitecture
import SwiftUI

extension MyPageView {
    struct HeaderView: View {
        @Bindable var store: StoreOf<MyPageReducer>
    
        var body: some View {
            let user = store.loginUser!.me.user
            
            VStack(spacing: 0) {
                Spacer20()
                HStack(alignment: .top, spacing: 0) {
                    Spacer16()
                    RemoteImageView(
                        url: user.iconSignedUrl.url,
                        size: CGSize(width: 64, height: 64),
                        isCircle: true
                    )
                    
                    Spacer16()
                    VStack(alignment: .leading, spacing: 0) {
                        HStack(spacing: 0) {
                            Text("\(user.fullName)")
                                .font(.title2)
                                .fontWeight(.bold)
                            if !user.isPublic {
                                Image("IconLock")
                                    .resizable()
                                    .frame(width: 24, height: 24)
                                    .foregroundStyle(Color.primary)
                            }
                        }
                        Text("@\(user.username)")
                            .font(.subheadline)
                            .foregroundStyle(Color(.secondaryLabel))
                        Spacer4()
                        HStack(spacing: 0) {
                            Button(action: {
                                store.send(.presentFollowListView(0))
                            }) {
                                Text("\(user.followeeCount)フォロー")
                                    .font(.footnote)
                                    .foregroundStyle(Color(.secondaryLabel))
                            }
                            Text("・")
                                .font(.footnote)
                                .foregroundStyle(Color(.secondaryLabel))
                            Button(action: {
                                store.send(.presentFollowListView(1))
                            }) {
                                Text("\(user.followerCount)フォロワー")
                                    .font(.footnote)
                                    .foregroundStyle(Color(.secondaryLabel))
                            }
                        }
                    }
                    
                    Spacer()
                    
                    Spacer16()
                    Button {
                        store.send(.presentUserEditView)
                    } label: {
                        Text("編集")
                            .foregroundStyle(Color.primary)
                            .font(.subheadline)
                    }
                    .foregroundStyle(Color.primary)
                    .padding(EdgeInsets(top: 7, leading: 14, bottom: 7, trailing: 14))
                    .background(Color(.tertiarySystemFill))
                    .cornerRadius(.infinity)
                    
                    Spacer16()
                }
                Spacer16()
                
                Text("\(user.profile)")
                    .font(.subheadline)
                    .foregroundStyle(Color.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                
                Spacer16()
                HStack(spacing: 12) {
                    Button {
                        store.send(.presentClippedPologListView)
                    } label: {
                        HStack(alignment: .center, spacing: 0) {
                            Image("IconClip")
                                .resizable()
                                .frame(width: 16, height: 16)
                                .foregroundStyle(Color.primary)
                            Spacer4()
                            Text("クリップ")
                                .foregroundStyle(Color.primary)
                                .font(.subheadline)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .foregroundColor(Color.primary)
                    .background(Color(.tertiarySystemFill))
                    .cornerRadius(.infinity)
                    
                    Button {} label: {
                        HStack(alignment: .center, spacing: 0) {
                            Image("IconMap")
                                .resizable()
                                .frame(width: 16, height: 16)
                                .foregroundStyle(Color.primary)
                            Spacer4()
                            Text("マップ")
                                .foregroundStyle(Color.primary)
                                .font(.subheadline)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .foregroundColor(Color.primary)
                    .background(Color(.tertiarySystemFill))
                    .cornerRadius(.infinity)
                        
                    Button {} label: {
                        HStack(alignment: .center, spacing: 0) {
                            Image("IconSticker")
                                .resizable()
                                .frame(width: 16, height: 16)
                                .foregroundStyle(Color.primary)
                            Spacer4()
                            Text("ステッカー")
                                .foregroundStyle(Color.primary)
                                .font(.subheadline)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .foregroundColor(Color.primary)
                    .background(Color(.tertiarySystemFill))
                    .cornerRadius(.infinity)
                }
                .padding(.horizontal, 16)
                    
                Spacer20()
                    
                Button(action: {}, label: {
                    VStack(spacing: 0) {
                        Divider()
                        Spacer16()
                        HStack {
                            Spacer16()
                            VStack(spacing: 0) {
                                Text("旅行回数")
                                    .font(.footnote)
                                    .foregroundStyle(Color(.secondaryLabel))
                                Text(String(store.pologSummary?.totalPologCount ?? 0))
                                    .font(.title2)
                                    .fontWeight(.semibold)
                            }
                            Spacer()
                            VStack(spacing: 0) {
                                Text("旅行日数")
                                    .font(.footnote)
                                    .foregroundStyle(Color(.secondaryLabel))
                                Text(String(store.pologSummary?.totalPologDayCount ?? 0))
                                    .font(.title2)
                                    .fontWeight(.semibold)
                            }
                            Spacer()
                            VStack(spacing: 0) {
                                Text("スポット")
                                    .font(.footnote)
                                    .foregroundStyle(Color(.secondaryLabel))
                                Text(String(store.pologSummary?.totalSpotCount ?? 0))
                                    .font(.title2)
                                    .fontWeight(.semibold)
                            }
                            Spacer()
                            VStack(spacing: 0) {
                                Text("移動距離(km)")
                                    .font(.footnote)
                                    .foregroundStyle(Color(.secondaryLabel))
                                    
                                Text(String(Int(store.pologSummary?.totalDistance ?? 0)))
                                    .font(.title2)
                                    .fontWeight(.semibold)
                            }
                            Spacer()
                            ZStack {
                                Circle()
                                    .fill(Color(.tertiarySystemFill))
                                    .frame(width: 28, height: 28)
                                Image(systemName: "chevron.forward")
                                    .frame(width: 15, height: 20)
                                    .foregroundColor(Color.primary)
                            }
                            Spacer16()
                        }
                        .frame(maxWidth: .infinity)
                        Spacer16()
                        Divider()
                    }
                    .overlay(
                        Rectangle().fill(.clear)
                    )
                    .contentShape(Rectangle())
                })
                .buttonStyle(PlainButtonStyle())
                    
                if let progress = store.pologRegistrationProgress {
                    ProgressIndicatorView(text: "旅行記をアップロード中...", value: progress)
                }
                    
                Spacer16()
                    
                HStack(spacing: 0) {
                    Spacer16()
                    Button {
                        store.send(.setPologListType(.myPologs))
                        store.send(.isPresentedHUD(true))
                        store.send(.fetchPologs(true))
                    } label: {
                        Text("旅行記")
                            .font(.subheadline)
                    }
                    .buttonStyle(SelectedButtonStyle(isSelected: store.pologListType == .myPologs))
                    Spacer8()
                    Button {
                        store.send(.setPologListType(.accompaniedPolog))
                        store.send(.isPresentedHUD(true))
                        store.send(.fetchPologs(true))
                    } label: {
                        Text("タグ付け")
                            .font(.subheadline)
                    }
                    .buttonStyle(SelectedButtonStyle(isSelected: store.pologListType == .accompaniedPolog))
                        
                    Spacer()
                    Button(action: {}) {
                        HStack {
                            Image("IconTune")
                                .resizable()
                                .frame(width: 20, height: 20)
                            Text("絞り込み")
                        }
                        .foregroundColor(.primary)
                    }
                    Spacer16()
                }
                Spacer24()
            }
        }
    }
}
