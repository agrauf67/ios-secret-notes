import SwiftUI
import SwiftData

struct NoteDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let note: SecretNote

    @State private var showingEditView = false
    @State private var showingDeleteAlert = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if note.overallRating > 0 {
                    RatingView(rating: note.overallRating, size: 16)
                }

                noteContent

                Spacer()

                VStack(alignment: .leading, spacing: 4) {
                    Text("Created: \(note.createdAt.formatted(date: .long, time: .shortened))")
                    Text("Updated: \(note.updatedAt.formatted(date: .long, time: .shortened))")
                }
                .font(.caption)
                .foregroundStyle(.tertiary)
            }
            .padding()
        }
        .navigationTitle(note.title.isEmpty ? "Untitled" : note.title)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        showingEditView = true
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }

                    Button {
                        note.isPinned.toggle()
                        note.updatedAt = Date()
                    } label: {
                        Label(
                            note.isPinned ? "Unpin" : "Pin",
                            systemImage: note.isPinned ? "pin.slash" : "pin"
                        )
                    }

                    Button {
                        copyToClipboard()
                    } label: {
                        Label("Copy to Clipboard", systemImage: "doc.on.doc")
                    }

                    Button {
                        note.isArchived = true
                        note.updatedAt = Date()
                        dismiss()
                    } label: {
                        Label("Archive", systemImage: "archivebox")
                    }

                    Divider()

                    Button(role: .destructive) {
                        showingDeleteAlert = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .navigationDestination(isPresented: $showingEditView) {
            NoteEditView(mode: .edit(note))
        }
        .alert("Delete Note", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                note.isDeleted = true
                note.updatedAt = Date()
                dismiss()
            }
        } message: {
            Text("This note will be moved to trash.")
        }
    }

    @ViewBuilder
    private var noteContent: some View {
        switch note.noteType {
        case .checklist:
            let items = note.checklistItems
            if !items.isEmpty {
                ChecklistDisplayView(items: items)
            }
        case .markdown:
            if let text = note.text, !text.isEmpty {
                MarkdownDisplayView(markdown: text)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        default:
            if let text = note.text, !text.isEmpty {
                Text(text)
                    .font(.body)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private func copyToClipboard() {
        var content = note.title

        switch note.noteType {
        case .checklist:
            let items = note.checklistItems
            for item in items.sorted(by: { $0.position < $1.position }) {
                let prefix = item.isParent ? "" : "  "
                let check = item.isChecked ? "[x]" : "[ ]"
                content += "\n\(prefix)\(check) \(item.text)"
            }
        default:
            if let text = note.text, !text.isEmpty {
                content += "\n\n" + text
            }
        }

        UIPasteboard.general.string = content
    }
}
