import Foundation

enum LockTimeout: String, CaseIterable, Codable {
    case immediate = "IMMEDIATE"
    case oneMinute = "ONE_MINUTE"
    case fiveMinutes = "FIVE_MINUTES"
    case fifteenMinutes = "FIFTEEN_MINUTES"
    case never = "NEVER"

    var displayName: String {
        switch self {
        case .immediate: "Immediately"
        case .oneMinute: "After 1 minute"
        case .fiveMinutes: "After 5 minutes"
        case .fifteenMinutes: "After 15 minutes"
        case .never: "Never"
        }
    }

    var intervalSeconds: TimeInterval? {
        switch self {
        case .immediate: 0
        case .oneMinute: 60
        case .fiveMinutes: 300
        case .fifteenMinutes: 900
        case .never: nil
        }
    }
}
