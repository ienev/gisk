import SwiftUI
import GiskLib

struct CommitGraphView: View {
    let lane: GraphLane
    let maxColumns: Int
    let rowHeight: CGFloat = 28
    let laneWidth: CGFloat = 20
    let nodeRadius: CGFloat = 5
    let lineWidth: CGFloat = 2.5

    var totalWidth: CGFloat {
        CGFloat(max(maxColumns + 1, 3)) * laneWidth
    }

    var body: some View {
        Canvas { context, size in
            let midY = size.height / 2

            // Draw passing lanes (vertical lines)
            for passing in lane.passingLanes {
                let x = xForColumn(passing.column)
                var path = Path()
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: size.height))
                context.stroke(
                    path,
                    with: .color(passing.color),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round)
                )
            }

            // Draw the main lane's vertical line
            let nodeX = xForColumn(lane.column)
            var mainPath = Path()
            mainPath.move(to: CGPoint(x: nodeX, y: 0))
            mainPath.addLine(to: CGPoint(x: nodeX, y: size.height))
            context.stroke(
                mainPath,
                with: .color(lane.color),
                style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round)
            )

            // Draw merge lines (other branches merging into this commit)
            for merge in lane.mergingFrom {
                let fromX = xForColumn(merge.fromColumn)
                let toX = xForColumn(merge.toColumn)
                let deltaX = abs(fromX - toX)
                let curveWeight: CGFloat = min(deltaX / (laneWidth * 3), 1.0) * 0.5 + 0.3

                var path = Path()
                path.move(to: CGPoint(x: fromX, y: 0))
                path.addCurve(
                    to: CGPoint(x: toX, y: midY),
                    control1: CGPoint(x: fromX, y: midY * curveWeight),
                    control2: CGPoint(x: toX, y: midY * (1.0 - curveWeight))
                )
                context.stroke(
                    path,
                    with: .color(merge.color),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round)
                )
            }

            // Draw branch lines (this commit branching to new lanes)
            for branch in lane.branchingTo {
                let fromX = xForColumn(branch.fromColumn)
                let toX = xForColumn(branch.toColumn)
                let deltaX = abs(fromX - toX)
                let curveWeight: CGFloat = min(deltaX / (laneWidth * 3), 1.0) * 0.5 + 0.3

                var path = Path()
                path.move(to: CGPoint(x: fromX, y: midY))
                path.addCurve(
                    to: CGPoint(x: toX, y: size.height),
                    control1: CGPoint(x: fromX, y: midY + midY * curveWeight),
                    control2: CGPoint(x: toX, y: size.height - midY * curveWeight)
                )
                context.stroke(
                    path,
                    with: .color(branch.color),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round)
                )
            }

            // Draw commit node glow/shadow
            let glowRadius = nodeRadius + 3
            let glowRect = CGRect(
                x: nodeX - glowRadius,
                y: midY - glowRadius,
                width: glowRadius * 2,
                height: glowRadius * 2
            )
            context.fill(
                Circle().path(in: glowRect),
                with: .color(lane.color.opacity(0.35))
            )

            // Draw commit node (filled center)
            let nodeRect = CGRect(
                x: nodeX - nodeRadius,
                y: midY - nodeRadius,
                width: nodeRadius * 2,
                height: nodeRadius * 2
            )
            context.fill(Circle().path(in: nodeRect), with: .color(lane.color))

            // Draw white border ring
            context.stroke(
                Circle().path(in: nodeRect),
                with: .color(.white),
                lineWidth: 2
            )
        }
        .frame(width: totalWidth, height: rowHeight)
    }

    private func xForColumn(_ col: Int) -> CGFloat {
        CGFloat(col) * laneWidth + laneWidth / 2
    }
}
