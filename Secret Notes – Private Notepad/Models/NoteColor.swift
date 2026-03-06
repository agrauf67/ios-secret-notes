import SwiftUI

enum NoteColor: String, CaseIterable, Identifiable {
    case none = ""
    case redOrange = "FF6B6B"
    case redPink = "FF8FA3"
    case babyBlue = "8ECAE6"
    case violet = "B197FC"
    case lightGreen = "95D5B2"
    case lightBlue = "89CFF0"
    case sunnyYellow = "FFD93D"
    case orange = "FFB347"
    case mintGreen = "AAF0D1"
    case teal = "80CBC4"
    case indigo = "7986CB"
    case purple = "CE93D8"
    case beige = "F5E6CC"

    var id: String { rawValue }

    var color: Color? {
        guard !rawValue.isEmpty else { return nil }
        return Color(hex: rawValue)
    }

    var displayName: String {
        switch self {
        case .none: "Default"
        case .redOrange: "Red Orange"
        case .redPink: "Red Pink"
        case .babyBlue: "Baby Blue"
        case .violet: "Violet"
        case .lightGreen: "Light Green"
        case .lightBlue: "Light Blue"
        case .sunnyYellow: "Sunny Yellow"
        case .orange: "Orange"
        case .mintGreen: "Mint Green"
        case .teal: "Teal"
        case .indigo: "Indigo"
        case .purple: "Purple"
        case .beige: "Beige"
        }
    }
}
