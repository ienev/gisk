import SwiftUI
import GiskLib

struct FileListView: View {
    let files: [FileDiff]
    @Binding var selectedFile: FileDiff?
    @FocusState private var isFocused: Bool
    // A row click targets an already-visible row, so suppress the auto-scroll
    // for that id (see CommitListView for the same pattern).
    @State private var suppressScrollForID: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("Files")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(files.count)")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 1)
                    .background(.quaternary)
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)

            Divider()

            // ScrollView + LazyVStack rather than List: avoids the NSTableView
            // delegate the SwiftUI List is built on, whose reentrancy warning
            // fired when files + selection changed together. The view model
            // keeps `selectedFile` valid (it selects the first file on diff load).
            // Arrow keys navigate when this pane has focus; clicking it (or a
            // row) gives it focus, independent of the commit list.
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(files) { file in
                            selectableRow(file)
                        }
                    }
                }
                .focusable()
                .focused($isFocused)
                .onMoveCommand { direction in
                    switch direction {
                    case .up: moveSelection(by: -1)
                    case .down: moveSelection(by: 1)
                    default: break
                    }
                }
                .onChange(of: selectedFile?.id) { _, newID in
                    guard let newID else { return }
                    if newID == suppressScrollForID {
                        suppressScrollForID = nil
                        return
                    }
                    withAnimation(.easeInOut(duration: 0.15)) {
                        proxy.scrollTo(newID)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func selectableRow(_ file: FileDiff) -> some View {
        fileRow(file)
            .background(file.id == selectedFile?.id ? Theme.selectedBackground : Color.clear)
            .contentShape(Rectangle())
            .onTapGesture {
                isFocused = true
                suppressScrollForID = file.id
                selectedFile = file
            }
            .id(file.id)
    }

    private func moveSelection(by delta: Int) {
        guard !files.isEmpty else { return }
        let current = files.firstIndex { $0.id == selectedFile?.id } ?? 0
        let next = min(max(current + delta, 0), files.count - 1)
        guard next != current else { return }
        selectedFile = files[next]
    }

    @ViewBuilder
    private func fileRow(_ file: FileDiff) -> some View {
        HStack(spacing: 6) {
            Text(file.status.label)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(Theme.fileStatusColor(file.status))
                .frame(width: 16)

            VStack(alignment: .leading, spacing: 1) {
                Text(fileName(from: file.newPath))
                    .font(.system(size: 12, weight: .medium))
                    .lineLimit(1)
                    .truncationMode(.middle)

                let dir = directoryPath(from: file.newPath)
                if !dir.isEmpty {
                    Text(dir)
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.head)
                }
            }

            Spacer(minLength: 0)
        }
        .help(file.newPath)
        .padding(EdgeInsets(top: 3, leading: 8, bottom: 3, trailing: 8))
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func fileName(from path: String) -> String {
        (path as NSString).lastPathComponent
    }

    private func directoryPath(from path: String) -> String {
        let dir = (path as NSString).deletingLastPathComponent
        return dir == "." ? "" : dir
    }
}
