import SwiftUI

struct MarkdownEditorView: View {
    @Binding var text: String
    @State private var showingPreview = false

    var body: some View {
        VStack(spacing: 0) {
            Picker("Mode", selection: $showingPreview) {
                Text("Edit").tag(false)
                Text("Preview").tag(true)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.vertical, 8)

            if showingPreview {
                ScrollView {
                    MarkdownRendererView(markdown: text)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                VStack(spacing: 0) {
                    MarkdownToolbarView(text: $text)
                    TextEditor(text: $text)
                        .font(.system(.body, design: .monospaced))
                }
            }
        }
    }
}

struct MarkdownToolbarView: View {
    @Binding var text: String

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                toolbarButton("Bold", icon: "bold") { wrapSelection("**") }
                toolbarButton("Italic", icon: "italic") { wrapSelection("_") }
                toolbarButton("Strikethrough", icon: "strikethrough") { wrapSelection("~~") }
                toolbarButton("Heading", icon: "number") { prependLine("# ") }
                toolbarButton("List", icon: "list.bullet") { prependLine("- ") }
                toolbarButton("Numbered", icon: "list.number") { prependLine("1. ") }
                toolbarButton("Code", icon: "chevron.left.forwardslash.chevron.right") { wrapSelection("`") }
                toolbarButton("Quote", icon: "text.quote") { prependLine("> ") }
                toolbarButton("Link", icon: "link") { insertLink() }
            }
            .padding(.horizontal)
            .padding(.vertical, 6)
        }
        .background(.bar)
    }

    private func toolbarButton(_ label: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .frame(width: 32, height: 32)
        }
        .accessibilityLabel(label)
    }

    private func wrapSelection(_ wrapper: String) {
        text += "\(wrapper)text\(wrapper)"
    }

    private func prependLine(_ prefix: String) {
        if !text.isEmpty && !text.hasSuffix("\n") {
            text += "\n"
        }
        text += prefix
    }

    private func insertLink() {
        text += "[link text](url)"
    }
}

struct MarkdownRendererView: View {
    let markdown: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(markdown.components(separatedBy: "\n").enumerated()), id: \.offset) { _, line in
                renderLine(line)
            }
        }
    }

    @ViewBuilder
    private func renderLine(_ line: String) -> some View {
        if line.hasPrefix("### ") {
            Text(renderInline(String(line.dropFirst(4))))
                .font(.title3)
                .fontWeight(.semibold)
        } else if line.hasPrefix("## ") {
            Text(renderInline(String(line.dropFirst(3))))
                .font(.title2)
                .fontWeight(.bold)
        } else if line.hasPrefix("# ") {
            Text(renderInline(String(line.dropFirst(2))))
                .font(.title)
                .fontWeight(.bold)
        } else if line.hasPrefix("> ") {
            Text(renderInline(String(line.dropFirst(2))))
                .italic()
                .foregroundStyle(.secondary)
                .padding(.leading, 12)
                .overlay(alignment: .leading) {
                    Rectangle()
                        .fill(.secondary)
                        .frame(width: 3)
                }
        } else if line.hasPrefix("- ") || line.hasPrefix("* ") {
            HStack(alignment: .top, spacing: 6) {
                Text("\u{2022}")
                Text(renderInline(String(line.dropFirst(2))))
            }
        } else if let match = line.range(of: #"^\d+\.\s"#, options: .regularExpression) {
            HStack(alignment: .top, spacing: 6) {
                Text(String(line[match]))
                    .monospacedDigit()
                Text(renderInline(String(line[match.upperBound...])))
            }
        } else if line.hasPrefix("```") {
            Text(line)
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(.secondary)
        } else if line.trimmingCharacters(in: .whitespaces).isEmpty {
            Spacer().frame(height: 4)
        } else {
            Text(renderInline(line))
        }
    }

    private func renderInline(_ text: String) -> AttributedString {
        var result = text
        // Simple inline rendering - convert markdown bold/italic to plain text
        // For a full implementation, a proper markdown parser would be used
        result = result.replacingOccurrences(of: "**", with: "")
        result = result.replacingOccurrences(of: "__", with: "")
        result = result.replacingOccurrences(of: "~~", with: "")
        result = result.replacingOccurrences(of: "`", with: "")

        // Remove link markdown syntax, show just the text
        let linkPattern = #"\[([^\]]+)\]\([^\)]+\)"#
        if let regex = try? NSRegularExpression(pattern: linkPattern) {
            let range = NSRange(result.startIndex..., in: result)
            result = regex.stringByReplacingMatches(in: result, range: range, withTemplate: "$1")
        }

        return (try? AttributedString(markdown: result)) ?? AttributedString(result)
    }
}

struct MarkdownDisplayView: View {
    let markdown: String

    var body: some View {
        MarkdownRendererView(markdown: markdown)
    }
}
