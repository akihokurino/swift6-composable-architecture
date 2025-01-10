import Foundation

enum AppError: Error, Equatable {
    case plain(String)
    case unAuthorize
    case notFound
    case alreadyExist

    static func defaultError() -> AppError {
        return .plain("エラーが発生しました")
    }

    var localizedDescription: String {
        switch self {
        case .plain(let message):
            return message
        case .unAuthorize:
            return "一度ログアウトして再度ログインしてください"
        case .notFound:
            return "そのデータは存在しません"
        case .alreadyExist:
            return "そのデータはすでに存在しています"
        }
    }
}
