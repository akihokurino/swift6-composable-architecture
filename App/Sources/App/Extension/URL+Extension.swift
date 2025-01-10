import Foundation

extension URL {
    var withoutQuery: URL {
        var components = URLComponents(url: self, resolvingAgainstBaseURL: false)!
        components.query = nil
        return components.url!
    }

    func queryValue(key: String) -> String? {
        return URLComponents(string: absoluteString)?.getParameterValue(for: key)
    }
}
