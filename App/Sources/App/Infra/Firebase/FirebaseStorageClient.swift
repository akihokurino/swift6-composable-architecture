import FirebaseStorage
import Foundation
import UIKit

let pologRouteAssetPath = "polog-route-asset"
let pologThumbnailPath = "polog-thumbnail"
let userProfilePath = "user-profile"
let groupIconPath = "group-icon"
let groupAlbumCoverPath = "group-album-cover"
let groupAlbumAssetPath = "group-album-asset"

final class FirebaseStorageClient: Sendable {
    init() {}

    func upload(data: Data, contentType: String, filePath: String) async throws -> URL {
        let meta = StorageMetadata()
        meta.contentType = contentType
        let storageRef = Storage.storage().reference()
        let ref = storageRef.child("userdata/\(filePath)")

        return try await withCheckedThrowingContinuation { continuation in
            ref.putData(data, metadata: meta) { _, error in
                if let error = error {
                    continuation.resume(throwing: AppError.plain(error.localizedDescription))
                    return
                }
                guard let gsUrl = URL(string: "gs://\(ref.bucket)/\(ref.fullPath)") else {
                    continuation.resume(throwing: AppError.defaultError())
                    return
                }

                continuation.resume(returning: gsUrl)
            }
        }
    }
}
