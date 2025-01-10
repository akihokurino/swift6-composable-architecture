import Foundation

extension URLComponents {
    func getParameterValue(for parameter: String) -> String? {
        self.queryItems?.first(where: { $0.name == parameter })?.value
    }
}
