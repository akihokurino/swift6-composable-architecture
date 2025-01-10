import Foundation

extension URLSession {
    func loadDataFrom(url: URL) async throws -> Data {
        return try await withCheckedThrowingContinuation { continuation in
            dataTask(with: url, completionHandler: { data, _, _ in
                guard let data = data else {
                    continuation.resume(throwing: AppError.defaultError())
                    return
                }
                continuation.resume(returning: data)
            }).resume()
        }
    }

    func downloadDataFrom(url: URL) async throws -> URL {
        return try await withCheckedThrowingContinuation { continuation in
            downloadTask(with: url, completionHandler: { url, _, _ in
                guard let url = url else {
                    continuation.resume(throwing: AppError.defaultError())
                    return
                }
                continuation.resume(returning: url)
            }).resume()
        }
    }
}
