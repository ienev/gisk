import XCTest
@testable import GiskLib

final class GitLogParserTests: XCTestCase {

    // MARK: - Helpers

    /// Build a single commit record with NUL-delimited fields and trailing record separator.
    private func makeRecord(
        fullSHA: String = "abc123def456abc123def456abc123def456abc1",
        shortSHA: String = "abc123d",
        parents: String = "",
        subject: String = "Initial commit",
        authorName: String = "Alice",
        authorEmail: String = "alice@example.com",
        authorDate: String = "2024-01-15T10:30:00Z",
        committerName: String = "Alice",
        committerDate: String = "2024-01-15T10:30:00Z",
        refs: String = "",
        body: String = ""
    ) -> String {
        let fields = [
            fullSHA, shortSHA, parents, subject,
            authorName, authorEmail, authorDate,
            committerName, committerDate, refs, body
        ]
        return fields.joined(separator: "\u{00}")
    }

    private func wrapRecords(_ records: [String]) -> String {
        return records.joined(separator: "\u{1e}")
    }

    // MARK: - Single Commit

    func testParseSingleCommit() throws {
        let record = makeRecord()
        let output = record + "\u{1e}"

        let commits = try GitLogParser.parse(output)
        XCTAssertEqual(commits.count, 1)

        let commit = commits[0]
        XCTAssertEqual(commit.id, "abc123def456abc123def456abc123def456abc1")
        XCTAssertEqual(commit.shortSHA, "abc123d")
        XCTAssertEqual(commit.subject, "Initial commit")
        XCTAssertEqual(commit.author, "Alice")
        XCTAssertEqual(commit.authorEmail, "alice@example.com")
        XCTAssertEqual(commit.committer, "Alice")
        XCTAssertTrue(commit.parentIDs.isEmpty)
        XCTAssertTrue(commit.refs.isEmpty)
        XCTAssertEqual(commit.body, "")
    }

    // MARK: - Multiple Commits

    func testParseMultipleCommits() throws {
        let r1 = makeRecord(
            fullSHA: "aaaa",
            shortSHA: "aaa",
            parents: "bbbb",
            subject: "Second commit"
        )
        let r2 = makeRecord(
            fullSHA: "bbbb",
            shortSHA: "bbb",
            parents: "",
            subject: "First commit"
        )
        let output = wrapRecords([r1, r2])

        let commits = try GitLogParser.parse(output)
        XCTAssertEqual(commits.count, 2)
        XCTAssertEqual(commits[0].id, "aaaa")
        XCTAssertEqual(commits[1].id, "bbbb")
    }

    // MARK: - Merge Commits (Multiple Parents)

    func testParseMergeCommit() throws {
        let record = makeRecord(
            fullSHA: "merge1",
            shortSHA: "mer",
            parents: "parent1 parent2",
            subject: "Merge branch 'feature'"
        )
        let output = record + "\u{1e}"

        let commits = try GitLogParser.parse(output)
        XCTAssertEqual(commits.count, 1)
        XCTAssertEqual(commits[0].parentIDs, ["parent1", "parent2"])
    }

    func testParseOctopusMerge() throws {
        let record = makeRecord(
            parents: "p1 p2 p3"
        )
        let output = record + "\u{1e}"

        let commits = try GitLogParser.parse(output)
        XCTAssertEqual(commits[0].parentIDs, ["p1", "p2", "p3"])
    }

    // MARK: - Refs

    func testParseHeadRef() throws {
        let record = makeRecord(refs: "HEAD")
        let output = record + "\u{1e}"

        let commits = try GitLogParser.parse(output)
        XCTAssertEqual(commits[0].refs.count, 1)
        XCTAssertEqual(commits[0].refs[0], .head)
    }

    func testParseHeadWithCurrentBranch() throws {
        let record = makeRecord(refs: "HEAD -> main")
        let output = record + "\u{1e}"

        let commits = try GitLogParser.parse(output)
        XCTAssertEqual(commits[0].refs.count, 2)
        XCTAssertEqual(commits[0].refs[0], .head)
        XCTAssertEqual(commits[0].refs[1], .localBranch(name: "main", isCurrent: true))
    }

    func testParseTagRef() throws {
        let record = makeRecord(refs: "tag: v1.0.0")
        let output = record + "\u{1e}"

        let commits = try GitLogParser.parse(output)
        XCTAssertEqual(commits[0].refs.count, 1)
        XCTAssertEqual(commits[0].refs[0], .tag(name: "v1.0.0"))
    }

    func testParseRemoteBranch() throws {
        let record = makeRecord(refs: "origin/main")
        let output = record + "\u{1e}"

        let commits = try GitLogParser.parse(output)
        XCTAssertEqual(commits[0].refs.count, 1)
        XCTAssertEqual(commits[0].refs[0], .remoteBranch(name: "origin/main"))
    }

