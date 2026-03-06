import SwiftUI
import SwiftData

struct ArchiveView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(
        filter: #Predicate<SecretNote> { $0.isArchived && !$0.isDeleted },
        sort: \SecretNote.updatedAt,
        order: .reverse
    ) private var archivedNotes: [SecretNote]

    var body: some View {
        List {
            ForEach(archivedNotes) { note in
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Image(systemName: note.noteType.iconName)
                                .foregroundStyle(.secondary)
                                .font(.caption)
                            Text(note.title.isEmpty ? "Untitled" : note.title)
                                .font(.headline)
                                .lineLimit(1)
                        }
                        if let text = note.text, !text.isEmpty {
                            Text(text)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }
                        Text("Archived \(note.updatedAt.formatted(date: .abbreviated, time: .shortened))")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    Spacer()
                }
                .swipeActions(edge: .leading) {
                    Button {
                        note.isArchived = false
                        note.updatedAt = Date()
                    } label: {
                        Label("Unarchive", systemImage: "tray.and.arrow.up")
                    }
                    .tint(.blue)
                }
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        note.isDeleted = true
                        note.updatedAt = Date()
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
        .overlay {
            if archivedNotes.isEmpty {
                ContentUnavailableView(
                    "No Archived Notes",
                    systemImage: "archivebox",
                    description: Text("Archived notes will appear here.")
                )
            }
        }
        .navigationTitle("Archive")
    }
}
