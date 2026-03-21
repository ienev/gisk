import SwiftUI
import GiskLib

struct RefBadge: View {
    let ref: Ref

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: ref.icon)
                .font(.system(size: 9))
            Text(ref.displayName)
                .font(.system(size: 11, weight: .medium))
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(ref.color.opacity(0.2))
        .foregroundStyle(ref.color)
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .strokeBorder(ref.color.opacity(0.4), lineWidth: 0.5)
        )
    }
}
