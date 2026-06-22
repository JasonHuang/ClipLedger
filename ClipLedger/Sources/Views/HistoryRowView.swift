import SwiftUI

struct HistoryRowView: View {
    let item: ClipboardItem
    let isSelected: Bool
    let isPinnedSection: Bool
    let isRecentlyRestored: Bool
    let onRestore: () -> Void
    let onPinToggle: () -> Void
    let onDelete: () -> Void
    var onEditTag: (() -> Void)?

    @State private var isHovered = false

    var body: some View {
        HStack(alignment: .top, spacing: 11) {
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(leadingAccentColor)
                .frame(width: 3)
                .padding(.vertical, 3)

            VStack(alignment: .leading, spacing: 6) {
                Text(previewText)
                    .font(.callout.weight(.medium))
                    .lineLimit(2)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 8) {
                    if isPinnedSection {
                        if let tagName = item.normalizedTagName {
                            MetadataPill(systemImage: "tag", text: tagName)
                        }
                        MetadataPill(systemImage: "arrow.uturn.backward", text: "\(item.usageCount) uses")
                        MetadataPill(systemImage: "character.cursor.ibeam", text: "\(item.characterCount) chars")
                    } else {
                        MetadataPill(systemImage: "clock", text: relativeCreatedAt)
                        MetadataPill(systemImage: "character.cursor.ibeam", text: "\(item.characterCount) chars")
                    }
                }
            }

            HStack(spacing: 8) {
                RowIconButton(
                    systemImage: isRecentlyRestored ? "checkmark" : "doc.on.clipboard",
                    help: "Restore",
                    tint: isRecentlyRestored ? .green : .accentColor,
                    action: onRestore
                )

                RowIconButton(
                    systemImage: item.isPinned ? "pin.slash" : "pin",
                    help: item.isPinned ? "Unpin" : "Pin",
                    action: onPinToggle
                )

                if let onEditTag {
                    RowIconButton(
                        systemImage: "tag",
                        help: item.normalizedTagName == nil ? "Set Tag" : "Edit Tag",
                        action: onEditTag
                    )
                }

                RowIconButton(
                    systemImage: "trash",
                    help: "Delete",
                    tint: .red,
                    action: onDelete
                )
            }
            .opacity(isHovered || isSelected ? 1 : 0.78)
        }
        .padding(11)
        .background(backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(borderColor)
        }
        .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .shadow(color: shadowColor, radius: isHovered ? 4 : 0, y: isHovered ? 2 : 0)
        .onHover { isHovered = $0 }
    }

    private var previewText: String {
        let collapsed = item.content
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\t", with: " ")
        return collapsed.isEmpty ? " " : collapsed
    }

    private var backgroundColor: Color {
        if isSelected {
            return Color.accentColor.opacity(0.12)
        }
        if isHovered {
            return Color(nsColor: .controlBackgroundColor)
        }
        return Color(nsColor: .windowBackgroundColor)
    }

    private var borderColor: Color {
        if isSelected {
            return Color.accentColor.opacity(0.55)
        }
        if isHovered {
            return Color.secondary.opacity(0.18)
        }
        return Color.secondary.opacity(0.10)
    }

    private var leadingAccentColor: Color {
        if isRecentlyRestored {
            return .green
        }
        if item.isPinned {
            return .accentColor
        }
        return .secondary.opacity(0.28)
    }

    private var shadowColor: Color {
        Color.black.opacity(0.08)
    }

    private var relativeCreatedAt: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: item.createdAt, relativeTo: Date())
    }
}

private struct MetadataPill: View {
    let systemImage: String
    let text: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: systemImage)
                .font(.system(size: 10, weight: .semibold))
            Text(text)
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.75))
        .clipShape(Capsule())
    }
}

private struct RowIconButton: View {
    let systemImage: String
    let help: String
    var tint: Color = .secondary
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 12, weight: .semibold))
                .frame(width: 26, height: 26)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(tint)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.8))
        .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .strokeBorder(Color.secondary.opacity(0.12))
        }
        .help(help)
    }
}
