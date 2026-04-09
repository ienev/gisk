import SwiftUI
import GiskLib

struct FileListView: View {
    let files: [FileDiff]
    @Binding var selectedFile: FileDiff?

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

            List(selection: Binding(
                get: { selectedFile?.id },
                set: { newID in
                    selectedFile = files.first { $0.id == newID }
                }
            )) {
                ForEach(files) { file in
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
                    }
                    .help(file.newPath)
                    .tag(file.id)
                    .listRowInsets(EdgeInsets(top: 3, leading: 8, bottom: 3, trailing: 8))
                }
            }
            .listStyle(.plain)
            .onChange(of: files.map(\.id)) { _, newIDs in
                if let currentID = selectedFile?.id, newIDs.contains(currentID) {
                    return
                }
                if let first = files.first {
                    selectedFile = first
                }
            }
        }
    }

    private func fileName(from path: String) -> String {
        (path as NSString).lastPathComponent
    }

    private func directoryPath(from path: String) -> String {
        let dir = (path as NSString).deletingLastPathComponent
        return dir == "." ? "" : dir
    }
}
