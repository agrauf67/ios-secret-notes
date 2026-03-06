import SwiftUI
import LocalAuthentication

struct SettingsView: View {
    @Environment(AuthenticationManager.self) private var authManager
    @Environment(AppSettings.self) private var settings

    @State private var showingPinSetup = false
    @State private var showingPinRemove = false
    @State private var newPin = ""
    @State private var confirmPin = ""
    @State private var pinError = ""

    var body: some View {
        @Bindable var settings = settings
        @Bindable var authManager = authManager

        Form {
            Section("Appearance") {
                Picker("Theme", selection: $settings.themeMode) {
                    ForEach(ThemeMode.allCases, id: \.self) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }

                Picker("Color", selection: $settings.colorTheme) {
                    ForEach(ColorTheme.allCases, id: \.self) { theme in
                        HStack {
                            Circle()
                                .fill(theme.accentColor)
                                .frame(width: 12, height: 12)
                            Text(theme.displayName)
                        }
                        .tag(theme)
                    }
                }
            }

            Section("Display") {
                Toggle("Show Text Preview", isOn: $settings.showText)
                Toggle("Show Rating", isOn: $settings.showRating)
                Toggle("Show Categories", isOn: $settings.showCategory)
                Toggle("Show Folders", isOn: $settings.showFolders)
                Toggle("Show Dates", isOn: $settings.showCreatedUpdated)

                Stepper("Preview Lines: \(settings.maxPreviewLines)", value: $settings.maxPreviewLines, in: 1...10)
            }

            Section("Sorting") {
                Picker("Sort By", selection: $settings.sortOrder) {
                    ForEach(SortOrder.allCases, id: \.self) { order in
                        Text(order.displayName).tag(order)
                    }
                }
                Picker("Direction", selection: $settings.sortDirection) {
                    ForEach(SortDirection.allCases, id: \.self) { dir in
                        Text(dir.displayName).tag(dir)
                    }
                }
            }

            Section("Security") {
                if authManager.pinEnabled {
                    HStack {
                        Text("PIN")
                        Spacer()
                        Text("Enabled")
                            .foregroundStyle(.green)
                    }
                    Button("Remove PIN", role: .destructive) {
                        showingPinRemove = true
                    }
                } else {
                    Button("Set Up PIN") {
                        showingPinSetup = true
                    }
                }

                if !authManager.pinEnabled {
                    let canUseBiometric = LAContext().canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
                    if canUseBiometric {
                        Toggle(AuthenticationManager.biometricName, isOn: Binding(
                            get: { authManager.biometricEnabled },
                            set: { enabled in
                                if enabled {
                                    authManager.enableBiometric()
                                } else {
                                    authManager.disableBiometric()
                                }
                            }
                        ))
                    }
                }

                if authManager.isSecurityEnabled {
                    Picker("Lock Timeout", selection: Binding(
                        get: { authManager.lockTimeout },
                        set: { authManager.lockTimeout = $0 }
                    )) {
                        ForEach(LockTimeout.allCases, id: \.self) { timeout in
                            Text(timeout.displayName).tag(timeout)
                        }
                    }
                }
            }

            Section("Note History") {
                Stepper("History Limit: \(settings.historyLimit)", value: $settings.historyLimit, in: 5...200, step: 5)
            }
        }
        .navigationTitle("Settings")
        .sheet(isPresented: $showingPinSetup) {
            PinSetupSheet(authManager: authManager)
        }
        .alert("Remove PIN?", isPresented: $showingPinRemove) {
            Button("Cancel", role: .cancel) {}
            Button("Remove", role: .destructive) {
                authManager.removePin()
            }
        } message: {
            Text("PIN protection will be disabled.")
        }
    }
}

struct PinSetupSheet: View {
    let authManager: AuthenticationManager
    @Environment(\.dismiss) private var dismiss
    @State private var step = 1
    @State private var pin = ""
    @State private var confirmPin = ""
    @State private var error = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text(step == 1 ? "Enter a PIN (4-6 digits)" : "Confirm your PIN")
                    .font(.headline)

                Text(step == 1 ? String(repeating: "\u{25CF} ", count: pin.count) : String(repeating: "\u{25CF} ", count: confirmPin.count))
                    .font(.title)
                    .frame(height: 40)

                if !error.isEmpty {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.caption)
                }

                pinPad

                Spacer()
            }
            .padding()
            .navigationTitle("Set Up PIN")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private var pinPad: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
            ForEach(1...9, id: \.self) { digit in
                Button("\(digit)") { appendDigit(digit) }
                    .font(.title2)
                    .frame(width: 60, height: 60)
                    .background(Circle().fill(.secondary.opacity(0.1)))
            }
            Button {} label: { Text("") }.hidden()
            Button("0") { appendDigit(0) }
                .font(.title2)
                .frame(width: 60, height: 60)
                .background(Circle().fill(.secondary.opacity(0.1)))
            Button {
                if step == 1 && !pin.isEmpty { pin.removeLast() }
                if step == 2 && !confirmPin.isEmpty { confirmPin.removeLast() }
            } label: {
                Image(systemName: "delete.left.fill")
                    .font(.title2)
                    .frame(width: 60, height: 60)
            }
        }
        .padding(.horizontal, 40)
    }

    private func appendDigit(_ digit: Int) {
        error = ""
        if step == 1 {
            guard pin.count < 6 else { return }
            pin += "\(digit)"
            if pin.count >= 4 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    step = 2
                }
            }
        } else {
            guard confirmPin.count < 6 else { return }
            confirmPin += "\(digit)"
            if confirmPin.count == pin.count {
                if confirmPin == pin {
                    authManager.setupPin(pin)
                    dismiss()
                } else {
                    error = "PINs don't match"
                    confirmPin = ""
                }
            }
        }
    }
}
