import XCTest
@testable import GiskLib

final class GitDiffParserTests: XCTestCase {

    // MARK: - Single File Diff

    func testParseSingleFileDiff() {
        let input = """
        diff --git a/hello.txt b/hello.txt
        index 1234567..abcdefg 100644
        --- a/hello.txt
        +++ b/hello.txt
        @@ -1,3 +1,4 @@
         line1
         line2
        +line3
         line4
        """
        let diff = GitDiffParser.parse(input)
        XCTAssertEqual(diff.files.count, 1)

        let file = diff.files[0]
        XCTAssertEqual(file.oldPath, "hello.txt")
        XCTAssertEqual(file.newPath, "hello.txt")
        XCTAssertEqual(file.status, .modified)
        XCTAssertEqual(file.hunks.count, 1)
    }

    // MARK: - Multiple File Diffs

    func testParseMultipleFileDiffs() {
        let input = """
        diff --git a/file1.txt b/file1.txt
        index 1234567..abcdefg 100644
        --- a/file1.txt
        +++ b/file1.txt
        @@ -1,2 +1,3 @@
         a
        +b
         c
        diff --git a/file2.txt b/file2.txt
        index 1234567..abcdefg 100644
        --- a/file2.txt
        +++ b/file2.txt
        @@ -1,2 +1,2 @@
        -old
        +new
         keep
        """
        let diff = GitDiffParser.parse(input)
        XCTAssertEqual(diff.files.count, 2)
        XCTAssertEqual(diff.files[0].newPath, "file1.txt")
        XCTAssertEqual(diff.files[1].newPath, "file2.txt")
    }

    // MARK: - File Status Detection

    func testParseAddedFile() {
        let input = """
        diff --git a/new.txt b/new.txt
        new file mode 100644
        index 0000000..abcdefg
        --- /dev/null
        +++ b/new.txt
        @@ -0,0 +1,2 @@
        +hello
        +world
        """
        let diff = GitDiffParser.parse(input)
        XCTAssertEqual(diff.files[0].status, .added)
    }

    func testParseDeletedFile() {
        let input = """
        diff --git a/old.txt b/old.txt
        deleted file mode 100644
        index abcdefg..0000000
        --- a/old.txt
        +++ /dev/null
        @@ -1,2 +0,0 @@
        -goodbye
        -world
        """
        let diff = GitDiffParser.parse(input)
        XCTAssertEqual(diff.files[0].status, .deleted)
    }

    func testParseRenamedFile() {
        let input = """
        diff --git a/old_name.txt b/new_name.txt
        similarity index 95%
        rename from old_name.txt
        rename to new_name.txt
        index 1234567..abcdefg 100644
        --- a/old_name.txt
        +++ b/new_name.txt
        @@ -1,3 +1,3 @@
         same
        -old line
        +new line
         same
        """
        let diff = GitDiffParser.parse(input)
        XCTAssertEqual(diff.files[0].status, .renamed)
        XCTAssertEqual(diff.files[0].oldPath, "old_name.txt")
        XCTAssertEqual(diff.files[0].newPath, "new_name.txt")
    }

    func testParseModifiedFile() {
        let input = """
        diff --git a/mod.txt b/mod.txt
        index 1234567..abcdefg 100644
        --- a/mod.txt
        +++ b/mod.txt
        @@ -1,3 +1,3 @@
         a
        -b
        +c
         d
        """
        let diff = GitDiffParser.parse(input)
        XCTAssertEqual(diff.files[0].status, .modified)
    }

    // MARK: - Multiple Hunks

    func testParseMultipleHunks() {
        let input = """
        diff --git a/file.txt b/file.txt
        index 1234567..abcdefg 100644
        --- a/file.txt
        +++ b/file.txt
        @@ -1,3 +1,4 @@
         line1
        +inserted
         line2
         line3
        @@ -10,3 +11,4 @@
         line10
         line11
        +another insert
         line12
        """
        let diff = GitDiffParser.parse(input)
        XCTAssertEqual(diff.files[0].hunks.count, 2)

        let hunk1 = diff.files[0].hunks[0]
        XCTAssertEqual(hunk1.oldStart, 1)
        XCTAssertEqual(hunk1.oldCount, 3)
        XCTAssertEqual(hunk1.newStart, 1)
        XCTAssertEqual(hunk1.newCount, 4)

        let hunk2 = diff.files[0].hunks[1]
        XCTAssertEqual(hunk2.oldStart, 10)
        XCTAssertEqual(hunk2.oldCount, 3)
        XCTAssertEqual(hunk2.newStart, 11)
        XCTAssertEqual(hunk2.newCount, 4)
    }

