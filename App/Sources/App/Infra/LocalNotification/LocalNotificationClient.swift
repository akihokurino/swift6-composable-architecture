import Foundation
import SwiftUI

extension Notification.Name {
    static let forceLogout = Notification.Name("ForceLogout")
}

final class LocalNotificationClient: Sendable {
    func forceLogout() {
        NotificationCenter.default.post(name: .forceLogout, object: nil)
    }
}
