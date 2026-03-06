import Foundation
import SwiftData

enum AttachmentType: String, Codable {
    case image = "IMAGE"
    case pdf = "PDF"
    case audio = "AUDIO"
    case document = "DOCUMENT"
}

@Model
final class NoteAttachment {
    var noteId: PersistentIdentifier?
    var filePath: String = ""
    var mimeType: String = ""
    var originalFileName: String = ""
    var fileSize: Int64 = 0
    var attachmentTypeRaw: String = AttachmentType.document.rawValue
    var createdAt: Date = Date()

    var attachmentType: AttachmentType {
        get { AttachmentType(rawValue: attachmentTypeRaw) ?? .document }
        set { attachmentTypeRaw = newValue.rawValue }
    }

    init(filePath: String, mimeType: String, originalFileName: String, fileSize: Int64, attachmentType: AttachmentType) {
        self.filePath = filePath
        self.mimeType = mimeType
        self.originalFileName = originalFileName
        self.fileSize = fileSize
        self.attachmentTypeRaw = attachmentType.rawValue
    }
}