    // MARK: - Line Types

    func testDiffLineTypes() {
        let input = """
        diff --git a/file.txt b/file.txt
        index 1234567..abcdefg 100644
        --- a/file.txt
        +++ b/file.txt
        @@ -1,3 +1,3 @@
         context line
        -deleted line
        +added line
        """
        let diff = GitDiffParser.parse(input)
        let lines = diff.files[0].hunks[0].lines

        XCTAssertEqual(lines.count, 3)
        XCTAssertEqual(lines[0].type, .context)
        XCTAssertEqual(lines[0].text, "context line")
        XCTAssertEqual(lines[0].oldLineNumber, 1)
        XCTAssertEqual(lines[0].newLineNumber, 1)

        XCTAssertEqual(lines[1].type, .deletion)
        XCTAssertEqual(lines[1].text, "deleted line")
        XCTAssertEqual(lines[1].oldLineNumber, 2)
        XCTAssertNil(lines[1].newLineNumber)

        XCTAssertEqual(lines[2].type, .addition)
        XCTAssertEqual(lines[2].text, "added line")
        XCTAssertNil(lines[2].oldLineNumber)
        XCTAssertEqual(lines[2].newLineNumber, 2)
    }

    // MARK: - Hunk Header Parsing

    func testHunkHeaderWithCounts() {
        let input = """
        diff --git a/f.txt b/f.txt
        index 123..abc 100644
        --- a/f.txt
        +++ b/f.txt
        @@ -10,6 +10,8 @@ func example() {
         context
        +added
        """
        let diff = GitDiffParser.parse(input)
        let hunk = diff.files[0].hunks[0]
        XCTAssertEqual(hunk.oldStart, 10)
        XCTAssertEqual(hunk.oldCount, 6)
        XCTAssertEqual(hunk.newStart, 10)
        XCTAssertEqual(hunk.newCount, 8)
    }

    func testHunkHeaderWithoutCounts() {
        // When count is omitted, it means 1
        let input = """
        diff --git a/f.txt b/f.txt
        index 123..abc 100644
        --- a/f.txt
        +++ b/f.txt
        @@ -5 +5 @@ header
        -old
        +new
        """
        let diff = GitDiffParser.parse(input)
        let hunk = diff.files[0].hunks[0]
        XCTAssertEqual(hunk.oldStart, 5)
        XCTAssertEqual(hunk.oldCount, 1)
        XCTAssertEqual(hunk.newStart, 5)
        XCTAssertEqual(hunk.newCount, 1)
    }

    // MARK: - parseNameStatus

