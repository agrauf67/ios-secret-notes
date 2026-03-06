import SwiftUI

enum ColorTheme: String, CaseIterable {
    case green = "GREEN"
    case blue = "BLUE"
    case purple = "PURPLE"
    case orange = "ORANGE"
    case red = "RED"
    case teal = "TEAL"
    case pink = "PINK"
    case grey = "GREY"

    var displayName: String {
        switch self {
        case .green: "Green"
        case .blue: "Blue"
        case .purple: "Purple"
        case .orange: "Orange"
        case .red: "Red"
        case .teal: "Teal"
        case .pink: "Pink"
        case .grey: "Grey"
        }
    }

    var accentColor: Color {
        switch self {
        case .green: Color(hex: "006622")
        case .blue: Color(hex: "003366")
        case .purple: Color(hex: "330066")
        case .orange: Color(hex: "663300")
        case .red: Color(hex: "660022")
        case .teal: Color(hex: "006666")
        case .pink: Color(hex: "660033")
        case .grey: Color(hex: "333333")
        }
    }
}

enum ThemeMode: String, CaseIterable {
    case light = "LIGHT"
    case dark = "DARK"
    case system = "SYSTEM"

    var displayName: String {
        switch self {
        case .light: "Light"
        case .dark: "Dark"
        case .system: "System"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .light: .light
        case .dark: .dark
        case .system: nil
        }
    }
}
