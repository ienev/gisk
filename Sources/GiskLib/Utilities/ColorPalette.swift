import SwiftUI

public enum Theme {
    // Background colors
    public static let background = Color(nsColor: .windowBackgroundColor)
    public static let secondaryBackground = Color(nsColor: .controlBackgroundColor)
    public static let selectedBackground = Color.accentColor.opacity(0.2)
    public static let hoverBackground = Color.primary.opacity(0.05)

    // Diff colors
    public static let addedBackground = Color.green.opacity(0.15)
    public static let addedText = Color.green
    public static let deletedBackground = Color.red.opacity(0.15)
    public static let deletedText = Color.red
    public static let contextText = Color.secondary
    public static let hunkHeaderBackground = Color.blue.opacity(0.1)
    public static let hunkHeaderText = Color.blue

    // File status colors
    public static func fileStatusColor(_ status: FileStatus) -> Color {
        switch status {
        case .added: return .green
        case .modified: return .yellow
        case .deleted: return .red
        case .renamed: return .blue
        case .copied: return .cyan
        case .unknown: return .secondary
        }
    }

    // Text
    public static let primaryText = Color.primary
    public static let secondaryText = Color.secondary
    public static let monoFont = Font.system(.body, design: .monospaced)
    public static let smallMonoFont = Font.system(.caption, design: .monospaced)
}
