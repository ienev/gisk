import SwiftUI
import GiskLib

struct CommitListView: View {
    @Bindable var viewModel: RepositoryViewModel
    @FocusState private var isFocused: Bool
    // A row click targets an already-visible row, so suppress the auto-scroll
    // for that id — otherwise selecting a visible commit yanks the list around.
    @State private var suppressScrollForID: String? = nil

    var maxGraphColumns: Int {
        viewModel.filteredCommits.compactMap { $0.graphLane?.column }.max() ?? 0
    }

    var body: some View {
        // Rendered with ScrollView + LazyVStack rather than List: List is backed
        // by NSTableView, whose delegate emits a reentrant-operation warning when
        // its data/selection are mutated during an update (which happens as the
        // commit array loads and re-lays out at launch). A plain stack has no
        // such delegate.
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(viewModel.filteredCommits) { commit in
                        CommitRowView(commit: commit, maxGraphColumns: maxGraphColumns)
                            .background(
                                commit.id == viewModel.selectedCommit?.id
                                    ? Theme.selectedBackground
                                    : Color.clear
                            )
                            .onTapGesture {
                                isFocused = true
                                suppressScrollForID = commit.id
                                Task { await viewModel.selectCommit(commit) }
                            }
                            .id(commit.id)
                    }

                    // Load-more trigger: fires as it scrolls into view near the
                    // bottom. loadMore() guards against concurrent runs itself.
                    Color.clear
                        .frame(height: 1)
                        .onAppear {
                            Task { await viewModel.loadMore() }
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
            .onAppear {
                DispatchQueue.main.async { isFocused = true }
            }
            .onChange(of: viewModel.selectedCommit?.id) { _, newID in
                guard let newID else { return }
                if newID == suppressScrollForID {
                    suppressScrollForID = nil
                    return
                }
                // Keyboard navigation / programmatic navigation (parent/child
                // links): bring the newly selected commit into view.
                withAnimation(.easeInOut(duration: 0.15)) {
                    proxy.scrollTo(newID)
                }
            }
        }
    }

    private func moveSelection(by delta: Int) {
        let commits = viewModel.filteredCommits
        guard !commits.isEmpty else { return }
        let current = commits.firstIndex { $0.id == viewModel.selectedCommit?.id } ?? 0
        let next = min(max(current + delta, 0), commits.count - 1)
        guard next != current else { return }
        Task { await viewModel.selectCommit(commits[next]) }
    }
}
