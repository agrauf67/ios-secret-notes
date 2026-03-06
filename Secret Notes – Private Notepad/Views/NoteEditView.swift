import SwiftUI
import SwiftData

enum NoteEditMode {
    case create
    case edit(SecretNote)
}

struct NoteEditView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let mode: NoteEditMode

    @State private var title: String = ""
    @State private var text: String = ""
    @State private var noteType: NoteType = .text
    @State private var rating: Double = 0.0
    @State private var isPinned: Bool = false
    @State private var showingDiscardAlert = false

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
            return title != note.title ||
                   text != (note.text ?? "") ||
                   rating != note.overallRating ||
                   isPinned != note.isPinned
        }
        return !title.isEmpty || !text.isEmpty
    }

    var body: some View {
        Form {
            Section {
                TextField("Title", text: $title)
                    .font(.headline)
            }

            Section {
                TextEditor(text: $text)
                    .frame(minHeight: 200)
            } header: {
                Text("Content")
            }

            Section {
                RatingInputView(rating: $rating)
            } header: {
                Text("Rating")
            }

            Section {
                Toggle("Pinned", isOn: $isPinned)
            }
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
            }
        }
    }

    private func save() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespaces)
        if let note = existingNote {
            note.title = trimmedTitle
            note.text = text.isEmpty ? nil : text
            note.overallRating = rating
            note.isPinned = isPinned
            note.updatedAt = Date()
        } else {
            let note = SecretNote(title: trimmedTitle, text: text.isEmpty ? nil : text, noteType: noteType)
            note.overallRating = rating
            note.isPinned = isPinned
            modelContext.insert(note)
        }
    }
}
