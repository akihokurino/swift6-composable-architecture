import ComposableArchitecture
import Foundation

extension PresentationAction {
    var presented: Action? {
        switch self {
        case .dismiss:
            return nil
        case .presented(let action):
            return action
        }
    }
}
