import SwiftUI

struct SpreadsheetEditorView: View {
    @Binding var data: SpreadsheetData

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Button {
                    addColumn()
                } label: {
                    Label("Add Column", systemImage: "plus.rectangle")
                        .font(.caption)
                }
                Spacer()
                Button {
                    addRow()
                } label: {
                    Label("Add Row", systemImage: "plus.rectangle")
                        .font(.caption)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)

            ScrollView([.horizontal, .vertical]) {
                VStack(spacing: 0) {
                    headerRow
                    ForEach(Array(data.rows.enumerated()), id: \.element.id) { rowIndex, row in
                        dataRow(row: row, rowIndex: rowIndex)
                    }
                }
            }
        }
    }

    private var headerRow: some View {
        HStack(spacing: 0) {
            Text("#")
                .font(.caption.bold())
                .frame(width: 32, height: 36)
                .background(Color.secondary.opacity(0.15))

            ForEach(Array(data.columns.enumerated()), id: \.element.id) { colIndex, column in
                TextField("Col", text: Binding(
                    get: { column.name },
                    set: { data.columns[colIndex].name = $0 }
                ))
                .font(.caption.bold())
                .multilineTextAlignment(.center)
                .frame(width: column.widthDp, height: 36)
                .background(Color.secondary.opacity(0.15))
                .border(Color.secondary.opacity(0.3), width: 0.5)
            }

            if !data.columns.isEmpty {
                Button {
                    removeLastColumn()
                } label: {
                    Image(systemName: "minus.circle")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
                .frame(width: 24)
            }
        }
    }

    private func dataRow(row: SpreadsheetRow, rowIndex: Int) -> some View {
        HStack(spacing: 0) {
            Text("\(rowIndex + 1)")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 32, height: 36)
                .background(Color.secondary.opacity(0.05))

            ForEach(data.columns) { column in
                TextField("", text: Binding(
                    get: { row.cells[column.id.uuidString] ?? "" },
                    set: { data.rows[rowIndex].cells[column.id.uuidString] = $0 }
                ))
                .font(.caption)
                .frame(width: column.widthDp, height: 36)
                .border(Color.secondary.opacity(0.2), width: 0.5)
            }

            Button {
                removeRow(at: rowIndex)
            } label: {
                Image(systemName: "minus.circle")
                    .font(.caption)
                    .foregroundStyle(.red)
            }
            .frame(width: 24)
        }
    }

    private func addColumn() {
        let name = String(UnicodeScalar(65 + data.columns.count % 26)!)
        data.columns.append(SpreadsheetColumn(name: name, position: data.columns.count))
    }

    private func addRow() {
        data.rows.append(SpreadsheetRow(cells: [:], position: data.rows.count))
    }

    private func removeLastColumn() {
        guard !data.columns.isEmpty else { return }
        let removed = data.columns.removeLast()
        for i in data.rows.indices {
            data.rows[i].cells.removeValue(forKey: removed.id.uuidString)
        }
    }

    private func removeRow(at index: Int) {
        guard data.rows.count > 1 else { return }
        data.rows.remove(at: index)
    }
}

struct SpreadsheetDisplayView: View {
    let data: SpreadsheetData

    var body: some View {
        Text("\(data.rows.count) rows x \(data.columns.count) columns")
            .font(.subheadline)
            .foregroundStyle(.secondary)
    }
}
