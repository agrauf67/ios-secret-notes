import SwiftUI
import SwiftData

struct CategoryManagerView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(
        filter: #Predicate<Category> { !$0.isDeleted },
        sort: \Category.name
    ) private var categories: [Category]

    @State private var newCategoryName = ""
    @State private var editingCategory: Category?
    @State private var editName = ""

    var body: some View {
        List {
            Section {
                HStack {
                    TextField("New category", text: $newCategoryName)
                    Button("Add") {
                        addCategory()
                    }
                    .disabled(newCategoryName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }

            Section {
                ForEach(categories) { category in
                    HStack {
                        if editingCategory?.id == category.id {
                            TextField("Name", text: $editName)
                                .onSubmit { saveEdit(category) }
                            Button("Save") { saveEdit(category) }
                        } else {
                            Text(category.name)
                            Spacer()
                            Text("\(category.notes.count)")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            category.isDeleted = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        Button {
                            editingCategory = category
                            editName = category.name
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        .tint(.blue)
                    }
                }
            }
        }
        .navigationTitle("Categories")
    }

    private func addCategory() {
        let trimmed = newCategoryName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        guard !categories.contains(where: { $0.name == trimmed }) else { return }
        let category = Category(name: trimmed)
        modelContext.insert(category)
        newCategoryName = ""
    }

    private func saveEdit(_ category: Category) {
        let trimmed = editName.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty {
            category.name = trimmed
        }
        editingCategory = nil
    }
}
