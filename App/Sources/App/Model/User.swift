import Foundation

extension UserOverview: Identifiable {}

extension User: Identifiable {
    var isEnableShow: Bool {
        return (!isBlocked && !isBlocking) && (isPublic || isFollowing)
    }
}
