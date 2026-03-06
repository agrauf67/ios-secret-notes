import Foundation
import SwiftUI

@Observable
final class AppSettings {
    var sortOrder: SortOrder {
        didSet { UserDefaults.standard.set(sortOrder.rawValue, forKey: "sortOrder") }
    }

    var sortDirection: SortDirection {
        didSet { UserDefaults.standard.set(sortDirection.rawValue, forKey: "sortDirection") }
    }

    var themeMode: ThemeMode {
        didSet { UserDefaults.standard.set(themeMode.rawValue, forKey: "themeMode") }
    }

    var colorTheme: ColorTheme {
        didSet { UserDefaults.standard.set(colorTheme.rawValue, forKey: "colorTheme") }
    }

    var showText: Bool {
        didSet { UserDefaults.standard.set(showText, forKey: "showText") }
    }

    var showRating: Bool {
        didSet { UserDefaults.standard.set(showRating, forKey: "showRating") }
    }

    var showCategory: Bool {
        didSet { UserDefaults.standard.set(showCategory, forKey: "showCategory") }
    }

    var showFolders: Bool {
        didSet { UserDefaults.standard.set(showFolders, forKey: "showFolders") }
    }

    var showCreatedUpdated: Bool {
        didSet { UserDefaults.standard.set(showCreatedUpdated, forKey: "showCreatedUpdated") }
    }

    var maxPreviewLines: Int {
        didSet { UserDefaults.standard.set(maxPreviewLines, forKey: "maxLines") }
    }

    var historyLimit: Int {
        didSet { UserDefaults.standard.set(historyLimit, forKey: "historyLimit") }
    }

    init() {
        let defaults = UserDefaults.standard
        self.sortOrder = SortOrder(rawValue: defaults.string(forKey: "sortOrder") ?? "") ?? .byDate
        self.sortDirection = SortDirection(rawValue: defaults.string(forKey: "sortDirection") ?? "") ?? .descending
        self.themeMode = ThemeMode(rawValue: defaults.string(forKey: "themeMode") ?? "") ?? .system
        self.colorTheme = ColorTheme(rawValue: defaults.string(forKey: "colorTheme") ?? "") ?? .green
        self.showText = defaults.object(forKey: "showText") as? Bool ?? true
        self.showRating = defaults.object(forKey: "showRating") as? Bool ?? true
        self.showCategory = defaults.object(forKey: "showCategory") as? Bool ?? true
        self.showFolders = defaults.object(forKey: "showFolders") as? Bool ?? true
        self.showCreatedUpdated = defaults.object(forKey: "showCreatedUpdated") as? Bool ?? true
        self.maxPreviewLines = defaults.object(forKey: "maxLines") as? Int ?? 3
        self.historyLimit = defaults.object(forKey: "historyLimit") as? Int ?? 50
    }
}
