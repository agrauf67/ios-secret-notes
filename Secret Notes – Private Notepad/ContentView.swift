import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        NavigationStack {
            NoteListView()
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: SecretNote.self, inMemory: true)
}
