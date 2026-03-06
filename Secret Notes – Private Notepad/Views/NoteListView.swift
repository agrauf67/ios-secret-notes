import SwiftUI
import SwiftData

struct NoteListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(
        filter: #Predicate<SecretNote> { !$0.isDeleted && !$0.isArchived },
        sort: \SecretNote.updatedAt,
        order: .reverse
    ) private var notes: [SecretNote]

    @State private var searchText = ""
    @State private var showingCreateNote = false

    private var filteredNotes: [SecretNote] {
        if searchText.isEmpty { return notes }
        return notes.filter { note in
            note.title.localizedCaseInsensitiveContains(searchText) ||
            (note.text ?? "").localizedCaseInsensitiveContains(searchText)
        }
    }

    private var pinnedNotes: [SecretNote] {
        filteredNotes.filter(\.isPinned)
    }

    private var unpinnedNotes: [SecretNote] {
        filteredNotes.filter { !$0.isPinned }
    }

    var body: some View {
        List {
            if !pinnedNotes.isEmpty {
                Section("Pinned") {
                    ForEach(pinnedNotes) { note in
                        NoteCardView(note: note)
                    }
                }
            }

            Section(pinnedNotes.isEmpty ? "" : "Notes") {
                ForEach(unpinnedNotes) { note in
                    NoteCardView(note: note)
                }
            }
        }
        .overlay {
            if filteredNotes.isEmpty {
                ContentUnavailableView(
                    searchText.isEmpty ? "No Notes" : "No Results",
                    systemImage: searchText.isEmpty ? "note.text" : "magnifyingglass",
                    description: Text(searchText.isEmpty ? "Tap + to create your first note." : "No notes match your search.")
                )
            }
        }
        .searchable(text: $searchText, prompt: "Search notes")
        .navigationTitle("Notes")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingCreateNote = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .navigationDestination(isPresented: $showingCreateNote) {
            NoteEditView(mode: .create)
        }
    }
}

struct NoteCardView: View {
    let note: SecretNote

    var body: some View {
        NavigationLink {
            NoteDetailView(note: note)
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: note.noteType.iconName)
                        .foregroundStyle(.secondary)
                        .font(.caption)
                    Text(note.title.isEmpty ? "Untitled" : note.title)
                        .font(.headline)
                        .lineLimit(1)
                    Spacer()
                    if note.isPinned {
                        Image(systemName: "pin.fill")
                            .foregroundStyle(.orange)
                            .font(.caption)
                    }
                }

                if let text = note.text, !text.isEmpty {
                    Text(text)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                }

                if note.overallRating > 0 {
                    RatingView(rating: note.overallRating, size: 10)
                }

                Text(note.updatedAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, 2)
        }
    }
}
