import SwiftUI
import GiskLib

struct CommitListView: View {
    @Bindable var viewModel: RepositoryViewModel
    @FocusState private var isListFocused: Bool
    @State private var selectedID: String? = nil

    var maxGraphColumns: Int {
        viewModel.filteredCommits.compactMap { $0.graphLane?.column }.max() ?? 0
    }

    var body: some View {
        ScrollViewReader { proxy in
            List(selection: $selectedID) {
                ForEach(viewModel.filteredCommits) { commit in
                    CommitRowView(
                        commit: commit,
                        maxGraphColumns: maxGraphColumns
                    )
                    .id(commit.id)
                    .tag(commit.id)
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
                }

                // Load more trigger
                if !viewModel.isLoading {
                    Color.clear
                        .frame(height: 1)
                        .onAppear {
                            Task { await viewModel.loadMore() }
                        }
                }
            }
            .listStyle(.plain)
            .focused($isListFocused)
            .onAppear {
                isListFocused = true
                selectedID = viewModel.selectedCommit?.id
            }
            .onChange(of: selectedID) { _, newID in
                guard let id = newID,
                      id != viewModel.selectedCommit?.id,
                      let commit = viewModel.filteredCommits.first(where: { $0.id == id })
                else { return }
                DispatchQueue.main.async {
                    Task { await viewModel.selectCommit(commit) }
                }
            }
            .onChange(of: viewModel.selectedCommit?.id) { _, newID in
                if let id = newID, id != selectedID {
                    selectedID = id
                    withAnimation(.easeInOut(duration: 0.2)) {
                        proxy.scrollTo(id, anchor: .center)
                    }
                }
            }
        }
    }
}
