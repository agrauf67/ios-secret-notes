import Foundation
import SwiftData

@Model
final class Folder {
    var syncId: UUID = UUID()
    var name: String = ""
    var isDeleted: Bool = false
    var isArchived: Bool = false
    var sortOrder: Int = 0
    var colorHex: String?
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    var parent: Folder?

    @Relationship(inverse: \Folder.parent)
    var children: [Folder] = []

    @Relationship(inverse: \SecretNote.folder)
    var notes: [SecretNote] = []

    init(name: String, parent: Folder? = nil) {
        self.name = name
        self.parent = parent
    }

    var path: String {
        if let parent = parent {
            return parent.path + "/" + name
        }
        return name
    }
}
