import SwiftUI

struct ChecklistEditorView: View {
    @Binding var items: [ChecklistItem]
    @State private var newItemText = ""
    @FocusState private var newItemFocused: Bool

    private var parentItems: [ChecklistItem] {
        items.filter { $0.isParent }.sorted { $0.position < $1.position }
    }

    private func childItems(of parent: ChecklistItem) -> [ChecklistItem] {
        items.filter { $0.parentId == parent.id }.sorted { $0.position < $1.position }
    }

    private var checkedCount: Int {
        items.filter(\.isChecked).count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(parentItems) { parent in
                ChecklistRowView(
                    item: parent,
                    isChild: false,
                    onToggle: { toggleItem(parent) },
                    onDelete: { deleteItem(parent) },
                    onTextChange: { newText in updateText(parent, newText) },
                    onIndent: nil,
                    onOutdent: nil
                )

                ForEach(childItems(of: parent)) { child in
                    ChecklistRowView(
                        item: child,
                        isChild: true,
                        onToggle: { toggleItem(child) },
                        onDelete: { deleteItem(child) },
                        onTextChange: { newText in updateText(child, newText) },
                        onIndent: nil,
                        onOutdent: { outdentItem(child) }
                    )
                }
            }

            HStack(spacing: 8) {
                Image(systemName: "circle")
                    .foregroundStyle(.tertiary)
                TextField("Add item", text: $newItemText)
                    .focused($newItemFocused)
                    .onSubmit {
                        addItem()
                    }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 4)

            if checkedCount > 0 {
                Divider()
                    .padding(.vertical, 4)
                Text("\(checkedCount) completed")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 4)
            }
        }
    }

    private func addItem() {
        let trimmed = newItemText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let maxPos = (items.map(\.position).max() ?? -1) + 1
        let item = ChecklistItem(text: trimmed, position: maxPos)
        items.append(item)
        newItemText = ""
        newItemFocused = true
    }

    private func toggleItem(_ item: ChecklistItem) {
        guard let idx = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[idx].isChecked.toggle()
        items[idx].doneAt = items[idx].isChecked ? Date() : nil

        if items[idx].isParent {
            for i in items.indices where items[i].parentId == item.id {
                items[i].isChecked = items[idx].isChecked
                items[i].doneAt = items[idx].isChecked ? Date() : nil
            }
        } else if let parentId = items[idx].parentId {
            let siblings = items.filter { $0.parentId == parentId }
            let allChecked = siblings.allSatisfy(\.isChecked)
            if let parentIdx = items.firstIndex(where: { $0.id == parentId }) {
                items[parentIdx].isChecked = allChecked
                items[parentIdx].doneAt = allChecked ? Date() : nil
            }
        }
    }

    private func deleteItem(_ item: ChecklistItem) {
        items.removeAll { $0.id == item.id || $0.parentId == item.id }
    }

    private func updateText(_ item: ChecklistItem, _ newText: String) {
        guard let idx = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[idx].text = newText
    }

    private func outdentItem(_ item: ChecklistItem) {
        guard let idx = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[idx].parentId = nil
    }
}

struct ChecklistRowView: View {
    let item: ChecklistItem
    let isChild: Bool
    let onToggle: () -> Void
    let onDelete: () -> Void
    let onTextChange: (String) -> Void
    let onIndent: (() -> Void)?
    let onOutdent: (() -> Void)?

    @State private var editText: String = ""

    var body: some View {
        HStack(spacing: 8) {
            Button(action: onToggle) {
                Image(systemName: item.isChecked ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(item.isChecked ? .green : .secondary)
            }
            .buttonStyle(.plain)

            TextField("Item", text: $editText)
                .strikethrough(item.isChecked)
                .foregroundStyle(item.isChecked ? .secondary : .primary)
                .onChange(of: editText) { _, newValue in
                    onTextChange(newValue)
                }

            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.tertiary)
                    .font(.caption)
            }
            .buttonStyle(.plain)
        }
        .padding(.leading, isChild ? 28 : 0)
        .padding(.vertical, 4)
        .padding(.horizontal, 4)
        .onAppear { editText = item.text }
    }
}

struct ChecklistDisplayView: View {
    let items: [ChecklistItem]

    private var parentItems: [ChecklistItem] {
        items.filter { $0.isParent }.sorted { $0.position < $1.position }
    }

    private func childItems(of parent: ChecklistItem) -> [ChecklistItem] {
        items.filter { $0.parentId == parent.id }.sorted { $0.position < $1.position }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(parentItems) { parent in
                checklistRow(parent, isChild: false)
                ForEach(childItems(of: parent)) { child in
                    checklistRow(child, isChild: true)
                }
            }
        }
    }

    private func checklistRow(_ item: ChecklistItem, isChild: Bool) -> some View {
        HStack(spacing: 8) {
            Image(systemName: item.isChecked ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(item.isChecked ? .green : .secondary)
                .font(.subheadline)
            Text(item.text)
                .strikethrough(item.isChecked)
                .foregroundStyle(item.isChecked ? .secondary : .primary)
        }
        .padding(.leading, isChild ? 24 : 0)
    }
}
