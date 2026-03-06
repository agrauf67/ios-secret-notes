import Foundation
import LocalAuthentication
import CryptoKit

@Observable
final class AuthenticationManager {
    var isLocked = false
    private var lastActiveDate: Date?

    var pinEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "pinEnabled") }
        set { UserDefaults.standard.set(newValue, forKey: "pinEnabled") }
    }

    var biometricEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "biometricEnabled") }
        set { UserDefaults.standard.set(newValue, forKey: "biometricEnabled") }
    }

    var lockTimeout: LockTimeout {
        get {
            let raw = UserDefaults.standard.string(forKey: "lockTimeout") ?? LockTimeout.oneMinute.rawValue
            return LockTimeout(rawValue: raw) ?? .oneMinute
        }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: "lockTimeout") }
    }

    private var pinHash: String? {
        get { UserDefaults.standard.string(forKey: "pinHash") }
        set { UserDefaults.standard.set(newValue, forKey: "pinHash") }
    }

    var isSecurityEnabled: Bool {
        pinEnabled || biometricEnabled
    }

    func setupPin(_ pin: String) {
        pinHash = hashPin(pin)
        pinEnabled = true
        biometricEnabled = false
        isLocked = false
    }

    func removePin() {
        pinHash = nil
        pinEnabled = false
        isLocked = false
    }

    func verifyPin(_ pin: String) -> Bool {
        guard let storedHash = pinHash else { return false }
        return hashPin(pin) == storedHash
    }

    func enableBiometric() {
        biometricEnabled = true
        pinEnabled = false
        pinHash = nil
        isLocked = false
    }

    func disableBiometric() {
        biometricEnabled = false
        isLocked = false
    }

    func authenticateWithBiometric() async -> Bool {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return false
        }
        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: "Unlock Secret Notes"
            )
            if success {
                isLocked = false
            }
            return success
        } catch {
            return false
        }
    }

    static var biometricType: LABiometryType {
        let context = LAContext()
        _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
        return context.biometryType
    }

    static var biometricName: String {
        switch biometricType {
        case .faceID: "Face ID"
        case .touchID: "Touch ID"
        case .opticID: "Optic ID"
        default: "Biometric"
        }
    }

    func lock() {
        guard isSecurityEnabled else { return }
        isLocked = true
    }

    func onAppBecameActive() {
        guard isSecurityEnabled else {
            isLocked = false
            return
        }
        guard let last = lastActiveDate else {
            isLocked = true
            return
        }
        if let interval = lockTimeout.intervalSeconds {
            if Date().timeIntervalSince(last) >= interval {
                isLocked = true
            }
        }
    }

    func onAppBecameInactive() {
        lastActiveDate = Date()
    }

    private func hashPin(_ pin: String) -> String {
        let data = Data(pin.utf8)
        let hash = SHA256.hash(data: data)
        return hash.map { String(format: "%02x", $0) }.joined()
    }
}
