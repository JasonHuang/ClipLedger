import AppKit
import SwiftUI

struct MainView: View {
    @ObservedObject var viewModel: ClipboardViewModel
    @ObservedObject var settings: AppSettings

    let onOpenSettings: () -> Void

    @State private var isShowingClearConfirmation = false
    @State private var recentlyRestoredItemID: UUID?

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 20) {
                    if !viewModel.pinnedItems.isEmpty {
                        itemSection(
                            title: "Pinned",
                            systemImage: "pin.fill",
                            items: viewModel.pinnedItems,
                            isPinnedSection: true
                        )
                    }

                    itemSection(
                        title: "History",
                        systemImage: "clock.arrow.circlepath",
                        items: viewModel.historyItems,
                        isPinnedSection: false
                    )

                    if viewModel.allDisplayItems.isEmpty {
                        EmptyStateView()
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 18)
            }
            .scrollIndicators(.hidden)
            .background(Color(nsColor: .textBackgroundColor).opacity(0.42))

            if let errorMessage = viewModel.errorMessage {
                ErrorBanner(message: errorMessage)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 10)
            }

            footer
        }
        .frame(width: 468, height: 640)
        .background(Color(nsColor: .windowBackgroundColor))
        .onAppear {
            viewModel.reload()
        }
        .confirmationDialog(
            "Clear history?",
            isPresented: $isShowingClearConfirmation,
            titleVisibility: .visible
        ) {
            Button("Clear History", role: .destructive) {
                viewModel.clearHistory()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Pinned items will remain available.")
        }
    }

    private var header: some View {
        VStack(spacing: 14) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color.accentColor.opacity(0.16))

                    Image(systemName: "clipboard")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Color.accentColor)
                }
                .frame(width: 34, height: 34)

                VStack(alignment: .leading, spacing: 2) {
                    Text("ClipLedger")
                        .font(.title3.weight(.semibold))

                    Text("Local clipboard history")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                ToolbarIconButton(
                    systemImage: "magnifyingglass",
                    help: "Search",
                    isDisabled: true,
                    action: {}
                )

                ToolbarIconButton(
                    systemImage: "gearshape",
                    help: "Settings",
                    action: onOpenSettings
                )
            }

            HStack(spacing: 8) {
                StatPill(
                    title: "Pinned",
                    value: "\(viewModel.pinnedItems.count)",
                    systemImage: "pin.fill"
                )

                StatPill(
                    title: "History",
                    value: "\(viewModel.historyItems.count)",
                    systemImage: "clock"
                )

                Spacer(minLength: 0)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 14)
        .background(.regularMaterial)
    }

    private var footer: some View {
        HStack(spacing: 10) {
            HStack(spacing: 7) {
                Image(systemName: recentlyRestoredItemID == nil ? "lock.shield" : "checkmark.circle.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(recentlyRestoredItemID == nil ? .secondary : Color.green)

                Text(recentlyRestoredItemID == nil ? "Stored locally" : "Restored to clipboard")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                isShowingClearConfirmation = true
            } label: {
                Label("Clear History", systemImage: "trash")
            }
            .disabled(viewModel.historyItems.isEmpty)

            Button(action: onOpenSettings) {
                Label("Settings", systemImage: "gearshape")
            }

            Button {
                NSApp.terminate(nil)
            } label: {
                Label("Quit", systemImage: "power")
            }
            .help("Quit ClipLedger")
        }
        .buttonStyle(.bordered)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.regularMaterial)
    }

    private func itemSection(
        title: String,
        systemImage: String,
        items: [ClipboardItem],
        isPinnedSection: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(isPinnedSection ? Color.accentColor : .secondary)

                Text(title)
                    .font(.subheadline.weight(.semibold))

                Spacer()

                Text("\(items.count)")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(minWidth: 20)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Color(nsColor: .controlBackgroundColor))
                    .clipShape(Capsule())
            }

            if items.isEmpty {
                Text("No clipboard text yet")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 12)
            } else {
                ForEach(items) { item in
                    HistoryRowView(
                        item: item,
                        isSelected: item.id == viewModel.selectedItemID,
                        isPinnedSection: isPinnedSection,
                        isRecentlyRestored: item.id == recentlyRestoredItemID,
                        onRestore: {
                            restore(item)
                        },
                        onPinToggle: {
                            if item.isPinned {
                                viewModel.unpin(item)
                            } else {
                                viewModel.pin(item)
                            }
                        },
                        onDelete: {
                            viewModel.delete(item)
                        }
                    )
                    .onTapGesture {
                        restore(item)
                    }
                }
            }
        }
    }

    private func restore(_ item: ClipboardItem) {
        viewModel.restore(item)
        recentlyRestoredItemID = item.id

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            if recentlyRestoredItemID == item.id {
                recentlyRestoredItemID = nil
            }
        }
    }
}

private struct StatPill: View {
    let title: String
    let value: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)

            Text(title)
                .foregroundStyle(.secondary)

            Text(value)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
        }
        .font(.caption)
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.8))
        .clipShape(Capsule())
    }
}

private struct ToolbarIconButton: View {
    let systemImage: String
    let help: String
    var isDisabled = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 14, weight: .semibold))
                .frame(width: 28, height: 28)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(isDisabled ? .tertiary : .secondary)
        .background(Color(nsColor: .controlBackgroundColor).opacity(isDisabled ? 0.38 : 0.75))
        .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .strokeBorder(Color.secondary.opacity(0.12))
        }
        .disabled(isDisabled)
        .help(help)
    }
}

private struct ErrorBanner: View {
    let message: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
            Text(message)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .font(.caption)
        .padding(10)
        .background(Color.red.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}
