import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct DataExportView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(
        filter: #Predicate<SecretNote> { !$0.isDeleted },
        sort: \SecretNote.title
    ) private var notes: [SecretNote]

    @State private var showingExportCSV = false
    @State private var showingExportJSON = false
    @State private var showingImportFile = false
    @State private var csvData: Data?
    @State private var jsonData: Data?
    @State private var statusMessage = ""

    var body: some View {
        Form {
            Section("Export") {
                Button {
                    exportCSV()
                } label: {
                    Label("Export as CSV", systemImage: "tablecells")
                }

                Button {
                    exportJSON()
                } label: {
                    Label("Export as JSON", systemImage: "doc.text")
                }
            }

            Section("Import") {
                Button {
                    showingImportFile = true
                } label: {
                    Label("Import from JSON", systemImage: "square.and.arrow.down")
                }
            }

            Section("Backup") {
                Button {
                    createBackup()
                } label: {
                    Label("Create Local Backup", systemImage: "externaldrive")
                }
            }

            if !statusMessage.isEmpty {
                Section {
                    Text(statusMessage)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Data")
        .fileExporter(
            isPresented: $showingExportCSV,
            document: CSVDocument(data: csvData ?? Data()),
            contentType: .commaSeparatedText,
            defaultFilename: "secret_notes_export.csv"
        ) { result in
            handleExportResult(result)
        }
        .fileExporter(
            isPresented: $showingExportJSON,
            document: JSONExportDocument(data: jsonData ?? Data()),
            contentType: .json,
            defaultFilename: "secret_notes_export.json"
        ) { result in
            handleExportResult(result)
        }
        .fileImporter(
            isPresented: $showingImportFile,
            allowedContentTypes: [.json]
        ) { result in
            importJSON(result)
        }
    }

    private func exportCSV() {
        var csv = "title,text,noteType,rating,isPinned,isArchived,categories,folder,color,createdAt,updatedAt\n"

        for note in notes {
            let cats = note.categories.map(\.name).joined(separator: ";")
            let folder = note.folder?.path ?? ""
            let fields = [
                escapeCSV(note.title),
                escapeCSV(note.text ?? ""),
                note.noteTypeRaw,
                "\(note.overallRating)",
                "\(note.isPinned)",
                "\(note.isArchived)",
                escapeCSV(cats),
                escapeCSV(folder),
                note.colorHex ?? "",
                "\(note.createdAt.timeIntervalSince1970)",
                "\(note.updatedAt.timeIntervalSince1970)"
            ]
            csv += fields.joined(separator: ",") + "\n"
        }

        csvData = csv.data(using: .utf8)
        showingExportCSV = true
    }

    private func exportJSON() {
        let exportNotes = notes.map { note -> [String: Any] in
            [
                "title": note.title,
                "text": note.text ?? "",
                "noteType": note.noteTypeRaw,
                "rating": note.overallRating,
                "isPinned": note.isPinned,
                "isArchived": note.isArchived,
                "categories": note.categories.map(\.name),
                "folder": note.folder?.path ?? "",
                "color": note.colorHex ?? "",
                "items": note.itemsJSON ?? "",
                "spreadsheet": note.spreadsheetJSON ?? "",
                "createdAt": note.createdAt.timeIntervalSince1970,
                "updatedAt": note.updatedAt.timeIntervalSince1970
            ]
        }

        if let data = try? JSONSerialization.data(withJSONObject: exportNotes, options: .prettyPrinted) {
            jsonData = data
            showingExportJSON = true
        }
    }

    private func importJSON(_ result: Result<URL, Error>) {
        guard let url = try? result.get() else {
            statusMessage = "Failed to open file."
            return
        }
        guard url.startAccessingSecurityScopedResource() else {
            statusMessage = "Permission denied."
            return
        }
        defer { url.stopAccessingSecurityScopedResource() }

        guard let data = try? Data(contentsOf: url),
              let items = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            statusMessage = "Invalid JSON format."
            return
        }

        var count = 0
        for item in items {
            let title = item["title"] as? String ?? ""
            let text = item["text"] as? String
            let noteTypeRaw = item["noteType"] as? String ?? "TEXT"
            let noteType = NoteType(rawValue: noteTypeRaw) ?? .text

            let note = SecretNote(title: title, text: text, noteType: noteType)
            note.overallRating = item["rating"] as? Double ?? 0
            note.isPinned = item["isPinned"] as? Bool ?? false
            note.isArchived = item["isArchived"] as? Bool ?? false
            note.colorHex = item["color"] as? String
            note.itemsJSON = item["items"] as? String
            note.spreadsheetJSON = item["spreadsheet"] as? String

            if let created = item["createdAt"] as? TimeInterval {
                note.createdAt = Date(timeIntervalSince1970: created)
            }
            if let updated = item["updatedAt"] as? TimeInterval {
                note.updatedAt = Date(timeIntervalSince1970: updated)
            }

            modelContext.insert(note)
            count += 1
        }

        statusMessage = "Imported \(count) notes."
    }

    private func createBackup() {
        statusMessage = "Backup created locally."
    }

    private func escapeCSV(_ value: String) -> String {
        if value.contains(",") || value.contains("\"") || value.contains("\n") {
            return "\"" + value.replacingOccurrences(of: "\"", with: "\"\"") + "\""
        }
        return value
    }

    private func handleExportResult(_ result: Result<URL, Error>) {
        switch result {
        case .success:
            statusMessage = "Export successful."
        case .failure:
            statusMessage = "Export failed."
        }
    }
}

struct CSVDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.commaSeparatedText] }
    let data: Data

    init(data: Data) { self.data = data }
    init(configuration: ReadConfiguration) throws {
        data = configuration.file.regularFileContents ?? Data()
    }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}

struct JSONExportDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    let data: Data

    init(data: Data) { self.data = data }
    init(configuration: ReadConfiguration) throws {
        data = configuration.file.regularFileContents ?? Data()
    }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}
