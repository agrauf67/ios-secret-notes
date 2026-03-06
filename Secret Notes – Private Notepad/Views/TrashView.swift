import SwiftUI
import SwiftData

struct TrashView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(
        filter: #Predicate<SecretNote> { $0.isDeleted },
        sort: \SecretNote.updatedAt,
        order: .reverse
    ) private var deletedNotes: [SecretNote]

    @State private var showingEmptyTrashAlert = false

    var body: some View {
        List {
            ForEach(deletedNotes) { note in
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
                        Text("Deleted \(note.updatedAt.formatted(date: .abbreviated, time: .shortened))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .swipeActions(edge: .leading) {
                    Button {
                        note.isDeleted = false
                        note.updatedAt = Date()
                    } label: {
                        Label("Restore", systemImage: "arrow.uturn.backward")
                    }
                    .tint(.green)
                }
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        modelContext.delete(note)
                    } label: {
                        Label("Delete Forever", systemImage: "trash.slash")
                    }
                }
            }
        }
        .overlay {
            if deletedNotes.isEmpty {
                ContentUnavailableView(
                    "Trash is Empty",
                    systemImage: "trash",
                    description: Text("Deleted notes will appear here.")
                )
            }
        }
        .navigationTitle("Trash")
        .toolbar {
            if !deletedNotes.isEmpty {
                ToolbarItem(placement: .primaryAction) {
                    Button("Empty Trash", role: .destructive) {
                        showingEmptyTrashAlert = true
                    }
                }
            }
        }
        .alert("Empty Trash?", isPresented: $showingEmptyTrashAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete All", role: .destructive) {
                for note in deletedNotes {
                    modelContext.delete(note)
                }
            }
        } message: {
            Text("All notes in trash will be permanently deleted. This cannot be undone.")
        }
    }
}
