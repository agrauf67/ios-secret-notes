import Foundation
import SwiftData

@Model
final class SecretNote {
    var syncId: UUID = UUID()
    var title: String = ""
    var text: String?
    var itemsJSON: String?
    var noteTypeRaw: String = NoteType.text.rawValue
    var overallRating: Double = 0.0
    var isPinned: Bool = false
    var isDeleted: Bool = false
    var isArchived: Bool = false
    var reminderTime: Date?
    var colorHex: String?
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    var noteType: NoteType {
        get { NoteType(rawValue: noteTypeRaw) ?? .text }
        set { noteTypeRaw = newValue.rawValue }
    }

    var checklistItems: [ChecklistItem] {
        get {
            guard let data = itemsJSON?.data(using: .utf8) else { return [] }
            return (try? JSONDecoder().decode([ChecklistItem].self, from: data)) ?? []
        }
        set {
            let data = try? JSONEncoder().encode(newValue)
            itemsJSON = data.flatMap { String(data: $0, encoding: .utf8) }
        }
    }

    init(
        title: String = "",
        text: String? = nil,
        noteType: NoteType = .text
    ) {
        self.title = title
        self.text = text
        self.noteTypeRaw = noteType.rawValue
    }
}