    func testParseLocalBranch() throws {
        let record = makeRecord(refs: "feature-x")
        let output = record + "\u{1e}"

        let commits = try GitLogParser.parse(output)
        XCTAssertEqual(commits[0].refs.count, 1)
        XCTAssertEqual(commits[0].refs[0], .localBranch(name: "feature-x", isCurrent: false))
    }

    func testParseMultipleRefs() throws {
        let record = makeRecord(refs: "HEAD -> main, tag: v2.0, origin/main")
        let output = record + "\u{1e}"

        let commits = try GitLogParser.parse(output)
        let refs = commits[0].refs
        XCTAssertEqual(refs.count, 4) // HEAD, main (current), tag: v2.0, origin/main
        XCTAssertEqual(refs[0], .head)
        XCTAssertEqual(refs[1], .localBranch(name: "main", isCurrent: true))
        XCTAssertEqual(refs[2], .tag(name: "v2.0"))
        XCTAssertEqual(refs[3], .remoteBranch(name: "origin/main"))
    }

    // MARK: - Empty Body

    func testParseCommitWithEmptyBody() throws {
        let record = makeRecord(body: "")
        let output = record + "\u{1e}"

        let commits = try GitLogParser.parse(output)
        XCTAssertEqual(commits[0].body, "")
    }

    func testParseCommitWithBody() throws {
        let record = makeRecord(body: "This is a detailed description\nof the changes made.")
        let output = record + "\u{1e}"

        let commits = try GitLogParser.parse(output)
        XCTAssertEqual(commits[0].body, "This is a detailed description\nof the changes made.")
    }

    // MARK: - Root Commits (No Parents)

    func testRootCommitHasNoParents() throws {
        let record = makeRecord(parents: "")
        let output = record + "\u{1e}"

        let commits = try GitLogParser.parse(output)
        XCTAssertTrue(commits[0].parentIDs.isEmpty)
    }

    // MARK: - Child ID Computation

    func testChildIDsComputed() throws {
        let r1 = makeRecord(
            fullSHA: "child1",
            shortSHA: "c1",
            parents: "parent1",
            subject: "Child commit"
        )
        let r2 = makeRecord(
            fullSHA: "parent1",
            shortSHA: "p1",
            parents: "",
            subject: "Parent commit"
        )
        let output = wrapRecords([r1, r2])

        let commits = try GitLogParser.parse(output)
        XCTAssertEqual(commits[1].childIDs, ["child1"])
        XCTAssertTrue(commits[0].childIDs.isEmpty)
    }

    func testChildIDsMultipleChildren() throws {
        let r1 = makeRecord(fullSHA: "c1", shortSHA: "c1", parents: "root", subject: "C1")
        let r2 = makeRecord(fullSHA: "c2", shortSHA: "c2", parents: "root", subject: "C2")
        let r3 = makeRecord(fullSHA: "root", shortSHA: "rt", parents: "", subject: "Root")
        let output = wrapRecords([r1, r2, r3])

        let commits = try GitLogParser.parse(output)
        let root = commits.first { $0.id == "root" }!
        XCTAssertEqual(Set(root.childIDs), Set(["c1", "c2"]))
    }

    // MARK: - Date Parsing

    func testParseDateWithFractionalSeconds() throws {
        let record = makeRecord(authorDate: "2024-06-15T14:30:00.123Z")
        let output = record + "\u{1e}"

        let commits = try GitLogParser.parse(output)
        XCTAssertNotEqual(commits[0].authorDate, Date.distantPast)
    }

    func testParseDateWithoutFractionalSeconds() throws {
        let record = makeRecord(authorDate: "2024-06-15T14:30:00Z")
        let output = record + "\u{1e}"

        let commits = try GitLogParser.parse(output)
        XCTAssertNotEqual(commits[0].authorDate, Date.distantPast)
    }

    // MARK: - Malformed Input

    func testEmptyInputReturnsNoCommits() throws {
        let commits = try GitLogParser.parse("")
        XCTAssertTrue(commits.isEmpty)
    }

    func testInsufficientFieldsSkipsRecord() throws {
        // Only 5 NUL-delimited fields (need at least 10)
        let bad = "a\u{00}b\u{00}c\u{00}d\u{00}e"
        let output = bad + "\u{1e}"

        let commits = try GitLogParser.parse(output)
        XCTAssertTrue(commits.isEmpty)
    }

    // MARK: - parseRefs (public method)

    func testParseRefsEmpty() {
        let refs = GitLogParser.parseRefs("")
        XCTAssertTrue(refs.isEmpty)
    }

    func testParseRefsHeadAlone() {
        let refs = GitLogParser.parseRefs("HEAD")
        XCTAssertEqual(refs, [.head])
    }
}
