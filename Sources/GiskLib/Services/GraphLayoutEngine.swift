import SwiftUI

public struct GraphLayoutEngine {
    public static let branchColors: [Color] = [
        .blue, .green, .red, .orange, .purple, .cyan, .pink, .yellow,
        .mint, .teal, .indigo,
    ]

    public static func computeLayout(commits: inout [Commit]) {
        // Active lanes: each lane tracks which commit SHA it's waiting for
        var activeLanes: [(sha: String, color: Color)] = []
        var colorIndex = 0

        func nextColor() -> Color {
            let c = branchColors[colorIndex % branchColors.count]
            colorIndex += 1
            return c
        }

        for i in commits.indices {
            let commit = commits[i]

            // Find which lanes expect this commit
            let matchingIndices = activeLanes.indices.filter { activeLanes[$0].sha == commit.id }

            let column: Int
            let nodeColor: Color

            if matchingIndices.isEmpty {
                // New branch head — append a new lane
                let color = nextColor()
                column = activeLanes.count
                activeLanes.append((sha: commit.id, color: color))
                nodeColor = color
            } else {
                // Use the leftmost matching lane as the commit's column
                column = matchingIndices[0]
                nodeColor = activeLanes[column].color
            }

            // Record passing lanes (all active lanes at this row)
            var passingLanes: [LaneLine] = []
            for (idx, lane) in activeLanes.enumerated() {
                if idx != column && !matchingIndices.contains(idx) {
                    passingLanes.append(LaneLine(column: idx, color: lane.color))
                }
            }

            // Record merge lines from extra matching lanes
            var mergingFrom: [MergeLine] = []
            if matchingIndices.count > 1 {
                for idx in matchingIndices.dropFirst() {
                    mergingFrom.append(MergeLine(fromColumn: idx, toColumn: column, color: activeLanes[idx].color))
                }
            }

            // Remove extra matching lanes (merge point) — remove from right to left to keep indices valid
            for idx in matchingIndices.dropFirst().reversed() {
                activeLanes.remove(at: idx)
            }

            // Now update the commit's lane with its first parent
            var branchingTo: [BranchLine] = []
            if commit.parentIDs.isEmpty {
                // Root commit — remove this lane
                activeLanes.remove(at: min(column, activeLanes.count - 1))
            } else {
                // First parent continues in this lane
                let adjustedColumn = min(column, activeLanes.count - 1)
                activeLanes[adjustedColumn].sha = commit.parentIDs[0]

                // Additional parents — find existing lane or create new one
                for parentID in commit.parentIDs.dropFirst() {
                    let existingIdx = activeLanes.firstIndex { $0.sha == parentID }
                    if let idx = existingIdx {
                        // Merge from existing lane
                        mergingFrom.append(MergeLine(fromColumn: adjustedColumn, toColumn: idx, color: activeLanes[idx].color))
                    } else {
                        // Branch out to a new lane
                        let color = nextColor()
                        let newCol = activeLanes.count
                        activeLanes.append((sha: parentID, color: color))
                        branchingTo.append(BranchLine(fromColumn: adjustedColumn, toColumn: newCol, color: color))
                    }
                }
            }

            commits[i].graphLane = GraphLane(
                column: column,
                color: nodeColor,
                passingLanes: passingLanes,
                mergingFrom: mergingFrom,
                branchingTo: branchingTo
            )
        }
    }
}
