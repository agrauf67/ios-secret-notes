import Foundation
import MultipeerConnectivity

enum SyncState: Equatable {
    case idle
    case searching
    case foundDevice(String)
    case connecting
    case connected(String)
    case syncing(Double)
    case complete(Int)
    case error(String)
}

struct SyncNote: Codable {
    var syncId: String
    var title: String
    var text: String?
    var itemsJSON: String?
    var spreadsheetJSON: String?
    var noteTypeRaw: String
    var overallRating: Double
    var isPinned: Bool
    var isDeleted: Bool
    var isArchived: Bool
    var colorHex: String?
    var categories: [String]
    var folderPath: String?
    var createdAt: TimeInterval
    var updatedAt: TimeInterval
}

struct SyncManifest: Codable {
    var deviceId: String
    var noteCount: Int
    var lastModified: TimeInterval
    var notes: [NoteDigest]
}

struct NoteDigest: Codable {
    var syncId: String
    var lastModified: TimeInterval
    var contentHash: String
    var isDeleted: Bool
}

@Observable
final class DeviceSyncManager: NSObject {
    private let serviceType = "secretnotes"
    private let myPeerId = MCPeerID(displayName: UIDevice.current.name)
    private var session: MCSession?
    private var advertiser: MCNearbyServiceAdvertiser?
    private var browser: MCNearbyServiceBrowser?

    var state: SyncState = .idle
    var discoveredPeers: [MCPeerID] = []

    func startSearching() {
        session = MCSession(peer: myPeerId, securityIdentity: nil, encryptionPreference: .required)
        session?.delegate = self

        browser = MCNearbyServiceBrowser(peer: myPeerId, serviceType: serviceType)
        browser?.delegate = self
        browser?.startBrowsingForPeers()

        advertiser = MCNearbyServiceAdvertiser(peer: myPeerId, discoveryInfo: nil, serviceType: serviceType)
        advertiser?.delegate = self
        advertiser?.startAdvertisingPeer()

        state = .searching
    }

    func stopSearching() {
        browser?.stopBrowsingForPeers()
        advertiser?.stopAdvertisingPeer()
        session?.disconnect()
        discoveredPeers = []
        state = .idle
    }

    func connect(to peer: MCPeerID) {
        guard let browser = browser else { return }
        browser.invitePeer(peer, to: session!, withContext: nil, timeout: 30)
        state = .connecting
    }

    func sendNotes(_ notes: [SyncNote]) {
        guard let session = session, let peer = session.connectedPeers.first else { return }
        state = .syncing(0)

        do {
            let data = try JSONEncoder().encode(notes)
            try session.send(data, toPeers: [peer], with: .reliable)
            state = .complete(notes.count)
        } catch {
            state = .error("Failed to send: \(error.localizedDescription)")
        }
    }

    var onNotesReceived: (([SyncNote]) -> Void)?
}

extension DeviceSyncManager: MCSessionDelegate {
    nonisolated func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        Task { @MainActor in
            switch state {
            case .connected:
                self.state = .connected(peerID.displayName)
            case .notConnected:
                if case .connected = self.state {
                    self.state = .idle
                }
            case .connecting:
                self.state = .connecting
            @unknown default:
                break
            }
        }
    }

    nonisolated func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        if let notes = try? JSONDecoder().decode([SyncNote].self, from: data) {
            Task { @MainActor in
                self.onNotesReceived?(notes)
                self.state = .complete(notes.count)
            }
        }
    }

    nonisolated func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    nonisolated func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    nonisolated func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}

extension DeviceSyncManager: MCNearbyServiceBrowserDelegate {
    nonisolated func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String: String]?) {
        Task { @MainActor in
            if !discoveredPeers.contains(peerID) {
                discoveredPeers.append(peerID)
            }
            state = .foundDevice(peerID.displayName)
        }
    }

    nonisolated func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        Task { @MainActor in
            discoveredPeers.removeAll { $0 == peerID }
        }
    }
}

extension DeviceSyncManager: MCNearbyServiceAdvertiserDelegate {
    nonisolated func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        Task { @MainActor in
            invitationHandler(true, session)
        }
    }
}
