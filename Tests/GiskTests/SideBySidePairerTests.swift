import XCTest
@testable import GiskLib

final class SideBySidePairerTests: XCTestCase {

    // MARK: - Helpers

    private func line(_ id: Int, _ type: DiffLineType, _ text: String, old: Int? = nil, new: Int? = nil) -> DiffLine {
        DiffLine(id: id, type: type, oldLineNumber: old, newLineNumber: new, text: text)
    }

    // MARK: - Empty input

    func testEmptyLines() {
        let pairs = SideBySidePairer.pair(lines: [])
        XCTAssertTrue(pairs.isEmpty)
    }

    // MARK: - Context only

    func testContextLinesAppearOnBothSides() {
        let lines = [
            line(1, .context, "hello", old: 1, new: 1),
            line(2, .context, "world", old: 2, new: 2),
        ]
        let pairs = SideBySidePairer.pair(lines: lines)

        XCTAssertEqual(pairs.count, 2)
        XCTAssertEqual(pairs[0].left?.text, "hello")
        XCTAssertEqual(pairs[0].right?.text, "hello")
        XCTAssertEqual(pairs[1].left?.text, "world")
        XCTAssertEqual(pairs[1].right?.text, "world")
    }

    // MARK: - Additions only

    func testAdditionOnlyHasNilLeft() {
        let lines = [
            line(1, .addition, "new line", new: 1),
        ]
        let pairs = SideBySidePairer.pair(lines: lines)

        XCTAssertEqual(pairs.count, 1)
        XCTAssertNil(pairs[0].left)
        XCTAssertEqual(pairs[0].right?.text, "new line")
    }

    func testMultipleAdditions() {
        let lines = [
            line(1, .addition, "a", new: 1),
            line(2, .addition, "b", new: 2),
            line(3, .addition, "c", new: 3),
        ]
        let pairs = SideBySidePairer.pair(lines: lines)

        XCTAssertEqual(pairs.count, 3)
        for pair in pairs {
            XCTAssertNil(pair.left)
            XCTAssertNotNil(pair.right)
        }
    }

    // MARK: - Deletions only

    func testDeletionOnlyHasNilRight() {
        let lines = [
            line(1, .deletion, "old line", old: 1),
        ]
        let pairs = SideBySidePairer.pair(lines: lines)

        XCTAssertEqual(pairs.count, 1)
        XCTAssertEqual(pairs[0].left?.text, "old line")
        XCTAssertNil(pairs[0].right)
    }

    // MARK: - Paired deletions and additions

    func testEqualDeletionsAndAdditionsPairUp() {
        let lines = [
            line(1, .deletion, "old a", old: 1),
            line(2, .deletion, "old b", old: 2),
            line(3, .addition, "new a", new: 1),
            line(4, .addition, "new b", new: 2),
        ]
        let pairs = SideBySidePairer.pair(lines: lines)

        XCTAssertEqual(pairs.count, 2)
        XCTAssertEqual(pairs[0].left?.text, "old a")
        XCTAssertEqual(pairs[0].right?.text, "new a")
        XCTAssertEqual(pairs[1].left?.text, "old b")
        XCTAssertEqual(pairs[1].right?.text, "new b")
    }

    func testMoreDeletionsThanAdditions() {
        let lines = [
            line(1, .deletion, "old a", old: 1),
            line(2, .deletion, "old b", old: 2),
            line(3, .deletion, "old c", old: 3),
            line(4, .addition, "new a", new: 1),
        ]
        let pairs = SideBySidePairer.pair(lines: lines)

        XCTAssertEqual(pairs.count, 3)
        XCTAssertEqual(pairs[0].left?.text, "old a")
        XCTAssertEqual(pairs[0].right?.text, "new a")
        XCTAssertEqual(pairs[1].left?.text, "old b")
        XCTAssertNil(pairs[1].right)
        XCTAssertEqual(pairs[2].left?.text, "old c")
        XCTAssertNil(pairs[2].right)
    }

