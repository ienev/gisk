import SwiftUI
import GiskLib

struct ContentView: View {
    @State var viewModel = RepositoryViewModel()

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.commits.isEmpty {
                ProgressView("Loading repository...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = viewModel.error {
                ContentUnavailableView(
                    "Error",
                    systemImage: "exclamationmark.triangle",
                    description: Text(error)
                )
            } else if viewModel.commits.isEmpty {
                ContentUnavailableView(
                    "No Repository",
                    systemImage: "folder.badge.questionmark",
                    description: Text("Open a git repository to get started")
                )
            } else {
                mainContent
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                SearchBar(text: $viewModel.searchText)
                    .frame(width: 250)
            }
        }
        .navigationTitle(viewModel.repoName.isEmpty ? "Gisk" : viewModel.repoName)
        .task {
            await openInitialRepo()
        }
    }

    @ViewBuilder
    var mainContent: some View {
        GeometryReader { geo in
            let rightColumnWidth: CGFloat = 300
            VSplitView {
                // Top row: commit list + commit detail
                HStack(spacing: 0) {
                    CommitListView(viewModel: viewModel)
                        .frame(maxWidth: .infinity)

                    Divider()

                    if let commit = viewModel.selectedCommit {
                        let isVirtual = commit.id == stagedChangesID || commit.id == unstagedChangesID
                        if isVirtual {
                            CommitDetailView(commit: commit) { sha in
                                Task { await viewModel.navigateToCommit(sha: sha) }
                            }
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(width: rightColumnWidth, alignment: .topLeading)
                        } else {
                            ScrollView {
                                CommitDetailView(commit: commit) { sha in
                                    Task { await viewModel.navigateToCommit(sha: sha) }
                                }
                            }
                            .frame(width: rightColumnWidth)
                        }
                    }
                }
                .frame(minHeight: 100, maxHeight: geo.size.height * 0.25)

                // Bottom row: diff view + file list
                HStack(spacing: 0) {
                    DiffView(fileDiff: viewModel.selectedFileDiff)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                    Divider()

                    if let diff = viewModel.diff {
                        FileListView(
                            files: diff.files,
                            selectedFile: Binding(
                                get: { viewModel.selectedFileDiff },
                                set: { file in
                                    if let f = file { viewModel.selectFile(f) }
                                }
                            )
                        )
                        .frame(width: rightColumnWidth)
                    }
                }
                .frame(minHeight: 250)
            }
        }
    }

    private func openInitialRepo() async {
        // Check command line arguments first
        let args = CommandLine.arguments
        if args.count > 1 {
            let path = args[1]
            await viewModel.loadRepository(path: path)
            return
        }

        // Try current working directory
        let cwd = FileManager.default.currentDirectoryPath
        await viewModel.loadRepository(path: cwd)
    }
}
