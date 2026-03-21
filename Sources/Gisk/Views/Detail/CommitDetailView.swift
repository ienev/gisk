import SwiftUI
import GiskLib

struct CommitDetailView: View {
    let commit: Commit
    let onNavigate: (String) -> Void

    var isVirtual: Bool {
        commit.id == "__STAGED__" || commit.id == "__UNSTAGED__"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Subject
            Text(commit.subject)
                .font(.system(size: 14, weight: .semibold))
                .lineLimit(2)

            if !isVirtual {
                Divider()

                Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 4) {
                    GridRow {
                        Text("SHA")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        HStack {
                            SHALabel(commit.id, short: false)
                        }
                    }
                    GridRow {
                        Text("Author")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("\(commit.author) <\(commit.authorEmail)>")
                            .font(.system(size: 12))
                    }
                    GridRow {
                        Text("Date")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(DateFormatting.absolute(commit.authorDate))
                            .font(.system(size: 12))
                    }
                    if !commit.parentIDs.isEmpty {
                        GridRow {
                            Text(commit.parentIDs.count > 1 ? "Parents" : "Parent")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            HStack(spacing: 6) {
                                ForEach(commit.parentIDs, id: \.self) { parentID in
                                    Button(action: { onNavigate(parentID) }) {
                                        Text(String(parentID.prefix(8)))
                                            .font(.system(.caption, design: .monospaced))
                                    }
                                    .buttonStyle(.link)
                                }
                            }
                        }
                    }
                    if !commit.childIDs.isEmpty {
                        GridRow {
                            Text(commit.childIDs.count > 1 ? "Children" : "Child")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            HStack(spacing: 6) {
                                ForEach(commit.childIDs, id: \.self) { childID in
                                    Button(action: { onNavigate(childID) }) {
                                        Text(String(childID.prefix(8)))
                                            .font(.system(.caption, design: .monospaced))
                                    }
                                    .buttonStyle(.link)
                                }
                            }
                        }
                    }
                }
            }

            // Refs
            if !commit.refs.isEmpty {
                HStack(spacing: 4) {
                    ForEach(commit.refs) { ref in
                        RefBadge(ref: ref)
                    }
                }
            }

            // Full body if present
            if !commit.body.isEmpty && commit.body != commit.subject {
                Divider()
                ScrollView {
                    Text(commit.body)
                        .font(.system(size: 12))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding(12)
    }
}
