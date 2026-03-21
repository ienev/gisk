import SwiftUI
import GiskLib

// Special IDs for virtual entries
let stagedChangesID = "__STAGED__"
let unstagedChangesID = "__UNSTAGED__"

@Observable
class RepositoryViewModel {
    var repoPath: String = ""
    var repoName: String = ""
    var commits: [Commit] = []
    var selectedCommit: Commit? = nil
    var selectedFileDiff: FileDiff? = nil
    var diff: Diff? = nil
    var isLoading: Bool = false
    var error: String? = nil
    var searchText: String = ""

    private var git: GitCLI?
    private var loadedCount: Int = 0
    private let pageSize: Int = 500

    var filteredCommits: [Commit] {
        guard !searchText.isEmpty else { return commits }
        let query = searchText.lowercased()
        return commits.filter { commit in
            commit.subject.lowercased().contains(query)
                || commit.author.lowercased().contains(query)
                || commit.shortSHA.lowercased().contains(query)
                || commit.id.lowercased().hasPrefix(query)
        }
    }

    @MainActor
    func loadRepository(path: String) async {
        isLoading = true
        error = nil
        repoPath = path
        repoName = URL(fileURLWithPath: path).lastPathComponent

        let cli = GitCLI(repoPath: path)
        self.git = cli

        guard await cli.isGitRepo() else {
            error = "Not a git repository: \(path)"
            isLoading = false
            return
        }

        do {
            let output = try await cli.log(maxCount: pageSize, skip: 0)
            var parsed = try GitLogParser.parse(output)
            GraphLayoutEngine.computeLayout(commits: &parsed)

            // Prepend virtual entries for working tree changes
            let workingTreeEntries = await buildWorkingTreeEntries(cli: cli)
            commits = workingTreeEntries + parsed
            loadedCount = parsed.count

            if let first = commits.first {
                await selectCommit(first)
            }
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    @MainActor
    func loadMore() async {
        guard let git = git, !isLoading else { return }
        isLoading = true

        do {
            let output = try await git.log(maxCount: pageSize, skip: loadedCount)
            let newCommits = try GitLogParser.parse(output)
            guard !newCommits.isEmpty else {
                isLoading = false
                return
            }

            // Keep virtual entries, recompute layout for real commits only
            let virtualEntries = commits.filter { $0.id == stagedChangesID || $0.id == unstagedChangesID }
            var realCommits = commits.filter { $0.id != stagedChangesID && $0.id != unstagedChangesID } + newCommits
            GraphLayoutEngine.computeLayout(commits: &realCommits)
            commits = virtualEntries + realCommits
            loadedCount += newCommits.count
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    @MainActor
    func selectCommit(_ commit: Commit) async {
        selectedCommit = commit
        selectedFileDiff = nil

        guard let git = git else { return }

        do {
            let diffOutput: String

            if commit.id == unstagedChangesID {
                diffOutput = try await git.diffUnstaged()
            } else if commit.id == stagedChangesID {
                diffOutput = try await git.diffStaged()
            } else {
                let isMerge = commit.parentIDs.count > 1
                let isRoot = commit.parentIDs.isEmpty
                diffOutput = try await git.diff(commitSHA: commit.id, isMerge: isMerge, isRoot: isRoot)
            }

            diff = GitDiffParser.parse(diffOutput)

            if let firstFile = diff?.files.first {
                selectedFileDiff = firstFile
            }
        } catch {
            diff = nil
        }
    }

    func selectFile(_ file: FileDiff) {
        selectedFileDiff = file
    }

    @MainActor
    func navigateToCommit(sha: String) async {
        if let commit = commits.first(where: { $0.id == sha || $0.shortSHA == sha }) {
            await selectCommit(commit)
        }
    }

    // MARK: - Private

    private func buildWorkingTreeEntries(cli: GitCLI) async -> [Commit] {
        var entries: [Commit] = []

        do {
            let status = try await cli.statusPorcelain()
            guard !status.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                return []
            }

            var hasStaged = false
            var hasUnstaged = false

            for line in status.components(separatedBy: "\n") {
                guard line.count >= 2 else { continue }
                let index = line.index(line.startIndex, offsetBy: 0)
                let worktree = line.index(line.startIndex, offsetBy: 1)
                let indexChar = line[index]
                let worktreeChar = line[worktree]

                if indexChar != " " && indexChar != "?" {
                    hasStaged = true
                }
                if worktreeChar != " " && worktreeChar != "?" {
                    hasUnstaged = true
                }
                // Untracked files (?) count as unstaged
                if indexChar == "?" {
                    hasUnstaged = true
                }
            }

            if hasUnstaged {
                entries.append(Commit(
                    id: unstagedChangesID,
                    shortSHA: "",
                    subject: "Unstaged changes",
                    body: "",
                    author: "",
                    authorEmail: "",
                    authorDate: Date(),
                    committer: "",
                    committerDate: Date(),
                    parentIDs: [],
                    refs: [.localBranch(name: "working tree", isCurrent: false)]
                ))
            }

            if hasStaged {
                entries.append(Commit(
                    id: stagedChangesID,
                    shortSHA: "",
                    subject: "Staged changes (index)",
                    body: "",
                    author: "",
                    authorEmail: "",
                    authorDate: Date(),
                    committer: "",
                    committerDate: Date(),
                    parentIDs: [],
                    refs: [.localBranch(name: "index", isCurrent: false)]
                ))
            }
        } catch {
            // Silently ignore — just don't show working tree entries
        }

        return entries
    }
}
