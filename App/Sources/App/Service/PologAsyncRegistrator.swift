import Foundation

actor PologAsyncRegistrator {
    private let gqlClient: GraphQLClient
    private let swiftDataClient: SwiftDataClient
    private let photosClient: PhotosClient
    private let storageClient: FirebaseStorageClient
    private var isRunning: Bool = false

    init(
        gqlClient: GraphQLClient,
        swiftDataClient: SwiftDataClient,
        photosClient: PhotosClient,
        storageClient: FirebaseStorageClient)
    {
        self.gqlClient = gqlClient
        self.swiftDataClient = swiftDataClient
        self.photosClient = photosClient
        self.storageClient = storageClient
    }

    private func register() async {
        do {
            let context = swiftDataClient.modelContext
            let stagings: [SD_StagingPolog] = try swiftDataClient.fetch(context: context)
            print("PologAsyncRegistrator stagings count: \(stagings.count)")
            for staging in stagings {
                if staging.finishedAt != nil {
                    try swiftDataClient.delete(item: staging, context: context)
                    continue
                }

                guard let polog = staging.polog else {
                    continue
                }

                var current: Polog?
                do {
                    current = try (await gqlClient.query(PologAPI.GetPologQuery(pologId: polog.id))).polog.fragments.pologFragment
                } catch {
                    if let appError = error as? AppError {
                        switch appError {
                        case .notFound:
                            break
                        default:
                            throw error
                        }
                    } else {
                        throw error
                    }
                }

                var assetGsUrls: [String?] = []
                for route in Array(polog.routes) {
                    var assetGsUrl: String?
                    if let existed = current?.routes.first(where: {
                        route.id == "\(current!.id)_\($0.id)"
                    }) {
                        assetGsUrl = existed.assetGsUrl
                    }
                    if let uploaded = staging.uploadedRoutes.first(where: { $0.id == route.id }) {
                        assetGsUrl = uploaded.assetGsUrl
                    }
                    assetGsUrls.append(assetGsUrl)
                }

                staging.totalUploadCount = assetGsUrls.filter { $0 != nil }.count
                try swiftDataClient.save(item: staging, context: context)

                var routeInputs: [PologAPI.PologRouteInput] = []
                for (i, route) in Array(polog.routes).enumerated() {
                    if assetGsUrls[i] == nil {
                        var assetData: Data!
                        var assetFilePath: String!
                        var assetContentType: String!
                        switch route.assetSource {
                        case .local:
                            let asset = try await photosClient.getAsset(id: route.assetId)
                            if asset.isVideo {
                                assetData = try await photosClient.requestVideoData(asset: asset)
                                assetFilePath = "\(pologRouteAssetPath)/\(route.id).mp4"
                                assetContentType = "video/mp4"
                            } else {
                                assetData = try await photosClient.requestImageData(asset: asset)
                                assetFilePath = "\(pologRouteAssetPath)/\(route.id).jpeg"
                                assetContentType = "image/jpeg"
                            }
                        case .groupAsset:
                            let asset = try (await gqlClient.query(PologAPI.GetGroupAssetQuery(assetId: route.assetId))).groupAsset.fragments.groupAssetFragment
                            assetData = try await URLSession.shared.loadDataFrom(url: asset.signedUrl.url!)
                            if asset.isVideo {
                                assetFilePath = "\(pologRouteAssetPath)/\(route.id).mp4"
                                assetContentType = "video/mp4"
                            } else {
                                assetFilePath = "\(pologRouteAssetPath)/\(route.id).jpeg"
                                assetContentType = "image/jpeg"
                            }
                        case .pologThumbnail, .pologRouteAsset:
                            throw AppError.defaultError()
                        }

                        let gsUrl = try await storageClient.upload(data: assetData, contentType: assetContentType, filePath: assetFilePath)
                        let uploadedRoute = SD_UploadedRoute(id: route.id, assetGsUrl: gsUrl.absoluteString)
                        staging.uploadedRoutes.append(uploadedRoute)
                        try swiftDataClient.save(item: staging, context: context)
                        assetGsUrls[i] = gsUrl.absoluteString
                    }

                    var routeInput = PologAPI.PologRouteInput(
                        assetGsUrl: assetGsUrls[i]!,
                        assetKind: GraphQLEnum(route.assetKind),
                        assetDate: route.assetDate!.iso8601String,
                        description: gqlOption(route._description),
                        priceLabel: gqlOption(route.priceLabel),
                        review: gqlOption(route.review),
                        transportations: route.transportations.map { GraphQLEnum($0) },
                        isIncludeIndex: route.isIncludeIndex,
                        spotId: gqlOption(nil))
                    if route.assetKind == .video {
                        routeInput.videoInput = gqlOption(PologAPI.PologRouteVideoInput(
                            startSecond: Int(route.videoStartSeconds),
                            endSecond: Int(route.videoEndSeconds),
                            isMute: route.isVideoMuted))
                    }
                    routeInputs.append(routeInput)
                }

                let thumbnailFilePath = "\(pologThumbnailPath)/\(polog.thumbnailAssetId!).jpeg"
                let thumbnailContentType = "image/jpeg"
                let thumbnailGsUrl: URL!
                switch polog.thumbnailAssetSource {
                case .local:
                    let asset = try await photosClient.getAsset(id: polog.thumbnailAssetId!)
                    let data = try await photosClient.requestImageData(asset: asset)
                    thumbnailGsUrl = try await storageClient.upload(data: data, contentType: thumbnailContentType, filePath: thumbnailFilePath)
                case .groupAsset:
                    let asset = try (await gqlClient.query(PologAPI.GetGroupAssetQuery(assetId: polog.thumbnailAssetId!))).groupAsset.fragments.groupAssetFragment
                    let data = try await URLSession.shared.loadDataFrom(url: asset.signedUrl.url!)
                    thumbnailGsUrl = try await storageClient.upload(data: data, contentType: thumbnailContentType, filePath: thumbnailFilePath)
                case .pologThumbnail:
                    thumbnailGsUrl = current!.thumbnailGsUrl.url!
                case .pologRouteAsset, .none:
                    throw AppError.defaultError()
                }

                do {
                    if current != nil {
                        _ = try await gqlClient.mutation(PologAPI.UpdatePologMutation(
                            id: polog.id,
                            title: polog.title,
                            forewordHtml: polog.forewordHtml ?? "",
                            afterwordHtml: polog.afterwordHtml ?? "",
                            thumbnailGsUrl: thumbnailGsUrl.absoluteString,
                            companionIds: polog.innerCompanionIds,
                            outerCompanionNames: polog.outerCompanionNames,
                            visibility: GraphQLEnum(polog.visibility!),
                            label: PologAPI.PologLabelInput(
                                label1: polog.label?.label1 ?? "",
                                label2: polog.label?.label2 ?? "",
                                label3: polog.label?.label3 ?? ""),
                            tags: polog.tags,
                            isCommentable: polog.isCommentable,
                            routes: routeInputs))
                    } else {
                        _ = try await gqlClient.mutation(PologAPI.CreatePologMutation(
                            appLocalId: polog.id,
                            title: polog.title,
                            forewordHtml: polog.forewordHtml ?? "",
                            afterwordHtml: polog.afterwordHtml ?? "",
                            thumbnailGsUrl: thumbnailGsUrl.absoluteString,
                            companionIds: polog.innerCompanionIds,
                            outerCompanionNames: polog.outerCompanionNames,
                            visibility: GraphQLEnum(polog.visibility!),
                            label: PologAPI.PologLabelInput(
                                label1: polog.label?.label1 ?? "",
                                label2: polog.label?.label2 ?? "",
                                label3: polog.label?.label3 ?? ""),
                            tags: polog.tags,
                            isCommentable: polog.isCommentable,
                            routes: routeInputs))
                    }

                    staging.finishedAt = Date()
                    try swiftDataClient.save(item: staging, context: context)
                } catch {
                    if let appError = error as? AppError {
                        switch appError {
                        case .alreadyExist:
                            staging.finishedAt = Date()
                            try swiftDataClient.save(item: staging, context: context)
                        default:
                            throw error
                        }
                    } else {
                        throw error
                    }
                }
            }
        } catch {
            print("PologAsyncRegistrator error: \(error)")
        }
    }

    func start() {
        if isRunning { return }

        isRunning = true

        Task {
            while isRunning {
                await register()
                try! await Task.sleep(nanoseconds: 5_000_000_000)
            }
        }
    }

    func stop() {
        isRunning = false
    }
}
