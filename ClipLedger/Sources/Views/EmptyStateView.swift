import SwiftUI

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color(nsColor: .controlBackgroundColor))

                Image(systemName: "clipboard")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            .frame(width: 58, height: 58)
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(Color.secondary.opacity(0.12))
            }

            Text("No clipboard text yet")
                .font(.callout.weight(.semibold))

            Text("Only plain text is stored locally.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}
