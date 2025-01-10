import Foundation

public extension Date {
    var dateDisplayJST: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy年MM月dd日"
        return formatter.string(from: self)
    }

    var dateTimeDisplayJST: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy年MM月dd日 HH:mm"
        return formatter.string(from: self)
    }

    var ymDisplayJST: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy年MM月"
        return formatter.string(from: self)
    }

    var dateTimeString: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return dateFormatter.string(from: self)
    }

    var dateString: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return dateFormatter.string(from: self)
    }

    var timeString: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        return dateFormatter.string(from: self)
    }

    var timeDisplayUS: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateFormat = "a h:mm"
        return formatter.string(from: self)
    }

    var iso8601String: String {
        let formatter = ISO8601DateFormatter()
        return formatter.string(from: self)
    }

    func updateYMD(by: Date) -> Self {
        let calendar = Calendar.current

        let year = calendar.component(.year, from: by)
        let month = calendar.component(.month, from: by)
        let day = calendar.component(.day, from: by)

        let hour = calendar.component(.hour, from: self)
        let minute = calendar.component(.minute, from: self)
        let second = calendar.component(.second, from: self)

        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        components.second = second

        return calendar.date(from: components) ?? self
    }

    func updateHMS(by: Date) -> Self {
        let calendar = Calendar.current

        let year = calendar.component(.year, from: self)
        let month = calendar.component(.month, from: self)
        let day = calendar.component(.day, from: self)

        let hour = calendar.component(.hour, from: by)
        let minute = calendar.component(.minute, from: by)
        let second = calendar.component(.second, from: by)

        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        components.second = second

        return calendar.date(from: components) ?? self
    }

    func toUnitString(timeZone: TimeZone) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = .japan
        dateFormatter.timeZone = timeZone
        let day = Calendar.current.component(.day, from: self)
        if day <= 10 {
            dateFormatter.dateFormat = "yyyy'年'MMMM'上旬'"
        } else if (day > 10) && (day <= 20) {
            dateFormatter.dateFormat = "yyyy'年'MMMM'中旬'"
        } else if (day > 20) && (day <= 31) {
            dateFormatter.dateFormat = "yyyy'年'MMMM'下旬'"
        }
        return dateFormatter.string(from: self)
    }

    func calculateDateDifference(to endDate: Date) -> String {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day, .hour], from: self, to: endDate)

        guard let days = components.day, let hours = components.hour else {
            return "Invalid date components"
        }

        if days == 0 && hours < 24 {
            return "1日"
        } else {
            let nights = days
            return "\(nights)泊\(days + 1)日"
        }
    }

    func get(_ component: Calendar.Component, calendar: Calendar = Calendar.current) -> Int {
        return calendar.component(component, from: self)
    }
}

extension Locale {
    static let japan = Locale(identifier: "ja_JP")
}
