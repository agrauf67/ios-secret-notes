import SwiftUI
import SwiftData

@main
struct Secret_Notes___Private_NotepadApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [SecretNote.self, Category.self, Folder.self])
    }
}
