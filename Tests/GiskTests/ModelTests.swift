import XCTest
import SwiftUI
@testable import GiskLib

final class ModelTests: XCTestCase {

    // MARK: - Ref: displayName

    func testRefLocalBranchDisplayName() {
        let ref = Ref.localBranch(name: "main", isCurrent: true)
        XCTAssertEqual(ref.displayName, "main")
    }

    func testRefRemoteBranchDisplayName() {
        let ref = Ref.remoteBranch(name: "origin/main")
        XCTAssertEqual(ref.displayName, "origin/main")
    }

    func testRefTagDisplayName() {
        let ref = Ref.tag(name: "v1.0.0")
        XCTAssertEqual(ref.displayName, "v1.0.0")
    }

    func testRefHeadDisplayName() {
        let ref = Ref.head
        XCTAssertEqual(ref.displayName, "HEAD")
    }

    // MARK: - Ref: color

    func testRefCurrentBranchColorGreen() {
        let ref = Ref.localBranch(name: "main", isCurrent: true)
        XCTAssertEqual(ref.color, .green)
    }

    func testRefNonCurrentBranchColorBlue() {
        let ref = Ref.localBranch(name: "feature", isCurrent: false)
        XCTAssertEqual(ref.color, .blue)
    }

    func testRefRemoteBranchColorOrange() {
        let ref = Ref.remoteBranch(name: "origin/main")
        XCTAssertEqual(ref.color, .orange)
    }

    func testRefTagColorYellow() {
        let ref = Ref.tag(name: "v1.0")
        XCTAssertEqual(ref.color, .yellow)
    }

    func testRefHeadColorCyan() {
        let ref = Ref.head
        XCTAssertEqual(ref.color, .cyan)
    }

    // MARK: - Ref: icon

    func testRefLocalBranchIcon() {
        let ref = Ref.localBranch(name: "main", isCurrent: false)
        XCTAssertEqual(ref.icon, "arrow.triangle.branch")
    }

    func testRefRemoteBranchIcon() {
        let ref = Ref.remoteBranch(name: "origin/main")
        XCTAssertEqual(ref.icon, "cloud")
    }

    func testRefTagIcon() {
        let ref = Ref.tag(name: "v1.0")
        XCTAssertEqual(ref.icon, "tag")
    }

    func testRefHeadIcon() {
        let ref = Ref.head
        XCTAssertEqual(ref.icon, "arrow.right.circle")
    }

    // MARK: - Ref: id

    func testRefLocalBranchID() {
        let ref = Ref.localBranch(name: "main", isCurrent: true)
        XCTAssertEqual(ref.id, "local/main")
    }

    func testRefRemoteBranchID() {
        let ref = Ref.remoteBranch(name: "origin/main")
        XCTAssertEqual(ref.id, "remote/origin/main")
    }

    func testRefTagID() {
        let ref = Ref.tag(name: "v1.0")
        XCTAssertEqual(ref.id, "tag/v1.0")
    }

    func testRefHeadID() {
        let ref = Ref.head
        XCTAssertEqual(ref.id, "HEAD")
    }

    // MARK: - Ref: Hashable

    func testRefHashableEquality() {
        let r1 = Ref.localBranch(name: "main", isCurrent: true)
        let r2 = Ref.localBranch(name: "main", isCurrent: true)
        XCTAssertEqual(r1, r2)
    }

    func testRefHashableInequality() {
        let r1 = Ref.localBranch(name: "main", isCurrent: true)
        let r2 = Ref.localBranch(name: "main", isCurrent: false)
        XCTAssertNotEqual(r1, r2)
    }

    func testRefInSet() {
        let refs: Set<Ref> = [.head, .tag(name: "v1"), .localBranch(name: "main", isCurrent: false)]
        XCTAssertEqual(refs.count, 3)
        XCTAssertTrue(refs.contains(.head))
    }

    // MARK: - Commit: Equality and Hashing

    func testCommitEqualityBySHA() {
        let c1 = Commit(
            id: "abc123", shortSHA: "abc", subject: "A", body: "",
            author: "Alice", authorEmail: "a@a.com", authorDate: Date(),
            committer: "Alice", committerDate: Date(), parentIDs: []
        )
        let c2 = Commit(
            id: "abc123", shortSHA: "abc", subject: "Different subject", body: "body",
            author: "Bob", authorEmail: "b@b.com", authorDate: Date.distantPast,
            committer: "Bob", committerDate: Date.distantPast, parentIDs: ["xyz"]
        )
        XCTAssertEqual(c1, c2, "Commits with the same id should be equal")
    }