    func testParseNameStatusAdded() {
        let input = "A\tfile.txt\n"
        let results = GitDiffParser.parseNameStatus(input)
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results[0].0, .added)
        XCTAssertEqual(results[0].1, "file.txt")
    }

    func testParseNameStatusModified() {
        let input = "M\tfile.txt\n"
        let results = GitDiffParser.parseNameStatus(input)
        XCTAssertEqual(results[0].0, .modified)
    }

    func testParseNameStatusDeleted() {
        let input = "D\tfile.txt\n"
        let results = GitDiffParser.parseNameStatus(input)
        XCTAssertEqual(results[0].0, .deleted)
    }

    func testParseNameStatusRenamed() {
        let input = "R100\told.txt\tnew.txt\n"
        let results = GitDiffParser.parseNameStatus(input)
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results[0].0, .renamed)
        XCTAssertEqual(results[0].1, "new.txt")
    }

    func testParseNameStatusCopied() {
        let input = "C100\tsrc.txt\tdst.txt\n"
        let results = GitDiffParser.parseNameStatus(input)
        XCTAssertEqual(results[0].0, .copied)
        XCTAssertEqual(results[0].1, "dst.txt")
    }

    func testParseNameStatusMultipleEntries() {
        let input = "A\tnew.txt\nM\texisting.txt\nD\told.txt\n"
        let results = GitDiffParser.parseNameStatus(input)
        XCTAssertEqual(results.count, 3)
        XCTAssertEqual(results[0].0, .added)
        XCTAssertEqual(results[1].0, .modified)
        XCTAssertEqual(results[2].0, .deleted)
    }

    func testParseNameStatusEmptyInput() {
        let results = GitDiffParser.parseNameStatus("")
        XCTAssertTrue(results.isEmpty)
    }

    func testParseNameStatusUnknownStatus() {
        let input = "X\tfile.txt\n"
        let results = GitDiffParser.parseNameStatus(input)
        XCTAssertEqual(results[0].0, .unknown)
    }

    // MARK: - Empty Diff

    func testParseEmptyDiffOutput() {
        let diff = GitDiffParser.parse("")
        XCTAssertTrue(diff.files.isEmpty)
    }

    func testParseWhitespaceOnlyDiffOutput() {
        let diff = GitDiffParser.parse("   \n\n  \n")
        XCTAssertTrue(diff.files.isEmpty)
    }

    // MARK: - Root Commit Diff (--root format, /dev/null as old)

    func testParseRootCommitDiff() {
        // Root commits show /dev/null as the old file
        let input = """
        diff --git a/README.md b/README.md
        new file mode 100644
        index 0000000..e69de29
        --- /dev/null
        +++ b/README.md
        @@ -0,0 +1,3 @@
        +# Project
        +
        +Initial readme content
        """
        let diff = GitDiffParser.parse(input)
        XCTAssertEqual(diff.files.count, 1)

        let file = diff.files[0]
        XCTAssertEqual(file.status, .added)
        XCTAssertEqual(file.newPath, "README.md")
        XCTAssertEqual(file.hunks.count, 1)

        let lines = file.hunks[0].lines
        XCTAssertEqual(lines.count, 3)
        XCTAssertTrue(lines.allSatisfy { $0.type == .addition })
        XCTAssertEqual(lines[0].text, "# Project")
    }

    func testParseRootCommitMultipleNewFiles() {
        let input = """
        diff --git a/file1.txt b/file1.txt
        new file mode 100644
        index 0000000..abcdef1
        --- /dev/null
        +++ b/file1.txt
        @@ -0,0 +1,2 @@
        +hello
        +world
        diff --git a/file2.txt b/file2.txt
        new file mode 100644
        index 0000000..abcdef2
        --- /dev/null
        +++ b/file2.txt
        @@ -0,0 +1 @@
        +single line
        """
        let diff = GitDiffParser.parse(input)
        XCTAssertEqual(diff.files.count, 2)
        XCTAssertEqual(diff.files[0].status, .added)
        XCTAssertEqual(diff.files[0].newPath, "file1.txt")
        XCTAssertEqual(diff.files[1].status, .added)
        XCTAssertEqual(diff.files[1].newPath, "file2.txt")
    }

    // MARK: - Merge Diff (diff between two commits)

    func testParseMergeDiff() {
        // Merge diffs look like regular diffs (git diff parent1 merge_commit)
        let input = """
        diff --git a/feature.swift b/feature.swift
        index 1234567..abcdefg 100644
        --- a/feature.swift
        +++ b/feature.swift
        @@ -1,4 +1,6 @@
         import Foundation
        +import UIKit

         struct Feature {
        +    var name: String
         }
        """
        let diff = GitDiffParser.parse(input)
        XCTAssertEqual(diff.files.count, 1)

        let file = diff.files[0]
        XCTAssertEqual(file.status, .modified)
        XCTAssertEqual(file.newPath, "feature.swift")
        XCTAssertEqual(file.hunks.count, 1)

        let lines = file.hunks[0].lines
        let additions = lines.filter { $0.type == .addition }
        XCTAssertEqual(additions.count, 2)
        XCTAssertEqual(additions[0].text, "import UIKit")
        XCTAssertEqual(additions[1].text, "    var name: String")
    }

    func testParseMergeDiffWithAddedAndDeletedFiles() {
        let input = """
        diff --git a/removed.txt b/removed.txt
        deleted file mode 100644
        index abcdefg..0000000
        --- a/removed.txt
        +++ /dev/null
        @@ -1,2 +0,0 @@
        -old content
        -more old content
        diff --git a/added.txt b/added.txt
        new file mode 100644
        index 0000000..1234567
        --- /dev/null
        +++ b/added.txt
        @@ -0,0 +1 @@
        +new file content
        """
        let diff = GitDiffParser.parse(input)
        XCTAssertEqual(diff.files.count, 2)
        XCTAssertEqual(diff.files[0].status, .deleted)
        XCTAssertEqual(diff.files[0].newPath, "removed.txt")
        XCTAssertEqual(diff.files[1].status, .added)
        XCTAssertEqual(diff.files[1].newPath, "added.txt")
    }

    // MARK: - Staged Changes Diff

    func testParseStagedChangesDiff() {
        // Staged diffs (--cached) have the same format as regular diffs
        let input = """
        diff --git a/staged.swift b/staged.swift
        index 1234567..abcdefg 100644
        --- a/staged.swift
        +++ b/staged.swift
        @@ -5,3 +5,4 @@ class MyClass {
         func existing() {}
        +func newMethod() {}

         }
        """
        let diff = GitDiffParser.parse(input)
        XCTAssertEqual(diff.files.count, 1)

        let file = diff.files[0]
        XCTAssertEqual(file.status, .modified)
        XCTAssertEqual(file.hunks.count, 1)

        let hunk = file.hunks[0]
        XCTAssertEqual(hunk.oldStart, 5)
        XCTAssertEqual(hunk.newStart, 5)

        let additions = hunk.lines.filter { $0.type == .addition }
        XCTAssertEqual(additions.count, 1)
        XCTAssertEqual(additions[0].text, "func newMethod() {}")
    }

    func testParseStagedNewFile() {
        // A newly staged file (git add newfile.txt && git diff --cached)
        let input = """
        diff --git a/brand_new.txt b/brand_new.txt
        new file mode 100644
        index 0000000..abc1234
        --- /dev/null
        +++ b/brand_new.txt
        @@ -0,0 +1,3 @@
        +line one
        +line two
        +line three
        """
        let diff = GitDiffParser.parse(input)
        XCTAssertEqual(diff.files.count, 1)
        XCTAssertEqual(diff.files[0].status, .added)
        XCTAssertEqual(diff.files[0].newPath, "brand_new.txt")

        let lines = diff.files[0].hunks[0].lines
        XCTAssertEqual(lines.count, 3)
        XCTAssertTrue(lines.allSatisfy { $0.type == .addition })
        // For a new file starting at line 0,0 -> 1, additions start at new line 1
        XCTAssertEqual(lines[0].newLineNumber, 1)
        XCTAssertEqual(lines[2].newLineNumber, 3)
    }

    // MARK: - Line Number Tracking

    func testLineNumbersTrackCorrectly() {
        let input = """
        diff --git a/f.txt b/f.txt
        index 123..abc 100644
        --- a/f.txt
        +++ b/f.txt
        @@ -5,4 +5,5 @@
         ctx1
        -del1
        +add1
        +add2
         ctx2
        """
        let diff = GitDiffParser.parse(input)
        let lines = diff.files[0].hunks[0].lines

        // ctx1: old=5, new=5
        XCTAssertEqual(lines[0].oldLineNumber, 5)
        XCTAssertEqual(lines[0].newLineNumber, 5)

        // del1: old=6, new=nil
        XCTAssertEqual(lines[1].oldLineNumber, 6)
        XCTAssertNil(lines[1].newLineNumber)

        // add1: old=nil, new=6
        XCTAssertNil(lines[2].oldLineNumber)
        XCTAssertEqual(lines[2].newLineNumber, 6)

        // add2: old=nil, new=7
        XCTAssertNil(lines[3].oldLineNumber)
        XCTAssertEqual(lines[3].newLineNumber, 7)

        // ctx2: old=7, new=8
        XCTAssertEqual(lines[4].oldLineNumber, 7)
        XCTAssertEqual(lines[4].newLineNumber, 8)
    }
}
