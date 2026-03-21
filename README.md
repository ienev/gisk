# Gisk

A modern, native macOS replacement for [gitk](https://git-scm.com/docs/gitk) - built with SwiftUI.

![macOS](https://img.shields.io/badge/macOS-14%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.10%2B-orange)
![License](https://img.shields.io/badge/license-MIT-green)

## Features

- **Commit graph** - visual DAG with colored branch lines, merge curves, and glow effects
- **Branch & tag badges** - colored pills for HEAD, local branches, remotes, and tags
- **Diff viewer** - unified and side-by-side diff modes with syntax coloring, togglable from the toolbar
- **Staged & unstaged changes** - view working tree and index diffs at the top of the commit list, just like gitk
- **File list** - changed files with status indicators (A/M/D/R) and directory grouping
- **Commit detail** - SHA, author, date, clickable parent/child navigation
- **Merge commit diffs** - shows diff against first parent for merge commits
- **Search** - filter commits by message, author, or SHA
- **Keyboard navigation** - arrow keys to browse commits
- **Lazy loading** - handles large repositories by loading commits in batches
- **Dark theme** by default, with light theme support via system preferences

## Install

### From source

Requires Swift 5.10+ (ships with Xcode 15.4+).

```bash
git clone https://github.com/your-username/gisk.git
cd gisk
make install
```

This builds a release binary and copies it to `~/.local/bin/gisk`.

### Uninstall

```bash
make uninstall
```

## Usage

```bash
gisk                      # open current directory's repo
gisk /path/to/repo        # open a specific repository
```

## Development

```bash
make build                         # debug build
make run                           # build + launch (current dir)
make run REPO=/path/to/repo        # build + launch on specific repo
make test                          # run all 81 tests
make clean                         # clean build artifacts
```

No Xcode project needed - everything builds with Swift Package Manager via the command line.

## Testing

```bash
make test
```

81 unit tests covering:
- **GitLogParser** - commit parsing, refs, dates, parent/child relationships
- **GitDiffParser** - unified diff parsing, file statuses, hunks, line numbers
- **GraphLayoutEngine** - DAG lane assignment, branching, merging, colors
- **Models** - Ref properties, Commit equality/hashing, FileDiff, FileStatus

## How It Works

Gisk shells out to the system `git` CLI for all data (log, diff, branches, tags) and parses the structured output. The commit graph topology is computed by a custom lane assignment algorithm and rendered using SwiftUI's GPU-accelerated `Canvas`.

### Architecture

```
+-------------+     +--------------+     +------------------+
|   SwiftUI   |---->|  ViewModel   |---->|     GitCLI       |
|   Views     |<----|  @Observable |<----|   (git Process)  |
+-------------+     +--------------+     +------------------+
                           |
                    +------+------+
                    |   Parsers   |
                    | Log / Diff  |
                    | GraphLayout |
                    +-------------+
```

- **Zero dependencies** - only Swift standard library, Foundation, and SwiftUI
- **Single binary** - no runtime, no Electron, no web views
- **Native performance** - GPU-accelerated rendering, virtualized scrolling

## License

MIT
