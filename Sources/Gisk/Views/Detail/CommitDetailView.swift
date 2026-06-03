import SwiftUI
import GiskLib

struct CommitDetailView: View {
    let commit: Commit
    let onNavigate: (String) -> Void

    @State private var showingMessagePopover = false

    var isVirtual: Bool {
        commit.id == "__STAGED__" || commit.id == "__UNSTAGED__"
    }

    /// Whether the commit carries a body beyond its subject worth expanding.
    private var hasExpandableMessage: Bool {
        !commit.body.isEmpty && commit.body != commit.subject
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Subject
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(commit.subject)
                    .font(.system(size: 14, weight: .semibold))
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if hasExpandableMessage {
                    Button {
                        showingMessagePopover = true
                    } label: {
                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                            .font(.system(size: 11))
                    }
                    .buttonStyle(.borderless)
                    .help("Show full message")
                    .popover(isPresented: $showingMessagePopover, arrowEdge: .bottom) {
                        messagePopover
                    }
                }
            }

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

            // Full body if present
            if hasExpandableMessage {
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

    /// Floating, comfortably-sized view of the full commit message, for when the
    /// detail pane is too short to read longer bodies inline.
    private var messagePopover: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(commit.subject)
                .font(.system(size: 14, weight: .semibold))
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)

            Divider()

            ScrollView {
                Text(commit.body)
                    .font(.system(size: 12))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(14)
        .frame(width: 460, height: 360)
    }
}
