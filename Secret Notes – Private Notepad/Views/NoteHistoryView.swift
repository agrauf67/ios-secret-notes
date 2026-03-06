import SwiftUI
import SwiftData

struct NoteHistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let note: SecretNote

    @Query private var allHistory: [NoteHistory]

    private var history: [NoteHistory] {
        allHistory
            .filter { $0.noteId == note.persistentModelID }
            .sorted { $0.createdAt > $1.createdAt }
    }

    @State private var showingRestoreAlert = false
    @State private var selectedSnapshot: NoteHistory?

    var body: some View {
        List {
            ForEach(history) { snapshot in
                VStack(alignment: .leading, spacing: 4) {
                    Text(snapshot.title.isEmpty ? "Untitled" : snapshot.title)
                        .font(.headline)

                    if let text = snapshot.text, !text.isEmpty {
                        Text(text)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }

                    Text(snapshot.createdAt.formatted(date: .long, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .swipeActions(edge: .leading) {
                    Button {
                        selectedSnapshot = snapshot
                        showingRestoreAlert = true
                    } label: {
                        Label("Restore", systemImage: "arrow.uturn.backward")
                    }
                    .tint(.blue)
                }
            }
        }
        .overlay {
            if history.isEmpty {
                ContentUnavailableView(
                    "No History",
                    systemImage: "clock.arrow.circlepath",
                    description: Text("Version history will appear after edits.")
                )
            }
        }
        .navigationTitle("Note History")
        .alert("Restore Version?", isPresented: $showingRestoreAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Restore") {
                if let snapshot = selectedSnapshot {
                    restoreSnapshot(snapshot)
                }
            }
        } message: {
            Text("This will replace the current note content with this version.")
        }
    }

    private func restoreSnapshot(_ snapshot: NoteHistory) {
        note.title = snapshot.title
        note.text = snapshot.text
        note.itemsJSON = snapshot.itemsJSON
        note.spreadsheetJSON = snapshot.spreadsheetJSON
        note.colorHex = snapshot.colorHex
        note.overallRating = snapshot.overallRating
        note.updatedAt = Date()
        dismiss()
    }
}
