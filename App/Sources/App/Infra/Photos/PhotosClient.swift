import Photos
import UIKit

final class PhotosClient: Sendable {
    func requestAuthorization() async -> LocalAssetAuthorizationStatus {
        return await withCheckedContinuation { continuation in
            PHPhotoLibrary.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
    }

    func getAlbums() async -> [LocalAssetCollection] {
        return await withCheckedContinuation { continuation in
            var albums = [PHAssetCollection]()

            let userAlbums = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .albumRegular, options: nil)
            userAlbums.enumerateObjects { collection, _, _ in
                albums.append(collection)
            }

            let smartAlbumSubtypes: [PHAssetCollectionSubtype] = [.smartAlbumFavorites, .smartAlbumRecentlyAdded, .smartAlbumVideos, .smartAlbumSlomoVideos, .smartAlbumTimelapses, .smartAlbumLongExposures, .smartAlbumAnimated, .smartAlbumCinematic, .smartAlbumSelfPortraits, .smartAlbumGeneric, .smartAlbumPanoramas]
            for subtype in smartAlbumSubtypes {
                let smartAlbums = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: subtype, options: nil)
                smartAlbums.enumerateObjects { collection, _, _ in
                    albums.append(collection)
                }
            }

            continuation.resume(returning: albums)
        }
    }

    func getAssets(
        album: PHAssetCollection? = nil,
        filter: AssetFilter? = nil
    ) async -> [LocalAsset] {
        return await withCheckedContinuation { continuation in
            var mediaTypeFilter = ""
            var mediaTypeParams: [Any] = []
            if let filter = filter {
                switch filter {
                case .photo:
                    mediaTypeFilter = "(mediaType == %d)"
                    mediaTypeParams = [
                        PHAssetMediaType.image.rawValue
                    ]
                case .video:
                    mediaTypeFilter = "(mediaType == %d)"
                    mediaTypeParams = [
                        PHAssetMediaType.video.rawValue
                    ]
                }
            } else {
                mediaTypeFilter = "(mediaType == %d || mediaType == %d)"
                mediaTypeParams = [
                    PHAssetMediaType.image.rawValue,
                    PHAssetMediaType.video.rawValue
                ]
            }

            let fetchOptions = PHFetchOptions()
            fetchOptions.predicate = NSPredicate(
                format: mediaTypeFilter,
                argumentArray: mediaTypeParams
            )
            fetchOptions.sortDescriptors = [
                NSSortDescriptor(key: "creationDate", ascending: false)
            ]

            var assets: [PHAsset] = []
            if let album = album {
                PHAsset.fetchAssets(in: album, options: fetchOptions).enumerateObjects { asset, _, _ in
                    assets.append(asset)
                }
            } else {
                PHAsset.fetchAssets(with: fetchOptions).enumerateObjects { asset, _, _ in
                    assets.append(asset)
                }
            }

            continuation.resume(returning: assets)
        }
    }

    func getAsset(id: String) async throws -> LocalAsset {
        return try await withCheckedThrowingContinuation { continuation in
            var assets: [PHAsset] = []
            PHAsset.fetchAssets(withLocalIdentifiers: [id], options: nil).enumerateObjects { asset, _, _ in
                assets.append(asset)
            }

            guard let asset = assets.first else {
                continuation.resume(throwing: AppError.plain("指定したデータが存在しません"))
                return
            }

            continuation.resume(returning: asset)
        }
    }

    func saveImage(image: UIImage) {
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
    }

    func saveVideo(url: URL) {
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
        }, completionHandler: nil)
    }

    func requestImage(asset: PHAsset, targetSize: CGSize) async throws -> UIImage {
        return try await withCheckedThrowingContinuation { continuation in
            let options = PHImageRequestOptions()
            options.deliveryMode = .opportunistic
            PHImageManager.default().requestImage(
                for: asset,
                targetSize: targetSize,
                contentMode: .aspectFill,
                options: options
            ) { image, _ in
                guard let image = image else {
                    continuation.resume(throwing: AppError.defaultError())
                    return
                }

                continuation.resume(returning: image)
            }
        }
    }

    func requestCachedImage(
        asset: PHAsset,
        targetSize: CGSize,
        completion: @escaping (UIImage?) -> ()
    ) -> PHImageRequestID {
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .opportunistic

        return PHCachingImageManager.default().requestImage(
            for: asset,
            targetSize: targetSize,
            contentMode: .aspectFill,
            options: options,
            resultHandler: { image, _ in
                completion(image)
            }
        )
    }

    func requestFullImage(asset: PHAsset) async throws -> UIImage {
        return try await withCheckedThrowingContinuation { continuation in
            let options = PHImageRequestOptions()
            options.deliveryMode = .highQualityFormat
            PHImageManager.default().requestImage(
                for: asset,
                targetSize: PHImageManagerMaximumSize,
                contentMode: .aspectFill,
                options: options
            ) { image, _ in
                guard let image = image else {
                    continuation.resume(throwing: AppError.defaultError())
                    return
                }

                continuation.resume(returning: image)
            }
        }
    }

    func requestImageData(asset: PHAsset) async throws -> Data {
        return try await withCheckedThrowingContinuation { continuation in
            let options = PHImageRequestOptions()
            options.deliveryMode = .highQualityFormat
            PHImageManager.default().requestImageDataAndOrientation(
                for: asset,
                options: options
            ) { data, _, _, _ in
                guard let data = data, let jpegData = UIImage(data: data)?.jpegData(compressionQuality: 1) else {
                    continuation.resume(throwing: AppError.defaultError())
                    return
                }
                
                continuation.resume(returning: jpegData)
            }
        }
    }

    func requestFullVideo(asset: PHAsset) async throws -> AVAsset {
        return try await withCheckedThrowingContinuation { continuation in
            let options = PHVideoRequestOptions()
            options.deliveryMode = .highQualityFormat
            options.isNetworkAccessAllowed = true
            PHImageManager.default().requestAVAsset(
                forVideo: asset,
                options: options
            ) { avAsset, _, _ in
                guard let avAsset = avAsset else {
                    continuation.resume(throwing: AppError.defaultError())
                    return
                }

                continuation.resume(returning: avAsset)
            }
        }
    }

    func requestVideoData(asset: PHAsset) async throws -> Data {
        return try await withCheckedThrowingContinuation { continuation in
            let options = PHVideoRequestOptions()
            options.deliveryMode = .highQualityFormat
            options.isNetworkAccessAllowed = true

            PHImageManager.default().requestAVAsset(forVideo: asset, options: options) { avAsset, _, _ in
                guard let avAsset = avAsset else {
                    continuation.resume(throwing: AppError.defaultError())
                    return
                }

                guard let urlAsset = avAsset as? AVURLAsset else {
                    continuation.resume(throwing: AppError.defaultError())
                    return
                }

                do {
                    let data = try Data(contentsOf: urlAsset.url)
                    continuation.resume(returning: data)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}

typealias LocalAssetAuthorizationStatus = PHAuthorizationStatus
typealias LocalAssetCollection = PHAssetCollection
typealias LocalAsset = PHAsset

enum AssetFilter {
    case photo
    case video
}

extension AVAsset: @unchecked @retroactive Sendable {}
