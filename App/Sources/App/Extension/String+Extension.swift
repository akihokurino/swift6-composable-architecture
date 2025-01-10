import Foundation
import UIKit

extension String {
    var url: URL? {
        return URL(string: self)
    }

    var iso8601: Date? {
        let cleanedDateString = self.replacingOccurrences(of: "\\.\\d+Z$", with: "Z", options: .regularExpression)

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        return formatter.date(from: cleanedDateString)
    }

    var e164: String? {
        guard self.count == 11 else {
            return nil
        }
        return "+81" + String(self.dropFirst())
    }

    var dateTime: Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return dateFormatter.date(from: self)
    }

    var isRealEmpty: Bool {
        return self.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var isNotEmpty: Bool {
        return !self.isEmpty
    }

    func jsonStringToArray() -> Any? {
        guard let data = self.data(using: .utf8) else {
            return nil
        }
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
            return jsonObject
        } catch {
            print("JSON変換に失敗: \(error)")
            return nil
        }
    }
}
