import Foundation
import CryptoKit

final class EncryptionManager {
    static let shared = EncryptionManager()

    private let dekKey = "encryptedDEK"
    private var cachedDEK: SymmetricKey?

    private init() {}

    var dek: SymmetricKey {
        if let cached = cachedDEK {
            return cached
        }
        if let stored = loadDEK() {
            cachedDEK = stored
            return stored
        }
        let newKey = SymmetricKey(size: .bits256)
        saveDEK(newKey)
        cachedDEK = newKey
        return newKey
    }

    func encrypt(_ plaintext: String) -> String? {
        guard let data = plaintext.data(using: .utf8) else { return nil }
        do {
            let sealedBox = try AES.GCM.seal(data, using: dek)
            let nonce = sealedBox.nonce.withUnsafeBytes { Data($0) }
            let combined = sealedBox.ciphertext + sealedBox.tag
            return "v1:\(nonce.base64EncodedString()):\(combined.base64EncodedString())"
        } catch {
            return nil
        }
    }

    func decrypt(_ encrypted: String) -> String? {
        let parts = encrypted.split(separator: ":")
        guard parts.count == 3, parts[0] == "v1" else { return nil }

        guard let nonceData = Data(base64Encoded: String(parts[1])),
              let combined = Data(base64Encoded: String(parts[2])) else { return nil }

        guard combined.count > 16 else { return nil }
        let ciphertext = combined.prefix(combined.count - 16)
        let tag = combined.suffix(16)

        do {
            let nonce = try AES.GCM.Nonce(data: nonceData)
            let sealedBox = try AES.GCM.SealedBox(nonce: nonce, ciphertext: ciphertext, tag: tag)
            let decrypted = try AES.GCM.open(sealedBox, using: dek)
            return String(data: decrypted, encoding: .utf8)
        } catch {
            return nil
        }
    }

    private func saveDEK(_ key: SymmetricKey) {
        let data = key.withUnsafeBytes { Data($0) }
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: dekKey,
            kSecValueData as String: data
        ]
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    private func loadDEK() -> SymmetricKey? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: dekKey,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return SymmetricKey(data: data)
    }
}