    func testCommitInequalityDifferentSHA() {
        let c1 = Commit(
            id: "abc", shortSHA: "a", subject: "A", body: "",
            author: "A", authorEmail: "a@a.com", authorDate: Date(),
            committer: "A", committerDate: Date(), parentIDs: []
        )
        let c2 = Commit(
            id: "def", shortSHA: "d", subject: "A", body: "",
            author: "A", authorEmail: "a@a.com", authorDate: Date(),
            committer: "A", committerDate: Date(), parentIDs: []
        )
        XCTAssertNotEqual(c1, c2)
    }

    func testCommitHashingConsistent() {
        let c1 = Commit(
            id: "same", shortSHA: "s", subject: "S", body: "",
            author: "A", authorEmail: "a@a.com", authorDate: Date(),
            committer: "A", committerDate: Date(), parentIDs: []
        )
        let c2 = Commit(
            id: "same", shortSHA: "s", subject: "Different", body: "body",
            author: "B", authorEmail: "b@b.com", authorDate: Date.distantPast,
            committer: "B", committerDate: Date.distantPast, parentIDs: ["p"]
        )
        XCTAssertEqual(c1.hashValue, c2.hashValue, "Same id should produce same hash")
    }

    func testCommitInSet() {
        let c1 = Commit(
            id: "a", shortSHA: "a", subject: "A", body: "",
            author: "A", authorEmail: "a@a.com", authorDate: Date(),
            committer: "A", committerDate: Date(), parentIDs: []
        )
        let c2 = Commit(
            id: "a", shortSHA: "a", subject: "B", body: "",
            author: "B", authorEmail: "b@b.com", authorDate: Date(),
            committer: "B", committerDate: Date(), parentIDs: []
        )
        let set: Set<Commit> = [c1, c2]
        XCTAssertEqual(set.count, 1, "Set should deduplicate by id")
    }

    // MARK: - FileDiff: displayPath

    func testFileDiffDisplayPathForModified() {
        let file = FileDiff(id: "f", oldPath: "file.txt", newPath: "file.txt", status: .modified, hunks: [])
        XCTAssertEqual(file.displayPath, "file.txt")
    }

    func testFileDiffDisplayPathForRenamed() {
        let file = FileDiff(id: "f", oldPath: "old.txt", newPath: "new.txt", status: .renamed, hunks: [])
        XCTAssertEqual(file.displayPath, "old.txt \u{2192} new.txt")
    }

    func testFileDiffDisplayPathForAdded() {
        let file = FileDiff(id: "f", oldPath: "file.txt", newPath: "file.txt", status: .added, hunks: [])
        XCTAssertEqual(file.displayPath, "file.txt")
    }

    func testFileDiffDisplayPathForDeleted() {
        let file = FileDiff(id: "f", oldPath: "file.txt", newPath: "file.txt", status: .deleted, hunks: [])
        XCTAssertEqual(file.displayPath, "file.txt")
    }

    // MARK: - FileStatus: label

    func testFileStatusLabels() {
        XCTAssertEqual(FileStatus.added.label, "A")
        XCTAssertEqual(FileStatus.modified.label, "M")
        XCTAssertEqual(FileStatus.deleted.label, "D")
        XCTAssertEqual(FileStatus.renamed.label, "R")
        XCTAssertEqual(FileStatus.copied.label, "C")
        XCTAssertEqual(FileStatus.unknown.label, "?")
    }

    // MARK: - FileStatus: rawValue

    func testFileStatusRawValues() {
        XCTAssertEqual(FileStatus.added.rawValue, "A")
        XCTAssertEqual(FileStatus.modified.rawValue, "M")
        XCTAssertEqual(FileStatus.deleted.rawValue, "D")
        XCTAssertEqual(FileStatus.renamed.rawValue, "R")
        XCTAssertEqual(FileStatus.copied.rawValue, "C")
        XCTAssertEqual(FileStatus.unknown.rawValue, "?")
    }

    func testFileStatusFromRawValue() {
        XCTAssertEqual(FileStatus(rawValue: "A"), .added)
        XCTAssertEqual(FileStatus(rawValue: "M"), .modified)
        XCTAssertEqual(FileStatus(rawValue: "D"), .deleted)
        XCTAssertEqual(FileStatus(rawValue: "R"), .renamed)
        XCTAssertEqual(FileStatus(rawValue: "C"), .copied)
        XCTAssertEqual(FileStatus(rawValue: "?"), .unknown)
        XCTAssertNil(FileStatus(rawValue: "X"))
    }

    // MARK: - Virtual Commit Entries (Staged/Unstaged)

