import Foundation

public struct Diff {
    public let files: [FileDiff]

    public init(files: [FileDiff]) {
        self.files = files
    }
}

public struct FileDiff: Identifiable {
    public let id: String
    public let oldPath: String
    public let newPath: String
    public let status: FileStatus
    public let hunks: [Hunk]

    public init(id: String, oldPath: String, newPath: String, status: FileStatus, hunks: [Hunk]) {
        self.id = id
        self.oldPath = oldPath
        self.newPath = newPath
        self.status = status
        self.hunks = hunks
    }

    public var displayPath: String {
        if status == .renamed {
            return "\(oldPath) \u{2192} \(newPath)"
        }
        return newPath
    }
}

public enum FileStatus: String {
    case added = "A"
    case modified = "M"
    case deleted = "D"
    case renamed = "R"
    case copied = "C"
    case unknown = "?"

    public var label: String {
        switch self {
        case .added: return "A"
        case .modified: return "M"
        case .deleted: return "D"
        case .renamed: return "R"
        case .copied: return "C"
        case .unknown: return "?"
        }
    }
}

public struct Hunk {
    public let header: String
    public let oldStart: Int
    public let oldCount: Int
    public let newStart: Int
    public let newCount: Int
    public let lines: [DiffLine]

    public init(header: String, oldStart: Int, oldCount: Int, newStart: Int, newCount: Int, lines: [DiffLine]) {
        self.header = header
        self.oldStart = oldStart
        self.oldCount = oldCount
        self.newStart = newStart
        self.newCount = newCount
        self.lines = lines
    }
}

public struct DiffLine: Identifiable {
    public let id: Int
    public let type: DiffLineType
    public let oldLineNumber: Int?
    public let newLineNumber: Int?
    public let text: String

    public init(id: Int, type: DiffLineType, oldLineNumber: Int?, newLineNumber: Int?, text: String) {
        self.id = id
        self.type = type
        self.oldLineNumber = oldLineNumber
        self.newLineNumber = newLineNumber
        self.text = text
    }
}

public enum DiffLineType {
    case context
    case addition
    case deletion
    case hunkHeader
}

// MARK: - Side-by-Side Pairing

public struct SideBySidePair {
    public let left: DiffLine?
    public let right: DiffLine?

    public init(left: DiffLine?, right: DiffLine?) {
        self.left = left
        self.right = right
    }
}

public struct SideBySidePairer {
    public static func pair(lines: [DiffLine]) -> [SideBySidePair] {
        var result: [SideBySidePair] = []
        var i = 0

        while i < lines.count {
            let line = lines[i]

            switch line.type {
            case .context:
                result.append(SideBySidePair(left: line, right: line))
                i += 1

            case .deletion:
                var deletions: [DiffLine] = []
                var additions: [DiffLine] = []

                while i < lines.count && lines[i].type == .deletion {
                    deletions.append(lines[i])
                    i += 1
                }
                while i < lines.count && lines[i].type == .addition {
                    additions.append(lines[i])
                    i += 1
                }

                let maxCount = max(deletions.count, additions.count)
                for j in 0..<maxCount {
                    let left = j < deletions.count ? deletions[j] : nil
                    let right = j < additions.count ? additions[j] : nil
                    result.append(SideBySidePair(left: left, right: right))
                }

            case .addition:
                result.append(SideBySidePair(left: nil, right: line))
                i += 1

            case .hunkHeader:
                i += 1
            }
        }

        return result
    }
}
