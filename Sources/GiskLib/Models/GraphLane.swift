import SwiftUI

public struct GraphLane {
    public let column: Int
    public let color: Color
    public let passingLanes: [LaneLine]
    public let mergingFrom: [MergeLine]
    public let branchingTo: [BranchLine]

    public init(column: Int, color: Color, passingLanes: [LaneLine], mergingFrom: [MergeLine], branchingTo: [BranchLine]) {
        self.column = column
        self.color = color
        self.passingLanes = passingLanes
        self.mergingFrom = mergingFrom
        self.branchingTo = branchingTo
    }
}

public struct LaneLine: Hashable {
    public let column: Int
    public let color: Color

    public init(column: Int, color: Color) {
        self.column = column
        self.color = color
    }
}

public struct MergeLine: Hashable {
    public let fromColumn: Int
    public let toColumn: Int
    public let color: Color

    public init(fromColumn: Int, toColumn: Int, color: Color) {
        self.fromColumn = fromColumn
        self.toColumn = toColumn
        self.color = color
    }
}

public struct BranchLine: Hashable {
    public let fromColumn: Int
    public let toColumn: Int
    public let color: Color

    public init(fromColumn: Int, toColumn: Int, color: Color) {
        self.fromColumn = fromColumn
        self.toColumn = toColumn
        self.color = color
    }
}
