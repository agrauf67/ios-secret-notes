import Foundation

struct SpreadsheetData: Codable, Equatable {
    var columns: [SpreadsheetColumn]
    var rows: [SpreadsheetRow]

    init() {
        columns = [
            SpreadsheetColumn(name: "A"),
            SpreadsheetColumn(name: "B"),
            SpreadsheetColumn(name: "C")
        ]
        rows = [SpreadsheetRow(cells: [:])]
    }
}

struct SpreadsheetColumn: Codable, Identifiable, Equatable {
    var id = UUID()
    var name: String
    var position: Int = 0
    var widthDp: Double = 120
}

struct SpreadsheetRow: Codable, Identifiable, Equatable {
    var id = UUID()
    var cells: [String: String]
    var position: Int = 0
}
