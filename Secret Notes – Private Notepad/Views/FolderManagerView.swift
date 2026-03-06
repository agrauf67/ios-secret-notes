import SwiftUI
import SwiftData

struct FolderManagerView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(
        filter: #Predicate<Folder> { !$0.isDeleted },
        sort: \Folder.name
    ) private var allFolders: [Folder]

    @State private var newFolderName = ""
    @State private var selectedParent: Folder?
    @State private var showingAddFolder = false

    private var rootFolders: [Folder] {
        allFolders.filter { $0.parent == nil }
    }

    var body: some View {
        List {
            Section {
                Button {
                    showingAddFolder = true
                } label: {
                    Label("New Folder", systemImage: "folder.badge.plus")
                }
            }

            Section {
                ForEach(rootFolders) { folder in
                    FolderRowView(folder: folder, depth: 0)
                }
            }
        }
        .navigationTitle("Folders")
        .alert("New Folder", isPresented: $showingAddFolder) {
            TextField("Folder name", text: $newFolderName)
            Button("Cancel", role: .cancel) { newFolderName = "" }
            Button("Create") { addFolder() }
        }
    }

    private func addFolder() {
        let trimmed = newFolderName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let folder = Folder(name: trimmed, parent: selectedParent)
        modelContext.insert(folder)
        newFolderName = ""
        selectedParent = nil
    }
}

struct FolderRowView: View {
    @Environment(\.modelContext) private var modelContext
    let folder: Folder
    let depth: Int

    @State private var isExpanded = true

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            ForEach(folder.children.filter { !$0.isDeleted }.sorted { $0.name < $1.name }) { child in
                FolderRowView(folder: child, depth: depth + 1)
            }
        } label: {
            HStack {
                Image(systemName: "folder.fill")
                    .foregroundStyle(folderColor)
                Text(folder.name)
                Spacer()
                Text("\(folder.notes.filter { !$0.isDeleted }.count)")
                    .foregroundStyle(.secondary)
                    .font(.caption)
            }
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                folder.isDeleted = true
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private var folderColor: Color {
        if let hex = folder.colorHex {
            return Color(hex: hex)
        }
        return .accentColor
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