    func testMoreAdditionsThanDeletions() {
        let lines = [
            line(1, .deletion, "old a", old: 1),
            line(2, .addition, "new a", new: 1),
            line(3, .addition, "new b", new: 2),
            line(4, .addition, "new c", new: 3),
        ]
        let pairs = SideBySidePairer.pair(lines: lines)

        XCTAssertEqual(pairs.count, 3)
        XCTAssertEqual(pairs[0].left?.text, "old a")
        XCTAssertEqual(pairs[0].right?.text, "new a")
        XCTAssertNil(pairs[1].left)
        XCTAssertEqual(pairs[1].right?.text, "new b")
        XCTAssertNil(pairs[2].left)
        XCTAssertEqual(pairs[2].right?.text, "new c")
    }

    // MARK: - Mixed sequences

    func testContextThenDeletionThenAddition() {
        let lines = [
            line(1, .context, "unchanged", old: 1, new: 1),
            line(2, .deletion, "removed", old: 2),
            line(3, .addition, "added", new: 2),
            line(4, .context, "also unchanged", old: 3, new: 3),
        ]
        let pairs = SideBySidePairer.pair(lines: lines)

        XCTAssertEqual(pairs.count, 3)
        // Context
        XCTAssertEqual(pairs[0].left?.text, "unchanged")
        XCTAssertEqual(pairs[0].right?.text, "unchanged")
        // Paired change
        XCTAssertEqual(pairs[1].left?.text, "removed")
        XCTAssertEqual(pairs[1].right?.text, "added")
        // Context
        XCTAssertEqual(pairs[2].left?.text, "also unchanged")
        XCTAssertEqual(pairs[2].right?.text, "also unchanged")
    }

    func testAdditionsBetweenContextLines() {
        let lines = [
            line(1, .context, "before", old: 1, new: 1),
            line(2, .addition, "inserted", new: 2),
            line(3, .context, "after", old: 2, new: 3),
        ]
        let pairs = SideBySidePairer.pair(lines: lines)

        XCTAssertEqual(pairs.count, 3)
        XCTAssertNotNil(pairs[0].left)
        XCTAssertNotNil(pairs[0].right)
        XCTAssertNil(pairs[1].left)
        XCTAssertEqual(pairs[1].right?.text, "inserted")
        XCTAssertNotNil(pairs[2].left)
        XCTAssertNotNil(pairs[2].right)
    }

    // MARK: - Hunk headers are skipped

    func testHunkHeadersAreSkipped() {
        let lines = [
            line(0, .hunkHeader, "@@ -1,3 +1,3 @@"),
            line(1, .context, "same", old: 1, new: 1),
            line(2, .deletion, "old", old: 2),
            line(3, .addition, "new", new: 2),
        ]
        let pairs = SideBySidePairer.pair(lines: lines)

        XCTAssertEqual(pairs.count, 2)
        XCTAssertEqual(pairs[0].left?.text, "same")
        XCTAssertEqual(pairs[1].left?.text, "old")
        XCTAssertEqual(pairs[1].right?.text, "new")
    }

    // MARK: - Multiple change blocks

    func testMultipleSeparateChangeBlocks() {
        let lines = [
            line(1, .deletion, "old1", old: 1),
            line(2, .addition, "new1", new: 1),
            line(3, .context, "middle", old: 2, new: 2),
            line(4, .deletion, "old2", old: 3),
            line(5, .addition, "new2", new: 3),
        ]
        let pairs = SideBySidePairer.pair(lines: lines)

        XCTAssertEqual(pairs.count, 3)
        XCTAssertEqual(pairs[0].left?.text, "old1")
        XCTAssertEqual(pairs[0].right?.text, "new1")
        XCTAssertEqual(pairs[1].left?.text, "middle")
        XCTAssertEqual(pairs[1].right?.text, "middle")
        XCTAssertEqual(pairs[2].left?.text, "old2")
        XCTAssertEqual(pairs[2].right?.text, "new2")
    }
}
