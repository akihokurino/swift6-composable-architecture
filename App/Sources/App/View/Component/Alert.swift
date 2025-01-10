import SwiftUI

struct AlertEntity: Equatable {
    let title: String
    let message: String
    var type: AlertEntityType = .plain

    static func from(error: Error) -> AlertEntity {
        let message = (error as? AppError)?.localizedDescription ?? error.localizedDescription

        if let appError = error as? AppError {
            switch appError {
            case .plain: fallthrough
            case .notFound: fallthrough
            case .alreadyExist:
                return AlertEntity(title: "", message: message)
            case .unAuthorize:
                return AlertEntity(title: "認証に失敗しました", message: message, type: .unAuthorize)
            }
        }
        return AlertEntity(title: "", message: message)
    }
}

enum AlertEntityType {
    case plain
    case unAuthorize
}

struct AlertModifier: ViewModifier {
    let entity: AlertEntity?
    let onTap: () -> Void

    @Binding var isPresented: Bool

    func body(content: Content) -> some View {
        content
            .alert(
                entity?.title ?? "",
                isPresented: $isPresented,
                presenting: entity
            ) { entity in
                if entity.type == .unAuthorize {
                    Button(role: .destructive) {
                        onTap()
                        LocalNotificationClient.liveValue.forceLogout()
                    } label: {
                        Text("サインアウト")
                    }
                } else {
                    Button("OK") {
                        onTap()
                    }
                }
            } message: { entity in
                Text(entity.message)
            }
    }
}
