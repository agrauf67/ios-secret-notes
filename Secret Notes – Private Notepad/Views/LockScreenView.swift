import SwiftUI
import LocalAuthentication

struct LockScreenView: View {
    @Environment(AuthenticationManager.self) private var authManager
    @State private var pinInput = ""
    @State private var showError = false
    @State private var isAuthenticating = false

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "lock.fill")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            Text("Secret Notes")
                .font(.title)
                .fontWeight(.bold)

            if authManager.pinEnabled {
                pinEntryView
            }

            if authManager.biometricEnabled {
                biometricButton
            }

            Spacer()
        }
        .padding()
        .onAppear {
            if authManager.biometricEnabled {
                authenticateWithBiometric()
            }
        }
    }

    private var pinEntryView: some View {
        VStack(spacing: 16) {
            Text("Enter PIN")
                .font(.headline)

            HStack(spacing: 12) {
                ForEach(0..<6, id: \.self) { index in
                    Circle()
                        .fill(index < pinInput.count ? Color.primary : Color.clear)
                        .stroke(Color.secondary, lineWidth: 1)
                        .frame(width: 16, height: 16)
                }
            }

            if showError {
                Text("Incorrect PIN")
                    .foregroundStyle(.red)
                    .font(.caption)
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 16) {
                ForEach(1...9, id: \.self) { digit in
                    pinButton("\(digit)") { appendDigit(digit) }
                }
                pinButton("") {}
                    .hidden()
                pinButton("0") { appendDigit(0) }
                pinButton("delete.left.fill", isSymbol: true) { deleteDigit() }
            }
            .padding(.horizontal, 40)
        }
    }

    private func pinButton(_ label: String, isSymbol: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            if isSymbol {
                Image(systemName: label)
                    .font(.title2)
                    .frame(width: 60, height: 60)
            } else {
                Text(label)
                    .font(.title)
                    .frame(width: 60, height: 60)
            }
        }
        .foregroundStyle(.primary)
        .background(Circle().fill(.secondary.opacity(0.1)))
    }

    private var biometricButton: some View {
        Button {
            authenticateWithBiometric()
        } label: {
            Label("Unlock with \(AuthenticationManager.biometricName)", systemImage: biometricIcon)
                .font(.headline)
                .padding()
                .background(.secondary.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(isAuthenticating)
    }

    private var biometricIcon: String {
        switch AuthenticationManager.biometricType {
        case .faceID: "faceid"
        case .touchID: "touchid"
        case .opticID: "opticid"
        default: "lock.shield"
        }
    }

    private func appendDigit(_ digit: Int) {
        guard pinInput.count < 6 else { return }
        pinInput += "\(digit)"
        showError = false
        if pinInput.count >= 4 {
            if authManager.verifyPin(pinInput) {
                authManager.isLocked = false
                pinInput = ""
            } else if pinInput.count == 6 {
                showError = true
                pinInput = ""
            }
        }
    }

    private func deleteDigit() {
        guard !pinInput.isEmpty else { return }
        pinInput.removeLast()
        showError = false
    }

    private func authenticateWithBiometric() {
        isAuthenticating = true
        Task {
            _ = await authManager.authenticateWithBiometric()
            isAuthenticating = false
        }
    }
}
