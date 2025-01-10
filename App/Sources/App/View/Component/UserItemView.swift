import SwiftUI

struct UserItemView: View {
    let user: UserOverview
    var isFollowing: Bool?
    var isBlocking: Bool?
    let followAction: () -> Void
    let unBlockAction: () -> Void
    
    var body: some View {
        HStack(spacing: 0) {
            RemoteImageView(
                url: user.iconSignedUrl.url,
                size: CGSize(width: 54, height: 54),
                isCircle: true
            )
            
            VStack(alignment: .leading, spacing: 0) {
                Text(user.fullName)
                    .font(.body)
                Text(user.username)
                    .font(.footnote)
                    .foregroundStyle(Color(.secondaryLabel))
            }
            .padding(.leading, 12)
            
            Spacer()
            
            if let _isBlocking = isBlocking, _isBlocking {
                Button(action: {
                    unBlockAction()
                }) {
                    Text("ブロックを解除")
                        .font(.subheadline)
                        .foregroundColor(Color.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.red)
                        .cornerRadius(.infinity)
                }
                .buttonStyle(PlainButtonStyle())
            } else if let _isFollowing = isFollowing {
                Button(action: {
                    followAction()
                }) {
                    HStack {
                        if _isFollowing {
                            Image(systemName: "checkmark")
                        }
                        Text(_isFollowing ? "フォロー中" : "フォロー")
                            .font(.subheadline)
                    }
                    .foregroundColor(_isFollowing ? Color.primary : Color.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(_isFollowing ? Color(.tertiarySystemFill) : Color.accentColor)
                    .cornerRadius(.infinity)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
}
