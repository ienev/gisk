import SwiftUI
import GiskLib

struct CommitRowView: View {
    let commit: Commit
    let maxGraphColumns: Int

    var isVirtual: Bool {
        commit.id == "__STAGED__" || commit.id == "__UNSTAGED__"
    }

    var body: some View {
        HStack(spacing: 0) {
            if isVirtual {
                // Virtual entry icon
                Image(systemName: commit.id == "__STAGED__" ? "tray.and.arrow.down" : "pencil.circle")
                    .font(.system(size: 14))
                    .foregroundStyle(commit.id == "__STAGED__" ? .green : .orange)
                    .frame(width: 28)
            } else {
                // Graph
                if let lane = commit.graphLane {
                    CommitGraphView(lane: lane, maxColumns: maxGraphColumns)
                }
            }

            // Ref badges
            if !commit.refs.isEmpty {
                HStack(spacing: 4) {
                    ForEach(commit.refs) { ref in
                        RefBadge(ref: ref)
                    }
                }
                .padding(.trailing, 6)
            }

            // Subject
            Text(commit.subject)
                .lineLimit(1)
                .font(.system(size: 13, weight: isVirtual ? .semibold : .regular))
                .foregroundStyle(isVirtual ? (commit.id == "__STAGED__" ? Color.green : Color.orange) : Theme.primaryText)

            Spacer(minLength: 8)

            if !isVirtual {
                // Author
                Text(commit.author)
                    .lineLimit(1)
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.secondaryText)
                    .frame(width: 160, alignment: .trailing)

                // Date
                Text(DateFormatting.relative(commit.authorDate))
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.secondaryText)
                    .frame(width: 80, alignment: .trailing)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 2)
        .frame(height: 30)
        .background(Color.clear)
        .contentShape(Rectangle())
    }
}
