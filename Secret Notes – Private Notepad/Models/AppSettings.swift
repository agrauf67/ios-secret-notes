import Foundation
import SwiftUI

@Observable
final class AppSettings {
    var sortOrder: SortOrder {
        get { SortOrder(rawValue: UserDefaults.standard.string(forKey: "sortOrder") ?? "") ?? .byDate }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: "sortOrder") }
    }

    var sortDirection: SortDirection {
        get { SortDirection(rawValue: UserDefaults.standard.string(forKey: "sortDirection") ?? "") ?? .descending }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: "sortDirection") }
    }

    var themeMode: ThemeMode {
        get { ThemeMode(rawValue: UserDefaults.standard.string(forKey: "themeMode") ?? "") ?? .system }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: "themeMode") }
    }

    var colorTheme: ColorTheme {
        get { ColorTheme(rawValue: UserDefaults.standard.string(forKey: "colorTheme") ?? "") ?? .green }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: "colorTheme") }
    }

    var showText: Bool {
        get { UserDefaults.standard.object(forKey: "showText") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "showText") }
    }

    var showRating: Bool {
        get { UserDefaults.standard.object(forKey: "showRating") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "showRating") }
    }

    var showCategory: Bool {
        get { UserDefaults.standard.object(forKey: "showCategory") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "showCategory") }
    }

    var showFolders: Bool {
        get { UserDefaults.standard.object(forKey: "showFolders") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "showFolders") }
    }

    var showCreatedUpdated: Bool {
        get { UserDefaults.standard.object(forKey: "showCreatedUpdated") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "showCreatedUpdated") }
    }

    var maxPreviewLines: Int {
        get { UserDefaults.standard.object(forKey: "maxLines") as? Int ?? 3 }
        set { UserDefaults.standard.set(newValue, forKey: "maxLines") }
    }

    var historyLimit: Int {
        get { UserDefaults.standard.object(forKey: "historyLimit") as? Int ?? 50 }
        set { UserDefaults.standard.set(newValue, forKey: "historyLimit") }
    }
}
