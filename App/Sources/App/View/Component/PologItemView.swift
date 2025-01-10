import SwiftUI

struct PologItemView: View {
    let menu: AnyView
    let polog: PologOverview
    let onTapHeart: () -> Void
    let onTapClip: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(polog.title)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .lineLimit(2)
                Spacer()
                menu
            }
            Spacer4()

            HStack(spacing: 0) {
                Text("\(polog.dateLabel)")
                    .font(.footnote)
                Spacer8()
                HStack(spacing: 0) {
                    Image("IconLocation")
                        .resizable()
                        .frame(width: 13, height: 13)
                    Text("佐賀県")
                        .font(.footnote)
                }
                Spacer8()
                HStack(spacing: 0) {
                    switch polog.visibility {
                    case .public:
                        Image("IconGlobeAsia")
                            .resizable()
                            .frame(width: 16, height: 16)
                        Text("公開").font(.footnote)
                    case .onlyMutualFollow:
                        Image("IconGroupMini")
                            .resizable()
                            .frame(width: 16, height: 16)
                        Text("フォロワーのみ").font(.footnote)
                    case .onlyCompanion:
                        Image("IconAccompanied")
                            .resizable()
                            .frame(width: 16, height: 16)
                        Text("同行者のみ").font(.footnote)
                    case .private:
                        Image("IconLock")
                            .resizable()
                            .frame(width: 16, height: 16)
                        Text("自分のみ").font(.footnote)
                    default:
                        Text("")
                    }
                }
                Spacer()
            }
            .foregroundColor(Color(.secondaryLabel))
            Spacer12()

            HStack(spacing: 0) {
                HStack(spacing: 4) {
                    ForEach(polog.sortedUniqueTransportations, id: \.self) { transportation in
                        if let icon = transportation.icon {
                            icon
                                .resizable()
                                .frame(width: 14, height: 14)
                        }
                    }
                }
                Spacer()
            }
            .foregroundColor(Color(.secondaryLabel))
            Spacer12()

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    ZStack(alignment: .center) {
                        RemoteImageView(
                            url: polog.thumbnailSignedUrl.url,
                            size: CGSize(width: 160, height: 160),
                            isCircle: false
                        )
                        .clipShape(
                            .rect(
                                topLeadingRadius: 8,
                                bottomLeadingRadius: 8
                            )
                        )
                    }

                    ForEach(polog.routes.filter { $0.isIncludeIndex }, id: \.self) { route in
                        ZStack(alignment: .bottomLeading) {
                            RemoteImageView(
                                url: route.videoThumbnailSignedUrl?.url ?? route.assetSignedUrl.url,
                                size: CGSize(width: 160, height: 160),
                                isCircle: false
                            )
                            .padding(.leading, 4)
                            if let spot = route.spot {
                                VStack {
                                    Spacer()
                                    HStack {
                                        Spacer8()
                                        Image("IconLocation")
                                            .resizable()
                                            .frame(width: 13, height: 13)
                                        Text(spot.name)
                                            .font(.footnote)
                                    }
                                    Spacer8()
                                }
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .frame(maxWidth: .infinity)
            Spacer8()

            HStack {
                Button(action: {
                    onTapClip()
                }, label: {
                    HStack(spacing: 0) {
                        Image("IconClip")
                            .resizable()
                            .frame(width: 20, height: 20)
                        Text(String(polog.clipCount))
                            .font(.subheadline)
                    }
                })
                .foregroundColor(Color(.secondaryLabel))

                Button(action: {
                    onTapHeart()
                }, label: {
                    HStack(spacing: 0) {
                        Image(polog.isLiked ? "IconHeartFill" : "IconHeart")
                            .resizable()
                            .frame(width: 20, height: 20)
                        Text(String(polog.likeCount))
                            .font(.subheadline)
                    }
                })
                .foregroundColor(Color(.secondaryLabel))

                Spacer()
                HStack {
                    RemoteImageView(
                        url: polog.user.iconSignedUrl.url,
                        size: CGSize(width: 20, height: 20),
                        isCircle: true
                    )
                    Text(polog.user.fullName)
                        .font(.subheadline)
                        .foregroundStyle(Color.primary)
                    Spacer16()
                }
            }

            Spacer16()

            Divider()
                .padding(.trailing, 16)
        }
        .padding(.leading, 16)
    }
}

struct DummyPologItemView: View {
    @State var isLoading = true
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("abcdefghijklmn")
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .lineLimit(2)
                    .shimmer(isLoading)

                Spacer()
            }
            .padding(.trailing, 16)
            .padding(.bottom, 8)

            HStack {
                Text("\("abcdefghijklmn")")
                    .font(.footnote)
                    .shimmer(isLoading)
                HStack(spacing: 0) {
                    Image("IconGlobeAsia")
                        .resizable()
                        .frame(width: 16, height: 16)
                }
                .shimmer(isLoading)
                Spacer()
            }
            .foregroundColor(Color(.secondaryLabel))
            .padding(.bottom, 8)

            HStack {
                HStack {
                    Image("IconLocation")
                        .resizable()
                        .frame(width: 13, height: 13)
                        .shimmer(isLoading)
                    Text("abcdef")
                        .font(.footnote)
                        .shimmer(isLoading)
                }

                Spacer()
            }
            .foregroundColor(Color(.secondaryLabel))
            .padding(.bottom, 12)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    ZStack(alignment: .center) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.gray)
                            .frame(width: 160, height: 160)
                            .shimmer(isLoading)
                    }

                    ForEach(0 ..< 4, id: \.self) { _ in
                        ZStack(alignment: .bottomLeading) {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.gray)
                                .frame(width: 160, height: 160)
                                .shimmer(isLoading)
                                .padding(.leading, 4)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .frame(maxWidth: .infinity)
            .padding(.trailing, 0)
            .padding(.bottom, 8)

            HStack {
                Button(action: {}, label: {
                    HStack(spacing: 0) {
                        Image("IconClip")
                            .resizable()
                            .frame(width: 20, height: 20)
                        Text(String(10))
                            .font(.subheadline)
                    }
                })
                .foregroundColor(Color.white)
                .shimmer(isLoading)
                Button(action: {}, label: {
                    HStack(spacing: 0) {
                        Image("IconHeartFill")
                            .resizable()
                            .frame(width: 20, height: 20)
                        Text(String(10))
                            .font(.subheadline)
                    }
                })
                .foregroundColor(Color(.secondaryLabel))
                .shimmer(isLoading)
                Spacer()
                HStack {
                    Circle()
                        .frame(width: 20, height: 20)
                        .shimmer(isLoading)
                    Text("abcdefg")
                        .font(.subheadline)
                        .foregroundStyle(Color.primary)
                        .shimmer(isLoading)
                }
                .padding(.trailing, 16)
            }
            .padding(.bottom, 16)
        }
        .padding(.leading, 16)
        .redacted(reason: .placeholder)
    }
}
