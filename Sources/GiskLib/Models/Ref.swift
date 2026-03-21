import SwiftUI

public enum Ref: Hashable, Identifiable {
    case localBranch(name: String, isCurrent: Bool)
    case remoteBranch(name: String)
    case tag(name: String)
    case head

    public var id: String {
        switch self {
        case .localBranch(let name, _): return "local/\(name)"
        case .remoteBranch(let name): return "remote/\(name)"
        case .tag(let name): return "tag/\(name)"
        case .head: return "HEAD"
        }
    }

    public var displayName: String {
        switch self {
        case .localBranch(let name, _): return name
        case .remoteBranch(let name): return name
        case .tag(let name): return name
        case .head: return "HEAD"
        }
    }

    public var color: Color {
        switch self {
        case .localBranch(_, let isCurrent):
            return isCurrent ? .green : .blue
        case .remoteBranch: return .orange
        case .tag: return .yellow
        case .head: return .cyan
        }
    }

    public var icon: String {
        switch self {
        case .localBranch: return "arrow.triangle.branch"
        case .remoteBranch: return "cloud"
        case .tag: return "tag"
        case .head: return "arrow.right.circle"
        }
    }
}
