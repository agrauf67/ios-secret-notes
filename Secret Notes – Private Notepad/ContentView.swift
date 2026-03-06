import SwiftUI
import SwiftData

enum AppTab: String, CaseIterable {
    case notes = "Notes"
    case categories = "Categories"
    case folders = "Folders"
    case trash = "Trash"
    case archive = "Archive"

    var iconName: String {
        switch self {
        case .notes: "note.text"
        case .categories: "tag"
        case .folders: "folder"
        case .trash: "trash"
        case .archive: "archivebox"
        }
    }
}

struct ContentView: View {
    @Environment(AuthenticationManager.self) private var authManager
    @State private var selectedTab: AppTab = .notes

    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                ForEach(AppTab.allCases, id: \.self) { tab in
                    NavigationStack {
                        tabContent(for: tab)
                    }
                    .tabItem {
                        Label(tab.rawValue, systemImage: tab.iconName)
                    }
                    .tag(tab)
                }
            }
            .opacity(authManager.isLocked ? 0 : 1)

            if authManager.isLocked {
                LockScreenView()
            }
        }
    }

    @ViewBuilder
    private func tabContent(for tab: AppTab) -> some View {
        switch tab {
        case .notes:
            NoteListView()
        case .categories:
            CategoryManagerView()
        case .folders:
            FolderManagerView()
        case .trash:
            TrashView()
        case .archive:
            ArchiveView()
        }
    }
}

#Preview {
    ContentView()
        .environment(AuthenticationManager())
        .modelContainer(for: [SecretNote.self, Category.self, Folder.self], inMemory: true)
}
