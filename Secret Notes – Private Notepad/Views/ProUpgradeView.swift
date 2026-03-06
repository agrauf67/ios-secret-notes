import SwiftUI
import StoreKit

struct ProUpgradeView: View {
    @Environment(StoreManager.self) private var storeManager
    @Environment(\.dismiss) private var dismiss

    private let proFeatures = [
        ("tablecells", "Spreadsheet Notes"),
        ("text.document", "Markdown Notes"),
        ("mic", "Audio Notes"),
        ("doc.richtext", "PDF Export"),
        ("externaldrive", "Database Backup/Restore"),
        ("clock.arrow.2.circlepath", "Automatic Backups"),
        ("paperclip", "File Attachments"),
        ("clock.arrow.circlepath", "Note History"),
        ("folder", "Folders"),
        ("arrow.triangle.2.circlepath", "Device Sync"),
        ("checkmark.circle", "Bulk Operations")
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    Image(systemName: "star.circle.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(.yellow)

                    Text("Upgrade to Pro")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("Unlock all premium features")
                        .font(.title3)
                        .foregroundStyle(.secondary)

                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(proFeatures, id: \.1) { icon, name in
                            HStack(spacing: 12) {
                                Image(systemName: icon)
                                    .frame(width: 24)
                                    .foregroundStyle(.tint)
                                Text(name)
                            }
                        }
                    }
                    .padding()

                    if let product = storeManager.proProduct {
                        Button {
                            Task { await storeManager.purchase() }
                        } label: {
                            Text("Purchase - \(product.displayPrice)")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(.tint)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .padding(.horizontal)
                    }

                    Button("Restore Purchases") {
                        Task { await storeManager.restorePurchases() }
                    }
                    .font(.subheadline)

                    if let error = storeManager.purchaseError {
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }
                .padding()
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}
