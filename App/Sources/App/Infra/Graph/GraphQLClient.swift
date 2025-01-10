import Apollo
import Foundation

final class GraphQLClient: Sendable {
    private let apiBaseURL: URL
    private let authClient: FirebaseAuthClient

    init(config: Config, authClient: FirebaseAuthClient) {
        self.apiBaseURL = URL(string: config.apiBaseUrl)!
        self.authClient = authClient
    }

    private func apollo() async throws -> ApolloClient {
        let token = try await authClient.getAccessToken()

        let client = URLSessionClient(sessionConfiguration: URLSessionConfiguration.default)
        let store = ApolloStore(cache: InMemoryNormalizedCache())
        let provider = DefaultInterceptorProvider(client: client, store: store)
        let transport = RequestChainNetworkTransport(
            interceptorProvider: provider,
            endpointURL: self.apiBaseURL,
            additionalHeaders: [
                "Authorization": "Bearer \(token)",
            ]
        )

        return ApolloClient(networkTransport: transport, store: store)
    }

    func query<Query>(_ query: Query) async throws -> Query.Data where Query: GraphQLQuery, Query.Data: Sendable {
        let cli = try await apollo()
        return try await withCheckedThrowingContinuation { [weak self] continuation in
            cli.fetch(query: query, cachePolicy: .fetchIgnoringCacheCompletely) { result in
                switch result {
                case let .success(result):
                    guard let weakSelf = self else {
                        continuation.resume(throwing: AppError.defaultError())
                        return
                    }
                    if let errors = result.errors {
                        continuation.resume(throwing: weakSelf.handleError(errors))
                        return
                    }
                    guard let data = result.data else {
                        continuation.resume(throwing: AppError.defaultError())
                        return
                    }

                    continuation.resume(returning: data)
                case let .failure(error):
                    continuation.resume(throwing: AppError.plain(error.localizedDescription))
                }
            }
        }
    }

    func mutation<Mutation>(_ mutation: Mutation) async throws -> Mutation.Data where Mutation: GraphQLMutation, Mutation.Data: Sendable {
        let cli = try await apollo()
        return try await withCheckedThrowingContinuation { [weak self] continuation in
            cli.perform(mutation: mutation) { result in
                switch result {
                case let .success(result):
                    guard let weakSelf = self else {
                        continuation.resume(throwing: AppError.defaultError())
                        return
                    }
                    if let errors = result.errors {
                        continuation.resume(throwing: weakSelf.handleError(errors))
                        return
                    }
                    guard let data = result.data else {
                        continuation.resume(throwing: AppError.defaultError())
                        return
                    }

                    continuation.resume(returning: data)
                case let .failure(error):
                    continuation.resume(throwing: AppError.plain(error.localizedDescription))
                }
            }
        }
    }

    private func handleError(_ errors: [GraphQLError]) -> AppError {
        for error in errors {
            if let data = error.extensions as? [String: AnyHashable], let code = data["code"] as? Int, code == 401 {
                return AppError.unAuthorize
            }
            if let data = error.extensions as? [String: AnyHashable], let code = data["code"] as? Int, code == 404 {
                return AppError.notFound
            }
            if let data = error.extensions as? [String: AnyHashable], let code = data["code"] as? Int, code == 409 {
                return AppError.alreadyExist
            }
        }

        if !errors.filter({ $0.message != nil }).isEmpty {
            let messages = errors.filter { $0.message != nil }.map { $0.message! }
            return AppError.plain(messages.joined(separator: "\n"))
        }

        return AppError.defaultError()
    }
}

func gqlOption<T>(_ val: T?) -> GraphQLNullable<T> {
    guard let val = val else {
        return .none
    }
    return .some(val)
}

func gqlEnum<T>(_ val: T) -> GraphQLEnum<T> {
    return GraphQLEnum(val)
}

func gqlEnumOption<T>(_ val: T?) -> GraphQLNullable<GraphQLEnum<T>> {
    guard let val = val else {
        return .none
    }
    return .some(GraphQLEnum(val))
}
