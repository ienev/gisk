# Gisk

A modern SwiftUI reimplementation of gitk - the Git graphical history viewer.

## Build & Run

```bash
make build                    # debug build
make run                      # debug build + launch on current dir
make run REPO=/path/to/repo   # debug build + launch on specific repo
make test                     # run all tests
make install                  # release build + install to ~/.local/bin
make clean                    # clean build artifacts
```

Requires Swift 5.10+ and macOS 14+. No external dependencies.

## Architecture

- **SwiftUI app** built with Swift Package Manager (`swift build`, no Xcode required)
- **Git interaction**: shells out to `/usr/bin/git` with NUL-delimited (`%x00`) format parsing - no libgit2 dependency
- **`@Observable` MVVM**: `RepositoryViewModel` holds all state, views bind reactively
- **`GitCLI` actor**: all git commands run through this actor for thread safety
- **Graph layout**: custom DAG lane assignment algorithm in `GraphLayoutEngine` renders the commit topology via SwiftUI `Canvas`

## Project Structure

```
Sources/
  GiskLib/           -> Library target (imported by app and tests)
    Models/           -> Commit, Diff, Ref, GraphLane
    Services/         -> GitCLI, GitLogParser, GitDiffParser, GraphLayoutEngine
    Utilities/        -> ColorPalette, DateFormatting
  Gisk/              -> Executable target (depends on GiskLib)
    App/              -> GiskApp.swift (entry point), ContentView.swift (main layout)
    ViewModels/       -> RepositoryViewModel
    Views/
      CommitList/     -> Scrollable commit table with graph column
      Detail/         -> CommitDetailView, DiffView, FileListView
      Graph/          -> Canvas-based DAG rendering
      Search/         -> SearchBar
      Shared/         -> RefBadge, SHALabel
Tests/GiskTests/     -> 81 unit tests covering parsers, graph layout, and models
```

## Key Implementation Notes

- The `GitCLI.run()` method reads all pipe data BEFORE calling `waitUntilExit()` to avoid deadlocking on large outputs.
- Git log uses `%x1e` (record separator) between commits and `%x00` between fields for reliable parsing.
- Graph layout is O(n * k) where k is max simultaneous branches. Layout is recomputed when loading more commits.
- Commits load in pages of 500. Scrolling to the bottom triggers `loadMore()`.
- The app registers as a regular GUI process via `NSApplication.setActivationPolicy(.regular)` in the AppDelegate — required for SPM-built SwiftUI apps to show windows.
- The commit list and file list are built with `ScrollView` + `LazyVStack`, **not** SwiftUI `List`. `List` is backed by `NSTableView`, whose delegate emits a "reentrant operation in its NSTableView delegate" warning at launch when the data and selection change together. The stacks derive selection from the view model with manual highlighting (`Theme.selectedBackground`) and click-to-select; each pane is independently focusable with arrow-key navigation via `onMoveCommand`.
- `make install` builds a `Gisk.app` bundle (with `Resources/Info.plist`) and symlinks `gisk` into it, so the process has a real bundle identifier even when launched via the symlink — without it AppKit's launch subsystems (intents, window tabbing) log "missing main bundle identifier" errors.
- Diffs use `--text` flag to always show text content.
- Merge commits diff against first parent (`git diff SHA~1 SHA`). Root commits use `--root`.
- Virtual "Staged changes" and "Unstaged changes" entries appear at the top when working tree has modifications (`git status --porcelain` to detect, `git diff --cached` / `git diff` for content).
- Diff view supports unified and side-by-side modes. Side-by-side pairs consecutive deletions/additions.
