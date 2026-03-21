import SwiftUI

struct SHALabel: View {
    let sha: String
    let short: Bool

    init(_ sha: String, short: Bool = true) {
        self.sha = sha
        self.short = short
    }

    var displayText: String {
        short ? String(sha.prefix(8)) : sha
    }

    var body: some View {
        Text(displayText)
            .font(.system(.caption, design: .monospaced))
            .foregroundStyle(.secondary)
            .onTapGesture {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(sha, forType: .string)
            }
            .help("Click to copy full SHA")
    }
}
