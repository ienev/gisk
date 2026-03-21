import Foundation

public struct GitDiffParser {
    public static func parse(_ output: String) -> Diff {
        var files: [FileDiff] = []
        let lines = output.components(separatedBy: "\n")
        var i = 0

        while i < lines.count {
            // Look for "diff --git a/... b/..."
            guard lines[i].hasPrefix("diff --git ") else {
                i += 1
                continue
            }

            let diffHeader = lines[i]
            let (oldPath, newPath) = parseDiffHeader(diffHeader)
            i += 1

            // Parse file metadata lines (index, old mode, new mode, etc.)
            var status: FileStatus = .modified
            while i < lines.count && !lines[i].hasPrefix("@@") && !lines[i].hasPrefix("diff --git ") {
                let line = lines[i]
                if line.hasPrefix("new file") {
                    status = .added
                } else if line.hasPrefix("deleted file") {
                    status = .deleted
                } else if line.hasPrefix("rename from") || line.hasPrefix("similarity index") {
                    status = .renamed
                }
                i += 1
            }

            // Parse hunks
            var hunks: [Hunk] = []
            while i < lines.count && !lines[i].hasPrefix("diff --git ") {
                if lines[i].hasPrefix("@@") {
                    let (hunk, nextI) = parseHunk(lines: lines, startIndex: i)
                    hunks.append(hunk)
                    i = nextI
                } else {
                    i += 1
                }
            }

            files.append(FileDiff(
                id: newPath.isEmpty ? oldPath : newPath,
                oldPath: oldPath,
                newPath: newPath.isEmpty ? oldPath : newPath,
                status: status,
                hunks: hunks
            ))
        }

        return Diff(files: files)
    }

    public static func parseNameStatus(_ output: String) -> [(FileStatus, String)] {
        var results: [(FileStatus, String)] = []
        let lines = output.components(separatedBy: "\n")

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { continue }
            let parts = trimmed.split(separator: "\t", maxSplits: 2)
            guard parts.count >= 2 else { continue }

            let statusChar = parts[0].prefix(1)
            let status: FileStatus
            switch statusChar {
            case "A": status = .added
            case "M": status = .modified
            case "D": status = .deleted
            case "R": status = .renamed
            case "C": status = .copied
            default: status = .unknown
            }

            let path = parts.count > 2 ? String(parts[2]) : String(parts[1])
            results.append((status, path))
        }

        return results
    }

    private static func parseDiffHeader(_ line: String) -> (String, String) {
        // "diff --git a/foo.txt b/foo.txt"
        let stripped = line.dropFirst("diff --git ".count)
        let parts = stripped.split(separator: " ", maxSplits: 1)
        guard parts.count == 2 else { return ("", "") }
        let old = parts[0].hasPrefix("a/") ? String(parts[0].dropFirst(2)) : String(parts[0])
        let new = parts[1].hasPrefix("b/") ? String(parts[1].dropFirst(2)) : String(parts[1])
        return (old, new)
    }

    private static func parseHunk(lines: [String], startIndex: Int) -> (Hunk, Int) {
        let header = lines[startIndex]
        let (oldStart, oldCount, newStart, newCount) = parseHunkHeader(header)

        var diffLines: [DiffLine] = []
        var lineID = startIndex * 1000
        var oldLine = oldStart
        var newLine = newStart
        var i = startIndex + 1

        while i < lines.count {
            let line = lines[i]
            if line.hasPrefix("diff --git ") || line.hasPrefix("@@") {
                break
            }

            let type: DiffLineType
            let text: String

            if line.hasPrefix("+") {
                type = .addition
                text = String(line.dropFirst())
                diffLines.append(DiffLine(id: lineID, type: type, oldLineNumber: nil, newLineNumber: newLine, text: text))
                newLine += 1
            } else if line.hasPrefix("-") {
                type = .deletion
                text = String(line.dropFirst())
                diffLines.append(DiffLine(id: lineID, type: type, oldLineNumber: oldLine, newLineNumber: nil, text: text))
                oldLine += 1
            } else if line.hasPrefix("\\") {
                // "\ No newline at end of file"
                i += 1
                lineID += 1
                continue
            } else {
                type = .context
                text = line.hasPrefix(" ") ? String(line.dropFirst()) : line
                diffLines.append(DiffLine(id: lineID, type: type, oldLineNumber: oldLine, newLineNumber: newLine, text: text))
                oldLine += 1
                newLine += 1
            }

            lineID += 1
            i += 1
        }

        let hunk = Hunk(
            header: header,
            oldStart: oldStart,
            oldCount: oldCount,
            newStart: newStart,
            newCount: newCount,
            lines: diffLines
        )

        return (hunk, i)
    }

    private static func parseHunkHeader(_ header: String) -> (Int, Int, Int, Int) {
        // "@@ -10,6 +10,8 @@ optional context"
        let regex = try? NSRegularExpression(pattern: #"@@ -(\d+)(?:,(\d+))? \+(\d+)(?:,(\d+))? @@"#)
        guard let match = regex?.firstMatch(in: header, range: NSRange(header.startIndex..., in: header)) else {
            return (1, 0, 1, 0)
        }

        func intAt(_ idx: Int) -> Int {
            guard let range = Range(match.range(at: idx), in: header) else { return 1 }
            return Int(header[range]) ?? 1
        }

        let oldStart = intAt(1)
        let oldCount = match.range(at: 2).location != NSNotFound ? intAt(2) : 1
        let newStart = intAt(3)
        let newCount = match.range(at: 4).location != NSNotFound ? intAt(4) : 1

        return (oldStart, oldCount, newStart, newCount)
    }
}
