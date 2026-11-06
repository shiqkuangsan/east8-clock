import Foundation

struct ClockSnapshot {
    let beijing: String
    let losAngeles: String

    init(date: Date) {
        beijing = Self.beijingFormatter.string(from: date)
        losAngeles = Self.losAngelesFormatter.string(from: date)
    }

    private static let beijingFormatter = formatter(for: TimeZone(secondsFromGMT: 8 * 3600)!)
    private static let losAngelesFormatter = formatter(for: TimeZone(identifier: "America/Los_Angeles")!)

    private static func formatter(for timeZone: TimeZone) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = timeZone
        formatter.dateFormat = "M月d日 EEE HH:mm"
        return formatter
    }
}
