import SwiftUI
import GiskLib

enum DiffViewMode: String, CaseIterable {
    case unified = "Unified"
    case sideBySide = "Side by Side"

    var icon: String {
        switch self {
        case .unified: return "text.alignleft"
        case .sideBySide: return "rectangle.split.2x1"
        }
    }
}

struct DiffView: View {
    let fileDiff: FileDiff?
    @State private var viewMode: DiffViewMode = .unified

    var body: some View {
        Group {
            if let file = fileDiff {
                VStack(alignment: .leading, spacing: 0) {
                    // Sticky file header with mode toggle
                    HStack {
                        Text(file.status.label)
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundStyle(Theme.fileStatusColor(file.status))
                        Text(file.displayPath)
                            .font(.system(size: 13, weight: .medium))

                        Spacer()

                        Picker("", selection: $viewMode) {
                            ForEach(DiffViewMode.allCases, id: \.self) { mode in
                                Label(mode.rawValue, systemImage: mode.icon)
                                    .tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 200)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.quaternary)

                    switch viewMode {
                    case .unified:
                        UnifiedDiffContent(file: file)
                    case .sideBySide:
                        SideBySideDiffContent(file: file)
                    }
                }
            } else {
                ContentUnavailableView(
                    "No File Selected",
                    systemImage: "doc",
                    description: Text("Select a file to view its diff")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Flattened diff rows
//
// Each diff is flattened into a single list of rows (hunk headers + lines) so
// that a single LazyVStack can virtualize the whole file. Nesting a LazyVStack
// per hunk defeats laziness: the inner stack must lay out every line to report
// its size, which builds one oversized view that AppKit clips on large files.

private enum UnifiedRow: Identifiable {
    case hunkHeader(index: Int, text: String)
    case line(DiffLine)

    var id: String {
        switch self {
        case .hunkHeader(let index, _): return "h\(index)"
        case .line(let line): return "l\(line.id)"
        }
    }
}

private func unifiedRows(for file: FileDiff) -> [UnifiedRow] {
    var rows: [UnifiedRow] = []
    for (index, hunk) in file.hunks.enumerated() {
        rows.append(.hunkHeader(index: index, text: hunk.header))
        for line in hunk.lines {
            rows.append(.line(line))
        }
    }
    return rows
}

private enum SideBySideRow: Identifiable {
    case hunkHeader(index: Int, text: String)
    case pair(index: Int, pair: SideBySidePair)

    var id: String {
        switch self {
        case .hunkHeader(let index, _): return "h\(index)"
        case .pair(let index, _): return "p\(index)"
        }
    }
}

private func sideBySideRows(for file: FileDiff) -> [SideBySideRow] {
    var rows: [SideBySideRow] = []
    var pairIndex = 0
    for (index, hunk) in file.hunks.enumerated() {
        rows.append(.hunkHeader(index: index, text: hunk.header))
        for pair in SideBySidePairer.pair(lines: hunk.lines) {
            rows.append(.pair(index: pairIndex, pair: pair))
            pairIndex += 1
        }
    }
    return rows
}

private struct HunkHeaderRow: View {
    let text: String
    let showDivider: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if showDivider {
                Rectangle()
                    .fill(Color.primary.opacity(0.08))
                    .frame(height: 1)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 2)
            }
            Text(text)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(Theme.hunkHeaderText)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.hunkHeaderBackground)
        }
    }
}

// MARK: - Unified Diff

struct UnifiedDiffContent: View {
    let file: FileDiff

    var body: some View {
        let rows = unifiedRows(for: file)
        GeometryReader { geo in
            ScrollView([.horizontal, .vertical]) {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(rows) { row in
                        switch row {
                        case .hunkHeader(let index, let text):
                            HunkHeaderRow(text: text, showDivider: index > 0)
                        case .line(let line):
                            DiffLineView(line: line)
                        }
                    }
                    Spacer(minLength: 0)
                }
                .frame(minWidth: geo.size.width, minHeight: geo.size.height, alignment: .topLeading)
            }
            .textSelection(.enabled)
        }
    }
}

// MARK: - Side by Side Diff

struct SideBySideDiffContent: View {
    let file: FileDiff

