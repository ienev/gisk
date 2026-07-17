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
        var output = try await run(["diff", "--text"])
        let untracked = try await run(["ls-files", "--others", "--exclude-standard", "-z"])
        for file in untracked.split(separator: "\0").map(String.init) {
            output += try await run(["diff", "--no-index", "--text", "--", "/dev/null", file], allowFailure: true)
        }
        return output
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
        let sha = try validatedRevision(commitSHA)
        if isRoot {
            // Root commit: diff against empty tree. Trailing `--` guarantees the
            // revision can't be reinterpreted as a pathspec.
            return try await run([
                "diff-tree", "-p", "--text", "--no-commit-id", "--root", "-M", "-C",
                sha, "--",
            ])
        }
        if isMerge {
            // For merge commits, diff against first parent
            return try await run([
                "diff", "--text", "-M", "-C", "\(sha)~1", sha, "--",
            ])
        }
        return try await run([
            "diff-tree", "-p", "--text", "--no-commit-id", "-M", "-C",
            "--diff-filter=ACDMRT", sha, "--",
        ])
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

    /// Config overrides forced on every git invocation. Opening an untrusted
    /// repository means git reads that repo's `.git/config`; keys like
    /// `core.fsmonitor`/`core.hooksPath`/`core.pager` can otherwise make git
    /// execute arbitrary programs during ordinary read commands. We neutralize
    /// them here so viewing a hostile repo can't run its code.
    private static let safeConfigArgs = [
        "-c", "core.fsmonitor=",
        "-c", "core.hooksPath=/dev/null",
        "-c", "core.pager=cat",
    ]

    /// Validate that a string is a bare git object name (hex) before it is used
    /// as a positional revision argument. Revisions originate from parsed
    /// `%H`/`%h` log output, so anything non-hex (e.g. a leading `-` that git
    /// would treat as an option) indicates corruption or tampering and is
    /// rejected rather than passed through.
    private func validatedRevision(_ sha: String) throws -> String {
        guard !sha.isEmpty, sha.allSatisfy({ $0.isHexDigit }) else {
            throw GitError.invalidArgument("Invalid commit revision: \(sha)")
        }
        return sha
    }

    private func run(_ arguments: [String], allowFailure: Bool = false) async throws -> String {
        let process = Process()
        let stdout = Pipe()
        let stderr = Pipe()

        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process.arguments = Self.safeConfigArgs + arguments
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

        let output = decodeLenient(outData)
        let errorOutput = decodeLenient(errData)

        if process.terminationStatus != 0 && !allowFailure {
            throw GitError.commandFailed(
                command: "git \(arguments.joined(separator: " "))",
                stderr: errorOutput,
                exitCode: process.terminationStatus
            )
        }

        return output
    }

    private func decodeLenient(_ data: Data) -> String {
        if let utf8 = String(data: data, encoding: .utf8) {
            return utf8
        }
        return data.withUnsafeBytes { buf in
            String(decoding: buf.bindMemory(to: UInt8.self), as: UTF8.self)
        }
    }
}

public enum GitError: LocalizedError {
    case commandFailed(command: String, stderr: String, exitCode: Int32)
    case processLaunchFailed(Error)
    case notAGitRepository(path: String)
    case parseError(String)
    case invalidArgument(String)

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
        case .invalidArgument(let msg):
            return "Invalid argument: \(msg)"
        }
    }
}
