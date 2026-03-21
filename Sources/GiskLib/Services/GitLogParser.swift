import Foundation

public struct GitLogParser {
    private static let isoFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    private static let isoFormatterBasic: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    public static func parse(_ output: String) throws -> [Commit] {
        let records = output.components(separatedBy: "\u{1e}")
        var commits: [Commit] = []

        for record in records {
            let trimmed = record.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty { continue }

            let fields = trimmed.components(separatedBy: "\u{00}")
            guard fields.count >= 10 else {
                continue
            }

            let fullSHA = fields[0]
            let shortSHA = fields[1]
            let parentStr = fields[2]
            let subject = fields[3]
            let authorName = fields[4]
            let authorEmail = fields[5]
            let authorDateStr = fields[6]
            let committerName = fields[7]
            let committerDateStr = fields[8]
            let refStr = fields[9]
            let body = fields.count > 10 ? fields[10] : ""

            let parentIDs = parentStr.isEmpty ? [] : parentStr.split(separator: " ").map(String.init)
            let authorDate = parseDate(authorDateStr) ?? Date.distantPast
            let committerDate = parseDate(committerDateStr) ?? Date.distantPast
            let refs = parseRefs(refStr)

            let commit = Commit(
                id: fullSHA,
                shortSHA: shortSHA,
                subject: subject,
                body: body.trimmingCharacters(in: .whitespacesAndNewlines),
                author: authorName,
                authorEmail: authorEmail,
                authorDate: authorDate,
                committer: committerName,
                committerDate: committerDate,
                parentIDs: parentIDs,
                refs: refs
            )
            commits.append(commit)
        }

        // Compute child IDs
        var childMap: [String: [String]] = [:]
        for commit in commits {
            for parentID in commit.parentIDs {
                childMap[parentID, default: []].append(commit.id)
            }
        }
        for i in commits.indices {
            commits[i].childIDs = childMap[commits[i].id] ?? []
        }

        return commits
    }

    private static func parseDate(_ str: String) -> Date? {
        return isoFormatter.date(from: str) ?? isoFormatterBasic.date(from: str)
    }

    public static func parseRefs(_ str: String) -> [Ref] {
        guard !str.isEmpty else { return [] }
        let parts = str.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        var refs: [Ref] = []

        for part in parts {
            if part == "HEAD" {
                refs.append(.head)
            } else if part.hasPrefix("HEAD -> ") {
                let name = String(part.dropFirst("HEAD -> ".count))
                refs.append(.head)
                refs.append(.localBranch(name: name, isCurrent: true))
            } else if part.hasPrefix("tag: ") {
                let name = String(part.dropFirst("tag: ".count))
                refs.append(.tag(name: name))
            } else if part.contains("/") && !part.hasPrefix("refs/") {
                // Remote branch like "origin/main"
                refs.append(.remoteBranch(name: part))
            } else {
                refs.append(.localBranch(name: part, isCurrent: false))
            }
        }

        return refs
    }
}
