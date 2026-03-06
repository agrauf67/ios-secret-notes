import Foundation
import SwiftData

@Model
final class NoteHistory {
    var noteId: PersistentIdentifier?
    var title: String = ""
    var text: String?
    var itemsJSON: String?
    var spreadsheetJSON: String?
    var categoriesJSON: String?
    var colorHex: String?
    var overallRating: Double = 0.0
    var noteTypeRaw: String = NoteType.text.rawValue
    var createdAt: Date = Date()

    init(from note: SecretNote) {
        self.noteId = note.persistentModelID
        self.title = note.title
        self.text = note.text
        self.itemsJSON = note.itemsJSON
        self.spreadsheetJSON = note.spreadsheetJSON
        self.categoriesJSON = {
            let names = note.categories.map(\.name)
            let data = try? JSONEncoder().encode(names)
            return data.flatMap { String(data: $0, encoding: .utf8) }
        }()
        self.colorHex = note.colorHex
        self.overallRating = note.overallRating
        self.noteTypeRaw = note.noteTypeRaw
    }
}
