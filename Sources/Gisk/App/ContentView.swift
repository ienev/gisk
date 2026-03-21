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
        VSplitView {
            // Top: commit list
            CommitListView(viewModel: viewModel)
                .frame(minHeight: 200)

            // Bottom: detail + diff
            HSplitView {
                // Left: file list + commit detail
                VStack(spacing: 0) {
                    if let commit = viewModel.selectedCommit {
                        ScrollView {
                            CommitDetailView(commit: commit) { sha in
                                Task { await viewModel.navigateToCommit(sha: sha) }
                            }
                        }
                        .frame(maxHeight: 200)

                        Divider()
                    }

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
                    }
                }
                .frame(minWidth: 200, idealWidth: 300, maxWidth: 500)

                // Right: diff view
                DiffView(fileDiff: viewModel.selectedFileDiff)
                    .frame(minWidth: 300, maxHeight: .infinity)
            }
            .frame(minHeight: 250, idealHeight: 350)
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