    var body: some View {
        let rows = sideBySideRows(for: file)
        GeometryReader { geo in
            ScrollView(.vertical) {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(rows) { row in
                        switch row {
                        case .hunkHeader(let index, let text):
                            HunkHeaderRow(text: text, showDivider: index > 0)
                        case .pair(_, let pair):
                            HStack(spacing: 0) {
                                // Left side (old)
                                SideBySideLine(line: pair.left, side: .left)
                                    .frame(width: geo.size.width / 2)

                                Divider()

                                // Right side (new)
                                SideBySideLine(line: pair.right, side: .right)
                                    .frame(width: geo.size.width / 2)
                            }
                        }
                    }
                    Spacer(minLength: 0)
                }
                .frame(minHeight: geo.size.height, alignment: .topLeading)
            }
            .textSelection(.enabled)
        }
    }
}

enum DiffSide {
    case left, right
}

struct SideBySideLine: View {
    let line: DiffLine?
    let side: DiffSide

    var backgroundColor: Color {
        guard let line = line else {
            return Color.primary.opacity(0.03)
        }
        switch line.type {
        case .deletion: return Theme.deletedBackground
        case .addition: return Theme.addedBackground
        case .context: return .clear
        case .hunkHeader: return .clear
        }
    }

    var textColor: Color {
        guard let line = line else { return .clear }
        switch line.type {
        case .deletion: return Theme.deletedText
        case .addition: return Theme.addedText
        case .context: return Theme.contextText
        case .hunkHeader: return Theme.hunkHeaderText
        }
    }

    var lineNumber: Int? {
        guard let line = line else { return nil }
        return side == .left ? line.oldLineNumber : line.newLineNumber
    }

    var prefix: String {
        guard let line = line else { return " " }
        switch line.type {
        case .deletion: return "-"
        case .addition: return "+"
        case .context: return " "
        case .hunkHeader: return ""
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            Text(lineNumber.map { String(format: "%4d", $0) } ?? "    ")
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(.tertiary)
                .frame(width: 44, alignment: .trailing)

            Divider()
                .frame(height: 16)
                .padding(.horizontal, 3)

            Text(prefix)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(textColor)
                .frame(width: 14)

            Text(line?.text ?? "")
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(line?.type == .context ? Theme.contextText : Theme.primaryText)
                .lineLimit(1)
                .truncationMode(.tail)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 2)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 22)
        .clipped()
        .background(backgroundColor)
    }
}

// MARK: - Unified Diff Components

struct DiffLineView: View {
    let line: DiffLine

    var backgroundColor: Color {
        switch line.type {
        case .addition: return Theme.addedBackground
        case .deletion: return Theme.deletedBackground
        case .context:
            return line.id.isMultiple(of: 2) ? Color.primary.opacity(0.02) : .clear
        case .hunkHeader: return .clear
        }
    }

    var textColor: Color {
        switch line.type {
        case .addition: return Theme.addedText
        case .deletion: return Theme.deletedText
        case .context: return Theme.contextText
        case .hunkHeader: return Theme.hunkHeaderText
        }
    }

    var prefix: String {
        switch line.type {
        case .addition: return "+"
        case .deletion: return "-"
        case .context: return " "
        case .hunkHeader: return ""
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            Text(line.oldLineNumber.map { String(format: "%4d", $0) } ?? "    ")
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(.tertiary)
                .frame(width: 44, alignment: .trailing)

            Text(line.newLineNumber.map { String(format: "%4d", $0) } ?? "    ")
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(.tertiary)
                .frame(width: 44, alignment: .trailing)

            Divider()
                .frame(height: 16)
                .padding(.horizontal, 4)

            Text(prefix)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(textColor)
                .frame(width: 14)

            Text(line.text)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(line.type == .context ? Theme.contextText : Theme.primaryText)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 4)
        .frame(height: 22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(backgroundColor)
    }
}
