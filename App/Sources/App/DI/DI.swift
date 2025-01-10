import ComposableArchitecture
import Foundation
import Nuke

struct Config {
    let apiBaseUrl = "https://\(Bundle.main.object(forInfoDictionaryKey: "Api Host") as! String)/graphql"
}

extension Config: DependencyKey {
    static let liveValue = Config()
}

extension GraphQLClient: DependencyKey {
    static let liveValue = GraphQLClient(config: Config.liveValue, authClient: FirebaseAuthClient.liveValue)
}

extension FirebaseAuthClient: DependencyKey {
    static let liveValue = FirebaseAuthClient()
}

extension FirebaseStorageClient: DependencyKey {
    static let liveValue = FirebaseStorageClient()
}

extension LocalNotificationClient: DependencyKey {
    static let liveValue = LocalNotificationClient()
}

extension PhotosClient: DependencyKey {
    static let liveValue = PhotosClient()
}

extension ImagePrefetcher: @retroactive DependencyKey {
    public static let liveValue = ImagePrefetcher(pipeline: ImagePipeline.custom())
}

extension SwiftDataClient: DependencyKey {
    static let liveValue = SwiftDataClient()
}

extension PologAsyncRegistrator: DependencyKey {
    static let liveValue = PologAsyncRegistrator(
        gqlClient: GraphQLClient.liveValue,
        swiftDataClient: SwiftDataClient.liveValue,
        photosClient: PhotosClient.liveValue,
        storageClient: FirebaseStorageClient.liveValue
    )
}

extension DependencyValues {
    var gqlClient: GraphQLClient {
        get { self[GraphQLClient.self] }
        set { self[GraphQLClient.self] = newValue }
    }

    var authClient: FirebaseAuthClient {
        get { self[FirebaseAuthClient.self] }
        set { self[FirebaseAuthClient.self] = newValue }
    }

    var storageClient: FirebaseStorageClient {
        get { self[FirebaseStorageClient.self] }
        set { self[FirebaseStorageClient.self] = newValue }
    }

    var localNotificationClient: LocalNotificationClient {
        get { self[LocalNotificationClient.self] }
        set { self[LocalNotificationClient.self] = newValue }
    }

    var photosClient: PhotosClient {
        get { self[PhotosClient.self] }
        set { self[PhotosClient.self] = newValue }
    }

    var imagePrefetcher: ImagePrefetcher {
        get { self[ImagePrefetcher.self] }
        set { self[ImagePrefetcher.self] = newValue }
    }

    var swiftDataClient: SwiftDataClient {
        get { self[SwiftDataClient.self] }
        set { self[SwiftDataClient.self] = newValue }
    }

    var pologAsyncRegistrator: PologAsyncRegistrator {
        get { self[PologAsyncRegistrator.self] }
        set { self[PologAsyncRegistrator.self] = newValue }
    }
}
