import SwiftUI

struct HistoryRowView: View {
    let item: ClipboardItem
    let isSelected: Bool
    let isPinnedSection: Bool
    let onRestore: () -> Void
    let onPinToggle: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 6) {
                Text(previewText)
                    .font(.callout)
                    .lineLimit(2)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 8) {
                    if isPinnedSection {
                        Label("\(item.usageCount)", systemImage: "arrow.uturn.backward")
                    } else {
                        Text(relativeCreatedAt)
                        Text("\(item.characterCount) chars")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            HStack(spacing: 8) {
                Button(action: onRestore) {
                    Image(systemName: "doc.on.clipboard")
                }
                .help("Restore")

                Button(action: onPinToggle) {
                    Image(systemName: item.isPinned ? "pin.slash" : "pin")
                }
                .help(item.isPinned ? "Unpin" : "Pin")

                Button(role: .destructive, action: onDelete) {
                    Image(systemName: "trash")
                }
                .help("Delete")
            }
            .buttonStyle(.borderless)
            .font(.system(size: 13, weight: .medium))
        }
        .padding(10)
        .background(backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(isSelected ? Color.accentColor.opacity(0.5) : Color.secondary.opacity(0.12))
        }
        .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var previewText: String {
        let collapsed = item.content
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\t", with: " ")
        return collapsed.isEmpty ? " " : collapsed
    }

    private var backgroundColor: Color {
        if isSelected {
            return Color.accentColor.opacity(0.14)
        }
        return Color(nsColor: .controlBackgroundColor)
    }

    private var relativeCreatedAt: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: item.createdAt, relativeTo: Date())
    }
}
