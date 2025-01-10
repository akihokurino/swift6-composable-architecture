import AuthenticationServices
import Firebase
import FirebaseAuth
import Foundation
import GoogleSignIn
import UIKit

final class FirebaseAuthClient: Sendable {
    private let appleProviderId = "apple.com"
    private let googleProviderId = "google.com"

    init() {}

    var isLogin: Bool {
        return Auth.auth().currentUser != nil
    }

    var currentUserId: String? {
        return Auth.auth().currentUser?.uid
    }

    func logout() throws {
        try Auth.auth().signOut()
    }

    func getAccessToken() async throws -> String {
        guard let me = Auth.auth().currentUser else {
            return ""
        }

        return try await withCheckedThrowingContinuation { continuation in
            me.getIDTokenForcingRefresh(true) { idToken, error in
                if let error = error {
                    continuation.resume(throwing: AppError.plain(error.localizedDescription))
                    return
                }

                guard let token = idToken else {
                    continuation.resume(throwing: AppError.defaultError())
                    return
                }

                continuation.resume(returning: token)
            }
        }
    }

    func loginByApple(appleIDCredential: ASAuthorizationAppleIDCredential, nonce: String) async throws -> LoginProviderInfo {
        guard let appleIDToken = appleIDCredential.identityToken else {
            throw AppError.defaultError()
        }
        guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
            throw AppError.defaultError()
        }

        let credential = OAuthProvider.appleCredential(withIDToken: idTokenString, rawNonce: nonce, fullName: appleIDCredential.fullName)

        return try await withCheckedThrowingContinuation { [weak self] continuation in
            Auth.auth().signIn(with: credential) { result, error in
                if let error = error {
                    continuation.resume(throwing: AppError.plain(error.localizedDescription))
                    return
                }

                guard result?.user != nil else {
                    continuation.resume(throwing: AppError.defaultError())
                    return
                }

                guard let weakSelf = self else {
                    continuation.resume(throwing: AppError.defaultError())
                    return
                }

                do {
                    try continuation.resume(returning: weakSelf.getProviderInfo(id: weakSelf.appleProviderId))
                } catch {
                    let message = (error as? AppError)?.localizedDescription ?? error.localizedDescription
                    continuation.resume(throwing: AppError.plain(message))
                }
            }
        }
    }

    func loginByGoogle(withPresenting: UIViewController) async throws -> LoginProviderInfo {
        guard let clientID: String = FirebaseApp.app()?.options.clientID else {
            throw AppError.defaultError()
        }

        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        return try await withCheckedThrowingContinuation { [weak self] continuation in
            GIDSignIn.sharedInstance.signIn(withPresenting: withPresenting) { result, error in
                if let error = error {
                    continuation.resume(throwing: AppError.plain(error.localizedDescription))
                    return
                }

                guard let user = result?.user, let idToken = user.idToken?.tokenString else {
                    continuation.resume(throwing: AppError.defaultError())
                    return
                }

                let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: user.accessToken.tokenString)

                Auth.auth().signIn(with: credential) { result, error in
                    if let error = error {
                        continuation.resume(throwing: AppError.plain(error.localizedDescription))
                        return
                    }

                    guard result?.user != nil else {
                        continuation.resume(throwing: AppError.defaultError())
                        return
                    }

                    guard let weakSelf = self else {
                        continuation.resume(throwing: AppError.defaultError())
                        return
                    }

                    do {
                        try continuation.resume(returning: weakSelf.getProviderInfo(id: weakSelf.googleProviderId))
                    } catch {
                        let message = (error as? AppError)?.localizedDescription ?? error.localizedDescription
                        continuation.resume(throwing: AppError.plain(message))
                    }
                }
            }
        }
    }

    func sendSMSPinCode(phoneNumber: String) async throws -> String {
        Auth.auth().languageCode = "jp"
        return try await withCheckedThrowingContinuation { continuation in
            PhoneAuthProvider.provider().verifyPhoneNumber(phoneNumber, uiDelegate: nil) { verificationId, error in
                if let error = error {
                    continuation.resume(throwing: AppError.plain(error.localizedDescription))
                    return
                }

                guard let verificationId = verificationId else {
                    continuation.resume(throwing: AppError.defaultError())
                    return
                }

                continuation.resume(returning: verificationId)
            }
        }
    }

    func loginByPhoneNumber(code: String, verificationId: String) async throws -> LoginProviderInfo {
        let credential = PhoneAuthProvider.provider().credential(
            withVerificationID: verificationId,
            verificationCode: code
        )

        return try await withCheckedThrowingContinuation { continuation in
            Auth.auth().signIn(with: credential) { result, error in
                if let error = error {
                    continuation.resume(throwing: AppError.plain(error.localizedDescription))
                    return
                }

                guard let user = result?.user else {
                    continuation.resume(throwing: AppError.defaultError())
                    return
                }

                continuation.resume(returning: LoginProviderInfo(name: user.displayName ?? "", profileUrl: nil))
            }
        }
    }

    private func getProviderInfo(id: String) throws -> LoginProviderInfo {
        if let user = Auth.auth().currentUser {
            for profile in user.providerData {
                if profile.providerID == id {
                    return LoginProviderInfo(name: profile.displayName ?? "unknown", profileUrl: profile.photoURL)
                }
            }
        }

        throw AppError.plain("不明なプロバイダーIDです")
    }
}

struct LoginProviderInfo: Equatable {
    let name: String
    let profileUrl: URL?
}
