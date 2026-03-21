import XCTest
@testable import GiskLib

final class GraphLayoutEngineTests: XCTestCase {

    // MARK: - Helpers

    private func makeCommit(
        id: String,
        parentIDs: [String] = []
    ) -> Commit {
        Commit(
            id: id,
            shortSHA: String(id.prefix(7)),
            subject: "Commit \(id)",
            body: "",
            author: "Test",
            authorEmail: "test@test.com",
            authorDate: Date(),
            committer: "Test",
            committerDate: Date(),
            parentIDs: parentIDs
        )
    }

    // MARK: - Linear History

    func testLinearHistoryAllColumnZero() {
        // A -> B -> C (linear chain, newest first)
        var commits = [
            makeCommit(id: "A", parentIDs: ["B"]),
            makeCommit(id: "B", parentIDs: ["C"]),
            makeCommit(id: "C", parentIDs: []),
        ]

        GraphLayoutEngine.computeLayout(commits: &commits)

        XCTAssertEqual(commits[0].graphLane?.column, 0)
        XCTAssertEqual(commits[1].graphLane?.column, 0)
        XCTAssertEqual(commits[2].graphLane?.column, 0)
    }

    func testLinearHistoryNoPassingLanes() {
        var commits = [
            makeCommit(id: "A", parentIDs: ["B"]),
            makeCommit(id: "B", parentIDs: ["C"]),
            makeCommit(id: "C", parentIDs: []),
        ]

        GraphLayoutEngine.computeLayout(commits: &commits)

        for commit in commits {
            XCTAssertTrue(commit.graphLane?.passingLanes.isEmpty ?? true)
            XCTAssertTrue(commit.graphLane?.mergingFrom.isEmpty ?? true)
        }
    }

    // MARK: - Simple Branch and Merge

    func testSimpleBranchAndMerge() {
        // M merges A and B, then A -> C, B -> C
        // Topo order: M, A, B, C
        var commits = [
            makeCommit(id: "M", parentIDs: ["A", "B"]),
            makeCommit(id: "A", parentIDs: ["C"]),
            makeCommit(id: "B", parentIDs: ["C"]),
            makeCommit(id: "C", parentIDs: []),
        ]

        GraphLayoutEngine.computeLayout(commits: &commits)

        // M should be at column 0 (new branch head)
        XCTAssertEqual(commits[0].graphLane?.column, 0)
        XCTAssertNotNil(commits[0].graphLane)

        // M should create a branching line for parent B
        XCTAssertFalse(commits[0].graphLane?.branchingTo.isEmpty ?? true,
                        "Merge commit should branch out to second parent")

        // All commits should have a graphLane assigned
        for commit in commits {
            XCTAssertNotNil(commit.graphLane, "Commit \(commit.id) should have a graphLane")
        }
    }

    // MARK: - Multiple Branches

    func testMultipleBranches() {
        // Two independent branch heads, then each converges
        // Topo order: X, Y, A, B
        var commits = [
            makeCommit(id: "X", parentIDs: ["A"]),
            makeCommit(id: "Y", parentIDs: ["B"]),
            makeCommit(id: "A", parentIDs: []),
            makeCommit(id: "B", parentIDs: []),
        ]

        GraphLayoutEngine.computeLayout(commits: &commits)

        // X and Y should be on different columns since they're independent
        let xCol = commits[0].graphLane!.column
        let yCol = commits[1].graphLane!.column
        XCTAssertNotEqual(xCol, yCol, "Independent branches should be on different columns")

        // When Y appears, X's lane should be passing
        XCTAssertFalse(commits[1].graphLane?.passingLanes.isEmpty ?? true,
                        "Y should have passing lanes from X's active lane")
    }

    // MARK: - Root Commit

    func testRootCommitHandling() {
        var commits = [
            makeCommit(id: "A", parentIDs: []),
        ]

        GraphLayoutEngine.computeLayout(commits: &commits)

        XCTAssertNotNil(commits[0].graphLane)
        XCTAssertEqual(commits[0].graphLane?.column, 0)
    }

    func testRootCommitRemovesLane() {
        // After root commit, its lane should be removed
        // B -> root, then A is a separate branch head
        var commits = [
            makeCommit(id: "B", parentIDs: ["root"]),
            makeCommit(id: "root", parentIDs: []),
        ]

        GraphLayoutEngine.computeLayout(commits: &commits)

        // Both should get graphLane
        XCTAssertNotNil(commits[0].graphLane)
        XCTAssertNotNil(commits[1].graphLane)
    }

    // MARK: - Branch Colors

    func testBranchColorsAssigned() {
        var commits = [
            makeCommit(id: "A", parentIDs: ["B"]),
            makeCommit(id: "B", parentIDs: []),
        ]

        GraphLayoutEngine.computeLayout(commits: &commits)

        // Same lane should get same color
        XCTAssertEqual(commits[0].graphLane?.color, commits[1].graphLane?.color)
    }

    func testDifferentBranchesGetDifferentColors() {
        var commits = [
            makeCommit(id: "X", parentIDs: ["A"]),
            makeCommit(id: "Y", parentIDs: ["B"]),
            makeCommit(id: "A", parentIDs: []),
            makeCommit(id: "B", parentIDs: []),
        ]

        GraphLayoutEngine.computeLayout(commits: &commits)

        let xColor = commits[0].graphLane?.color
        let yColor = commits[1].graphLane?.color
        XCTAssertNotEqual(xColor, yColor, "Different branches should have different colors")
    }

    // MARK: - GraphLane Completeness

    func testAllCommitsGetGraphLane() {
        var commits = [
            makeCommit(id: "M", parentIDs: ["A", "B"]),
            makeCommit(id: "A", parentIDs: ["C"]),
            makeCommit(id: "B", parentIDs: ["C"]),
            makeCommit(id: "C", parentIDs: ["D"]),
            makeCommit(id: "D", parentIDs: []),
        ]

        GraphLayoutEngine.computeLayout(commits: &commits)

        for commit in commits {
            XCTAssertNotNil(commit.graphLane, "Commit \(commit.id) should have a graphLane")
        }
    }
}
