import SwiftUI
import SwiftData

enum NoteEditMode {
    case create
    case edit(SecretNote)
}

struct NoteEditView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query(filter: #Predicate<Category> { !$0.isDeleted }, sort: \Category.name)
    private var allCategories: [Category]

    @Query(filter: #Predicate<Folder> { !$0.isDeleted }, sort: \Folder.name)
    private var allFolders: [Folder]

    let mode: NoteEditMode

    @State private var title: String = ""
    @State private var text: String = ""
    @State private var noteType: NoteType = .text
    @State private var rating: Double = 0.0
    @State private var isPinned: Bool = false
    @State private var checklistItems: [ChecklistItem] = []
    @State private var spreadsheetData: SpreadsheetData = SpreadsheetData()
    @State private var audioFilePath: String?
    @State private var selectedCategoryIds: Set<UUID> = []
    @State private var selectedFolderId: UUID?
    @State private var noteColorHex: String?
    @State private var reminderTime: Date?
    @State private var showingDiscardAlert = false
    @State private var isViewReady = false

    private var isNewNote: Bool {
        if case .create = mode { return true }
        return false
    }

    private var existingNote: SecretNote? {
        if case .edit(let note) = mode { return note }
        return nil
    }

    private var hasChanges: Bool {
        if let note = existingNote {
            let currentCatIds = Set(note.categories.map(\.syncId))
            return title != note.title ||
                   text != (note.text ?? "") ||
                   rating != note.overallRating ||
                   isPinned != note.isPinned ||
                   checklistItems != note.checklistItems ||
                   selectedCategoryIds != currentCatIds ||
                   selectedFolderId != note.folder?.syncId
        }
        return !title.isEmpty || !text.isEmpty || !checklistItems.isEmpty
    }

    var body: some View {
        Group {
            if isViewReady {
                formContent
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .task {
            try? await Task.sleep(for: .milliseconds(50))
            isViewReady = true
        }
        .navigationTitle(isNewNote ? "New Note" : "Edit Note")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    if hasChanges {
                        showingDiscardAlert = true
                    } else {
                        dismiss()
                    }
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    save()
                    dismiss()
                }
                .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .alert("Discard Changes?", isPresented: $showingDiscardAlert) {
            Button("Keep Editing", role: .cancel) {}
            Button("Discard", role: .destructive) { dismiss() }
        } message: {
            Text("You have unsaved changes that will be lost.")
        }
        .onAppear {
            if let note = existingNote {
                title = note.title
                text = note.text ?? ""
                noteType = note.noteType
                rating = note.overallRating
                isPinned = note.isPinned
                checklistItems = note.checklistItems
                spreadsheetData = note.spreadsheetData
                audioFilePath = note.audioFilePath
                noteColorHex = note.colorHex
                reminderTime = note.reminderTime
                selectedCategoryIds = Set(note.categories.map(\.syncId))
                selectedFolderId = note.folder?.syncId
            }
        }
    }

    @ViewBuilder
    private var formContent: some View {
        Form {
            Section {
                TextField("Title", text: $title)
                    .font(.headline)

                if isNewNote {
                    Picker("Type", selection: $noteType) {
                        ForEach(NoteType.allCases, id: \.self) { type in
                            Label(type.displayName, systemImage: type.iconName).tag(type)
                        }
                    }
                }
            }

            noteContentSection

            if !allCategories.isEmpty {
                Section("Categories") {
                    ForEach(allCategories) { category in
                        CategoryToggleRow(
                            category: category,
                            isSelected: selectedCategoryIds.contains(category.syncId),
                            onToggle: {
                                if selectedCategoryIds.contains(category.syncId) {
                                    selectedCategoryIds.remove(category.syncId)
                                } else {
                                    selectedCategoryIds.insert(category.syncId)
                                }
                            }
                        )
                    }
                }
            }

            if !allFolders.isEmpty {
                Section("Folder") {
                    Picker("Folder", selection: $selectedFolderId) {
                        Text("None").tag(nil as UUID?)
                        ForEach(allFolders.filter { $0.parent == nil }) { folder in
                            Text(folder.name).tag(folder.syncId as UUID?)
                        }
                    }
                }
            }

            Section("Color") {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(NoteColor.allCases) { noteColor in
                            let isSelected = noteColorHex == noteColor.rawValue || (noteColorHex == nil && noteColor == .none)
                            Circle()
                                .fill(noteColor.color ?? .clear)
                                .stroke(isSelected ? Color.primary : Color.clear, lineWidth: 2)
                                .frame(width: 32, height: 32)
                                .overlay {
                                    if noteColor == .none {
                                        Image(systemName: "xmark")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .onTapGesture {
                                    noteColorHex = noteColor.rawValue.isEmpty ? nil : noteColor.rawValue
                                }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }

            Section("Rating") {
                RatingInputView(rating: $rating)
            }

            Section("Reminder") {
                ReminderPickerView(reminderTime: $reminderTime)
            }

            Section {
                Toggle("Pinned", isOn: $isPinned)
            }
        }
    }

    @ViewBuilder
    private var noteContentSection: some View {
        switch noteType {
        case .text:
            Section("Content") {
                TextEditor(text: $text)
                    .frame(minHeight: 200)
            }
        case .checklist:
            Section("Items") {
                ChecklistEditorView(items: $checklistItems)
            }
        case .markdown:
            Section {
                MarkdownEditorView(text: $text)
                    .frame(minHeight: 300)
            }
        case .spreadsheet:
            Section("Table") {
                SpreadsheetEditorView(data: $spreadsheetData)
                    .frame(minHeight: 200)
            }
        case .audio:
            Section("Recording") {
                AudioRecorderView(audioFilePath: $audioFilePath)
            }
            Section("Transcript / Notes") {
                TextEditor(text: $text)
                    .frame(minHeight: 100)
            }
        }
    }

    private func save() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespaces)
        let resolvedCategories = allCategories.filter { selectedCategoryIds.contains($0.syncId) }
        let resolvedFolder = allFolders.first { $0.syncId == selectedFolderId }

        if let note = existingNote {
            let snapshot = NoteHistory(from: note)
            modelContext.insert(snapshot)

            note.title = trimmedTitle
            note.text = text.isEmpty ? nil : text
            note.overallRating = rating
            note.isPinned = isPinned
            note.checklistItems = checklistItems
            note.spreadsheetData = spreadsheetData
            note.audioFilePath = audioFilePath
            note.colorHex = noteColorHex
            note.reminderTime = reminderTime
            note.categories = resolvedCategories
            note.folder = resolvedFolder
            note.updatedAt = Date()
            scheduleReminder(for: note)
        } else {
            let note = SecretNote(title: trimmedTitle, text: text.isEmpty ? nil : text, noteType: noteType)
            note.overallRating = rating
            note.isPinned = isPinned
            note.checklistItems = checklistItems
            note.spreadsheetData = spreadsheetData
            note.audioFilePath = audioFilePath
            note.colorHex = noteColorHex
            note.reminderTime = reminderTime
            note.categories = resolvedCategories
            note.folder = resolvedFolder
            modelContext.insert(note)
            scheduleReminder(for: note)
        }
    }

    private func scheduleReminder(for note: SecretNote) {
        if note.reminderTime != nil {
            ReminderScheduler.schedule(for: note)
        } else {
            ReminderScheduler.cancel(for: note)
        }
    }
}

struct CategoryToggleRow: View {
    let category: Category
    let isSelected: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack {
                Text(category.name)
                    .foregroundStyle(.primary)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.tint)
                }
            }
        }
    }
}
