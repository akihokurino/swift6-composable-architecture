import CryptoKit
import Foundation
import UIKit

@MainActor
func windowWidth() -> CGFloat {
    let scenes = UIApplication.shared.connectedScenes
    if let windowScene = scenes.first as? UIWindowScene, let window = windowScene.windows.first {
        return window.frame.width
    }
    return UIScreen.main.bounds.size.width
}

@MainActor
func windowHeight() -> CGFloat {
    let scenes = UIApplication.shared.connectedScenes
    if let windowScene = scenes.first as? UIWindowScene, let window = windowScene.windows.first {
        return window.frame.height
    }
    return UIScreen.main.bounds.size.height
}

func randomNonceString(length: Int = 32) -> String {
    precondition(length > 0)
    let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
    var result = ""
    var remainingLength = length

    while remainingLength > 0 {
        let randoms: [UInt8] = (0 ..< 16).map { _ in
            var random: UInt8 = 0
            let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
            if errorCode != errSecSuccess {
                fatalError(
                    "Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)"
                )
            }
            return random
        }

        for random in randoms {
            if remainingLength == 0 {
                continue
            }

            if random < charset.count {
                result.append(charset[Int(random)])
                remainingLength -= 1
            }
        }
    }

    return result
}

func sha256(_ input: String) -> String {
    let inputData = Data(input.utf8)
    let hashedData = SHA256.hash(data: inputData)
    let hashString = hashedData.compactMap {
        String(format: "%02x", $0)
    }.joined()

    return hashString
}
