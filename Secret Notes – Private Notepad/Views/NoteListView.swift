import SwiftUI
import SwiftData

struct NoteListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(
        filter: #Predicate<SecretNote> { !$0.isDeleted && !$0.isArchived },
        sort: \SecretNote.updatedAt,
        order: .reverse
    ) private var notes: [SecretNote]

    @Query(filter: #Predicate<Category> { !$0.isDeleted }, sort: \Category.name)
    private var categories: [Category]

    @Query(filter: #Predicate<Folder> { !$0.isDeleted }, sort: \Folder.name)
    private var folders: [Folder]

    @State private var searchText = ""
    @State private var showingCreateNote = false
    @State private var sortOrder: SortOrder = .byDate
    @State private var sortDirection: SortDirection = .descending
    @State private var selectedCategoryId: PersistentIdentifier?
    @State private var selectedFolderId: PersistentIdentifier?
    @State private var showingFilters = false

    private var filteredNotes: [SecretNote] {
        var result = notes

        if !searchText.isEmpty {
            result = result.filter { note in
                note.title.localizedCaseInsensitiveContains(searchText) ||
                (note.text ?? "").localizedCaseInsensitiveContains(searchText)
            }
        }

        if let catId = selectedCategoryId {
            result = result.filter { note in
                note.categories.contains { $0.persistentModelID == catId }
            }
        }

        if let folderId = selectedFolderId {
            result = result.filter { $0.folder?.persistentModelID == folderId }
        }

        result.sort { a, b in
            let comparison: Bool
            switch sortOrder {
            case .byName:
                comparison = a.title.localizedCaseInsensitiveCompare(b.title) == .orderedAscending
            case .byRating:
                comparison = a.overallRating < b.overallRating
            case .byDate:
                comparison = a.updatedAt < b.updatedAt
            }
            return sortDirection == .ascending ? comparison : !comparison
        }

        return result
    }

    private var pinnedNotes: [SecretNote] {
        filteredNotes.filter(\.isPinned)
    }

    private var unpinnedNotes: [SecretNote] {
        filteredNotes.filter { !$0.isPinned }
    }

    private var hasActiveFilters: Bool {
        selectedCategoryId != nil || selectedFolderId != nil
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
                    searchText.isEmpty && !hasActiveFilters ? "No Notes" : "No Results",
                    systemImage: searchText.isEmpty ? "note.text" : "magnifyingglass",
                    description: Text(searchText.isEmpty && !hasActiveFilters ? "Tap + to create your first note." : "Try adjusting your search or filters.")
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
            ToolbarItem(placement: .topBarLeading) {
                Menu {
                    Section("Sort By") {
                        ForEach(SortOrder.allCases, id: \.self) { order in
                            Button {
                                sortOrder = order
                            } label: {
                                HStack {
                                    Text(order.displayName)
                                    if sortOrder == order {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    }
                    Section("Direction") {
                        ForEach(SortDirection.allCases, id: \.self) { direction in
                            Button {
                                sortDirection = direction
                            } label: {
                                HStack {
                                    Text(direction.displayName)
                                    if sortDirection == direction {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    }
                    Section("Category") {
                        Button {
                            selectedCategoryId = nil
                        } label: {
                            HStack {
                                Text("All")
                                if selectedCategoryId == nil {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                        ForEach(categories) { category in
                            Button {
                                selectedCategoryId = category.persistentModelID
                            } label: {
                                HStack {
                                    Text(category.name)
                                    if selectedCategoryId == category.persistentModelID {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    }
                    Section("Folder") {
                        Button {
                            selectedFolderId = nil
                        } label: {
                            HStack {
                                Text("All")
                                if selectedFolderId == nil {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                        ForEach(folders.filter { $0.parent == nil }) { folder in
                            Button {
                                selectedFolderId = folder.persistentModelID
                            } label: {
                                HStack {
                                    Text(folder.name)
                                    if selectedFolderId == folder.persistentModelID {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    }
                    if hasActiveFilters {
                        Section {
                            Button("Clear Filters", role: .destructive) {
                                selectedCategoryId = nil
                                selectedFolderId = nil
                            }
                        }
                    }
                } label: {
                    Image(systemName: hasActiveFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
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

                switch note.noteType {
                case .checklist:
                    let items = note.checklistItems
                    if !items.isEmpty {
                        let checked = items.filter(\.isChecked).count
                        Text("\(checked)/\(items.count) completed")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                default:
                    if let text = note.text, !text.isEmpty {
                        Text(text)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(3)
                    }
                }

                if !note.categories.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 4) {
                            ForEach(note.categories) { category in
                                Text(category.name)
                                    .font(.caption2)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(.secondary.opacity(0.15))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }

                if let folder = note.folder {
                    HStack(spacing: 4) {
                        Image(systemName: "folder")
                            .font(.caption2)
                        Text(folder.path)
                            .font(.caption2)
                    }
                    .foregroundStyle(.secondary)
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
