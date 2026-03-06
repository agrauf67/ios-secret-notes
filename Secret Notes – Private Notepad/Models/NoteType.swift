import Foundation

enum NoteType: String, Codable, CaseIterable {
    case text = "TEXT"
    case checklist = "CHECKLIST"
    case spreadsheet = "SPREADSHEET"
    case markdown = "MARKDOWN"
    case audio = "AUDIO"

    var displayName: String {
        switch self {
        case .text: "Text"
        case .checklist: "Checklist"
        case .spreadsheet: "Spreadsheet"
        case .markdown: "Markdown"
        case .audio: "Audio"
        }
    }

    var iconName: String {
        switch self {
        case .text: "doc.text"
        case .checklist: "checklist"
        case .spreadsheet: "tablecells"
        case .markdown: "text.document"
        case .audio: "mic"
        }
    }
}
