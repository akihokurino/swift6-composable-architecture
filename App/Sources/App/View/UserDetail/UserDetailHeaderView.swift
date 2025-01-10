import ComposableArchitecture
import SwiftUI

extension UserDetailView {
    struct HeaderView: View {
        @Bindable var store: StoreOf<UserDetailReducer>
    
        var body: some View {
            if let user = store.user {
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
                        if user.isBlocking {
                            Button(action: {}) {
                                Text("ブロックを解除")
                                    .foregroundStyle(Color.white)
                                    .font(.subheadline)
                            }
                            .padding(.vertical, 7)
                            .padding(.horizontal, 14)
                            .background(Color.red)
                            .cornerRadius(.infinity)
                        } else if store.isFollowRequesting {
                            Button(action: {}) {
                                Text("リクエスト中")
                                    .foregroundStyle(Color(.label))
                                    .font(.subheadline)
                            }
                            .padding(.vertical, 7)
                            .padding(.horizontal, 14)
                            .background(Color(.tertiarySystemFill))
                            .cornerRadius(.infinity)
                        } else if !user.isBlocked {
                            Button(action: {
                                store.send(.toggleFollow)
                            }) {
                                HStack(spacing: 3) {
                                    if store.isFollowing {
                                        Image(systemName: "check")
                                    }
                                    Text(store.isFollowing ? "フォロー中" : "フォロー")
                                        .foregroundStyle(store.isFollowing ? Color.primary : Color.white)
                                        .font(.subheadline)
                                }
                            }
                            .padding(.vertical, 7)
                            .padding(.horizontal, 14)
                            .background(store.isFollowing ? Color(.tertiarySystemFill) : Color(UIColor(named: "AccentColor")!))
                            .cornerRadius(.infinity)
                        }
                                    
                        Spacer16()
                    }
                    Spacer16()
                               
                    if !user.isBlocked {
                        Text("\(user.profile)")
                            .font(.subheadline)
                            .foregroundStyle(Color.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 16)
                    }
                          
                    if user.isEnableShow {
                        Spacer16()
                        HStack(spacing: 12) {
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
                    } else {
                        Spacer20()
                        Divider()
                    }
                }
            }
        }
    }
}
