import SwiftUI
import SwiftData
import MultipeerConnectivity

struct DeviceSyncView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(
        filter: #Predicate<SecretNote> { !$0.isDeleted },
        sort: \SecretNote.updatedAt,
        order: .reverse
    ) private var notes: [SecretNote]

    @State private var syncManager = DeviceSyncManager()

    var body: some View {
        Form {
            Section {
                statusView
            }

            Section("Actions") {
                switch syncManager.state {
                case .idle, .error:
                    Button {
                        syncManager.startSearching()
                    } label: {
                        Label("Start Searching", systemImage: "antenna.radiowaves.left.and.right")
                    }
                case .searching, .foundDevice:
                    Button {
                        syncManager.stopSearching()
                    } label: {
                        Label("Stop Searching", systemImage: "stop.circle")
                    }
                    .tint(.red)
                case .connected:
                    Button {
                        sendNotes()
                    } label: {
                        Label("Send Notes", systemImage: "arrow.up.circle")
                    }
                default:
                    EmptyView()
                }
            }

            if !syncManager.discoveredPeers.isEmpty {
                Section("Nearby Devices") {
                    ForEach(syncManager.discoveredPeers, id: \.displayName) { peer in
                        Button {
                            syncManager.connect(to: peer)
                        } label: {
                            HStack {
                                Image(systemName: "iphone")
                                Text(peer.displayName)
                                Spacer()
                                Text("Tap to connect")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Device Sync")
        .onAppear {
            syncManager.onNotesReceived = { syncNotes in
                importSyncedNotes(syncNotes)
            }
        }
        .onDisappear {
            syncManager.stopSearching()
        }
    }

    @ViewBuilder
    private var statusView: some View {
        switch syncManager.state {
        case .idle:
            Label("Ready to sync", systemImage: "circle")
                .foregroundStyle(.secondary)
        case .searching:
            HStack {
                ProgressView()
                Text("Searching for devices...")
            }
        case .foundDevice(let name):
            Label("Found: \(name)", systemImage: "checkmark.circle")
                .foregroundStyle(.green)
        case .connecting:
            HStack {
                ProgressView()
                Text("Connecting...")
            }
        case .connected(let name):
            Label("Connected to \(name)", systemImage: "link")
                .foregroundStyle(.green)
        case .syncing(let progress):
            VStack {
                ProgressView(value: progress)
                Text("Syncing...")
            }
        case .complete(let count):
            Label("Synced \(count) notes", systemImage: "checkmark.circle.fill")
                .foregroundStyle(.green)
        case .error(let message):
            Label(message, systemImage: "exclamationmark.triangle")
                .foregroundStyle(.red)
        }
    }

    private func sendNotes() {
        let syncNotes = notes.map { note in
            SyncNote(
                syncId: note.syncId.uuidString,
                title: note.title,
                text: note.text,
                itemsJSON: note.itemsJSON,
                spreadsheetJSON: note.spreadsheetJSON,
                noteTypeRaw: note.noteTypeRaw,
                overallRating: note.overallRating,
                isPinned: note.isPinned,
                isDeleted: note.isDeleted,
                isArchived: note.isArchived,
                colorHex: note.colorHex,
                categories: note.categories.map(\.name),
                folderPath: note.folder?.path,
                createdAt: note.createdAt.timeIntervalSince1970,
                updatedAt: note.updatedAt.timeIntervalSince1970
            )
        }
        syncManager.sendNotes(syncNotes)
    }

    private func importSyncedNotes(_ syncNotes: [SyncNote]) {
        for syncNote in syncNotes {
            guard let syncId = UUID(uuidString: syncNote.syncId) else { continue }

            let existing = notes.first { $0.syncId == syncId }
            if let existing = existing {
                if syncNote.updatedAt > existing.updatedAt.timeIntervalSince1970 {
                    existing.title = syncNote.title
                    existing.text = syncNote.text
                    existing.itemsJSON = syncNote.itemsJSON
                    existing.spreadsheetJSON = syncNote.spreadsheetJSON
                    existing.overallRating = syncNote.overallRating
                    existing.isPinned = syncNote.isPinned
                    existing.isDeleted = syncNote.isDeleted
                    existing.isArchived = syncNote.isArchived
                    existing.colorHex = syncNote.colorHex
                    existing.updatedAt = Date(timeIntervalSince1970: syncNote.updatedAt)
                }
            } else {
                let noteType = NoteType(rawValue: syncNote.noteTypeRaw) ?? .text
                let note = SecretNote(title: syncNote.title, text: syncNote.text, noteType: noteType)
                note.syncId = syncId
                note.itemsJSON = syncNote.itemsJSON
                note.spreadsheetJSON = syncNote.spreadsheetJSON
                note.overallRating = syncNote.overallRating
                note.isPinned = syncNote.isPinned
                note.isDeleted = syncNote.isDeleted
                note.isArchived = syncNote.isArchived
                note.colorHex = syncNote.colorHex
                note.createdAt = Date(timeIntervalSince1970: syncNote.createdAt)
                note.updatedAt = Date(timeIntervalSince1970: syncNote.updatedAt)
                modelContext.insert(note)
            }
        }
    }
}
