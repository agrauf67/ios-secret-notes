import Foundation
import SwiftData

@Model
final class Category {
    var syncId: UUID = UUID()
    var name: String = ""
    var isDeleted: Bool = false
    var isArchived: Bool = false
    var lockTimeoutRaw: String?

    @Relationship(inverse: \SecretNote.categories)
    var notes: [SecretNote] = []

    init(name: String) {
        self.name = name
    }
}
