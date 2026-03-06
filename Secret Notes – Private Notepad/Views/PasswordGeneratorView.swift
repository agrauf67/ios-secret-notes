import SwiftUI

struct PasswordGeneratorView: View {
    @State private var length: Double = 16
    @State private var includeUppercase = true
    @State private var includeDigits = true
    @State private var includeSymbols = true
    @State private var generatedPassword = ""
    @State private var copied = false

    var body: some View {
        Form {
            Section("Options") {
                HStack {
                    Text("Length: \(Int(length))")
                    Slider(value: $length, in: 8...64, step: 1)
                }
                Toggle("Uppercase (A-Z)", isOn: $includeUppercase)
                Toggle("Digits (0-9)", isOn: $includeDigits)
                Toggle("Symbols (!@#$...)", isOn: $includeSymbols)
            }

            Section {
                Button {
                    generatePassword()
                } label: {
                    Label("Generate", systemImage: "key")
                }
            }

            if !generatedPassword.isEmpty {
                Section("Result") {
                    Text(generatedPassword)
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)

                    Button {
                        UIPasteboard.general.string = generatedPassword
                        copied = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { copied = false }
                    } label: {
                        Label(copied ? "Copied!" : "Copy to Clipboard", systemImage: copied ? "checkmark" : "doc.on.doc")
                    }
                }
            }
        }
        .navigationTitle("Password Generator")
        .onAppear { generatePassword() }
    }

    private func generatePassword() {
        var chars = "abcdefghijklmnopqrstuvwxyz"
        if includeUppercase { chars += "ABCDEFGHIJKLMNOPQRSTUVWXYZ" }
        if includeDigits { chars += "0123456789" }
        if includeSymbols { chars += "!@#$%^&*()-_=+[]{}|;:,.<>?" }

        var bytes = [UInt8](repeating: 0, count: Int(length))
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)

        generatedPassword = String(bytes.map { byte in
            let index = Int(byte) % chars.count
            return chars[chars.index(chars.startIndex, offsetBy: index)]
        })
    }
}
