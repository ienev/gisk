import Foundation

public actor GitCLI {
    public let repoPath: String

    public init(repoPath: String) {
        self.repoPath = repoPath
    }

    // MARK: - Public API

    public func log(maxCount: Int = 500, skip: Int = 0) async throws -> String {
        // NUL-delimited fields, record separator between commits
        let format = [
            "%H",   // full hash
            "%h",   // short hash
            "%P",   // parent hashes (space-separated)
            "%s",   // subject
            "%an",  // author name
            "%ae",  // author email
            "%aI",  // author date (ISO 8601)
            "%cn",  // committer name
            "%cI",  // committer date (ISO 8601)
            "%D",   // ref names
            "%B",   // full body
        ].joined(separator: "%x00")

        return try await run([
            "log",
            "--topo-order",
            "--max-count=\(maxCount)",
            "--skip=\(skip)",
            "--format=\(format)%x1e",
        ])
    }

    public func diffUnstaged() async throws -> String {
        return try await run(["diff", "--text"])
    }

    public func diffStaged() async throws -> String {
        return try await run(["diff", "--text", "--cached"])
    }

    public func statusPorcelain() async throws -> String {
        return try await run(["status", "--porcelain"])
    }

    public func diff(commitSHA: String, isMerge: Bool = false, isRoot: Bool = false) async throws -> String {
        if commitSHA == "WORKING" {
            return try await run(["diff", "--text", "HEAD"])
        }
        if isRoot {
            // Root commit: diff against empty tree
            return try await run([
                "diff-tree", "-p", "--text", "--no-commit-id", "--root", "-M", "-C",
                commitSHA,
            ])
        }
        if isMerge {
            // For merge commits, diff against first parent
            return try await run([
                "diff", "--text", "-M", "-C", "\(commitSHA)~1", commitSHA,
            ])
        }
        return try await run([
            "diff-tree", "-p", "--text", "--no-commit-id", "-M", "-C",
            "--diff-filter=ACDMRT", commitSHA,
        ])
    }

    public func diffStat(commitSHA: String) async throws -> String {
        return try await run([
            "diff-tree", "--no-commit-id", "-r", "--text", "--name-status", "-M", "-C",
            commitSHA,
        ])
    }

    public func show(commitSHA: String, file: String) async throws -> String {
        return try await run(["show", "\(commitSHA):\(file)"])
    }

    public func branches() async throws -> String {
        return try await run(["branch", "-a", "--no-color"])
    }

    public func tags() async throws -> String {
        return try await run(["tag", "--list"])
    }

    public func revParse(_ arg: String) async throws -> String {
        return try await run(["rev-parse", arg])
    }

    public func isGitRepo() async -> Bool {
        do {
            _ = try await run(["rev-parse", "--git-dir"])
            return true
        } catch {
            return false
        }
    }

    // MARK: - Private

    private func run(_ arguments: [String]) async throws -> String {
        let process = Process()
        let stdout = Pipe()
        let stderr = Pipe()

        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process.arguments = arguments
        process.currentDirectoryURL = URL(fileURLWithPath: repoPath)
        process.standardOutput = stdout
        process.standardError = stderr

        do {
            try process.run()
        } catch {
            throw GitError.processLaunchFailed(error)
        }

        // Read all data BEFORE waiting for termination to avoid deadlock
        let outData = stdout.fileHandleForReading.readDataToEndOfFile()
        let errData = stderr.fileHandleForReading.readDataToEndOfFile()

        process.waitUntilExit()

        let output = String(data: outData, encoding: .utf8) ?? ""
        let errorOutput = String(data: errData, encoding: .utf8) ?? ""

        if process.terminationStatus != 0 {
            throw GitError.commandFailed(
                command: "git \(arguments.joined(separator: " "))",
                stderr: errorOutput,
                exitCode: process.terminationStatus
            )
        }

        return output
    }
}

public enum GitError: LocalizedError {
    case commandFailed(command: String, stderr: String, exitCode: Int32)
    case processLaunchFailed(Error)
    case notAGitRepository(path: String)
    case parseError(String)

    public var errorDescription: String? {
        switch self {
        case .commandFailed(let cmd, let stderr, let code):
            return "git command failed (exit \(code)): \(cmd)\n\(stderr)"
        case .processLaunchFailed(let error):
            return "Failed to launch git: \(error.localizedDescription)"
        case .notAGitRepository(let path):
            return "Not a git repository: \(path)"
        case .parseError(let msg):
            return "Parse error: \(msg)"
        }
    }
}
