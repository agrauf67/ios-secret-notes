import Foundation
import StoreKit

@Observable
final class StoreManager {
    static let proProductId = "secret_notes_pro"

    private(set) var isProUser = false
    private(set) var proProduct: Product?
    private(set) var purchaseError: String?

    #if DEBUG
    var debugProOverride: Bool {
        get { UserDefaults.standard.bool(forKey: "debugProOverride") }
        set {
            UserDefaults.standard.set(newValue, forKey: "debugProOverride")
            isProUser = newValue
        }
    }
    #endif

    func loadProducts() async {
        do {
            let products = try await Product.products(for: [Self.proProductId])
            proProduct = products.first
        } catch {
            purchaseError = error.localizedDescription
        }
        await checkEntitlements()
    }

    func purchase() async {
        guard let product = proProduct else { return }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                if case .verified = verification {
                    isProUser = true
                }
            case .userCancelled:
                break
            case .pending:
                break
            @unknown default:
                break
            }
        } catch {
            purchaseError = error.localizedDescription
        }
    }

    func restorePurchases() async {
        try? await AppStore.sync()
        await checkEntitlements()
    }

    func checkEntitlements() async {
        #if DEBUG
        if debugProOverride {
            isProUser = true
            return
        }
        #endif

        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.productID == Self.proProductId {
                isProUser = true
                return
            }
        }
        isProUser = false
    }
}
