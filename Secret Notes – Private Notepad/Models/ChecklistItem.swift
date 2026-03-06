import Foundation

struct ChecklistItem: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var text: String
    var isChecked: Bool = false
    var doneAt: Date?
    var parentId: UUID?
    var position: Int

    var isParent: Bool { parentId == nil }
}