    func testVirtualStagedCommitEntry() {
        let staged = Commit(
            id: "__STAGED__",
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
        )

        XCTAssertEqual(staged.id, "__STAGED__")
        XCTAssertEqual(staged.shortSHA, "")
        XCTAssertEqual(staged.subject, "Staged changes (index)")
        XCTAssertEqual(staged.author, "")
        XCTAssertEqual(staged.authorEmail, "")
        XCTAssertTrue(staged.parentIDs.isEmpty)
        XCTAssertEqual(staged.refs.count, 1)
        XCTAssertEqual(staged.refs[0], .localBranch(name: "index", isCurrent: false))
    }

    func testVirtualUnstagedCommitEntry() {
        let unstaged = Commit(
            id: "__UNSTAGED__",
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
        )

        XCTAssertEqual(unstaged.id, "__UNSTAGED__")
        XCTAssertEqual(unstaged.shortSHA, "")
        XCTAssertEqual(unstaged.subject, "Unstaged changes")
        XCTAssertEqual(unstaged.author, "")
        XCTAssertEqual(unstaged.authorEmail, "")
        XCTAssertTrue(unstaged.parentIDs.isEmpty)
        XCTAssertEqual(unstaged.refs[0], .localBranch(name: "working tree", isCurrent: false))
    }

    func testVirtualEntriesAreNotEqualToEachOther() {
        let staged = Commit(
            id: "__STAGED__", shortSHA: "", subject: "Staged", body: "",
            author: "", authorEmail: "", authorDate: Date(),
            committer: "", committerDate: Date(), parentIDs: []
        )
        let unstaged = Commit(
            id: "__UNSTAGED__", shortSHA: "", subject: "Unstaged", body: "",
            author: "", authorEmail: "", authorDate: Date(),
            committer: "", committerDate: Date(), parentIDs: []
        )
        XCTAssertNotEqual(staged, unstaged)
    }

    func testVirtualEntriesNotEqualToRealCommit() {
        let staged = Commit(
            id: "__STAGED__", shortSHA: "", subject: "Staged", body: "",
            author: "", authorEmail: "", authorDate: Date(),
            committer: "", committerDate: Date(), parentIDs: []
        )
        let real = Commit(
            id: "abc123", shortSHA: "abc", subject: "Real commit", body: "",
            author: "Alice", authorEmail: "a@a.com", authorDate: Date(),
            committer: "Alice", committerDate: Date(), parentIDs: []
        )
        XCTAssertNotEqual(staged, real)
    }

    func testVirtualEntriesInSet() {
        let staged = Commit(
            id: "__STAGED__", shortSHA: "", subject: "Staged", body: "",
            author: "", authorEmail: "", authorDate: Date(),
            committer: "", committerDate: Date(), parentIDs: []
        )
        let unstaged = Commit(
            id: "__UNSTAGED__", shortSHA: "", subject: "Unstaged", body: "",
            author: "", authorEmail: "", authorDate: Date(),
            committer: "", committerDate: Date(), parentIDs: []
        )
        let real = Commit(
            id: "abc123", shortSHA: "abc", subject: "Real", body: "",
            author: "Alice", authorEmail: "a@a.com", authorDate: Date(),
            committer: "Alice", committerDate: Date(), parentIDs: []
        )
        let set: Set<Commit> = [staged, unstaged, real]
        XCTAssertEqual(set.count, 3, "Virtual entries and real commits should all be unique in a set")
    }

    // MARK: - Commit with No Author/Email (virtual entries pattern)

    func testCommitWithEmptyAuthorAndEmail() {
        let commit = Commit(
            id: "virtual", shortSHA: "", subject: "Virtual", body: "",
            author: "", authorEmail: "", authorDate: Date(),
            committer: "", committerDate: Date(), parentIDs: []
        )
        XCTAssertEqual(commit.author, "")
        XCTAssertEqual(commit.authorEmail, "")
        XCTAssertEqual(commit.committer, "")
        XCTAssertEqual(commit.shortSHA, "")
    }

    func testCommitWithEmptyAuthorHashesConsistently() {
        let c1 = Commit(
            id: "virtual1", shortSHA: "", subject: "A", body: "",
            author: "", authorEmail: "", authorDate: Date(),
            committer: "", committerDate: Date(), parentIDs: []
        )
        let c2 = Commit(
            id: "virtual1", shortSHA: "", subject: "B", body: "",
            author: "", authorEmail: "", authorDate: Date.distantPast,
            committer: "", committerDate: Date.distantPast, parentIDs: []
        )
        XCTAssertEqual(c1, c2, "Commits with same id should be equal regardless of empty author fields")
        XCTAssertEqual(c1.hashValue, c2.hashValue)
    }
}
