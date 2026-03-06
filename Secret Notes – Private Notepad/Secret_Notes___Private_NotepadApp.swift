import SwiftUI
import SwiftData

@main
struct Secret_Notes___Private_NotepadApp: App {
    @State private var authManager = AuthenticationManager()
    @State private var appSettings = AppSettings()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(authManager)
                .environment(appSettings)
        }
        .modelContainer(for: [SecretNote.self, Category.self, Folder.self, NoteAttachment.self, NoteHistory.self])
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .active:
                authManager.onAppBecameActive()
            case .inactive, .background:
                authManager.onAppBecameInactive()
            @unknown default:
                break
            }
        }
    }
}
