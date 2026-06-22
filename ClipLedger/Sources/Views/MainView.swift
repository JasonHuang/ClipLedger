import AppKit
import SwiftUI

struct MainView: View {
    @ObservedObject var viewModel: ClipboardViewModel
    @ObservedObject var settings: AppSettings

    let onOpenSettings: () -> Void

    @State private var isShowingClearConfirmation = false
    @State private var recentlyRestoredItemID: UUID?
    @State private var isSearchPresented = false
    @FocusState private var isSearchFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            header

            if let shortcutWarningMessage = viewModel.shortcutWarningMessage {
                WarningBanner(message: shortcutWarningMessage)
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .background(Color(nsColor: .textBackgroundColor).opacity(0.42))
            }

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 20) {
                    if !viewModel.filteredPinnedItems.isEmpty {
                        itemSection(
                            title: "Pinned",
                            systemImage: "pin.fill",
                            items: viewModel.filteredPinnedItems,
                            isPinnedSection: true,
                            emptyMessage: nil
                        )
                    }

                    if !viewModel.isSearching || !viewModel.filteredHistoryItems.isEmpty {
                        itemSection(
                            title: "History",
                            systemImage: "clock.arrow.circlepath",
                            items: viewModel.filteredHistoryItems,
                            isPinnedSection: false,
                            emptyMessage: "No clipboard text yet"
                        )
                    }

                    if viewModel.allDisplayItems.isEmpty {
                        EmptyStateView()
                    } else if viewModel.filteredDisplayItems.isEmpty {
                        SearchEmptyStateView(query: viewModel.searchQuery)
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
            if isSearchPresented {
                isSearchFocused = true
            }
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
                    systemImage: isSearchPresented ? "xmark" : "magnifyingglass",
                    help: isSearchPresented ? "Close search" : "Search",
                    action: toggleSearch
                )

                ToolbarIconButton(
                    systemImage: "gearshape",
                    help: "Settings",
                    action: onOpenSettings
                )
            }

            if isSearchPresented {
                searchBar
                    .transition(.move(edge: .top).combined(with: .opacity))
            }

            HStack(spacing: 8) {
                StatPill(
                    title: "Pinned",
                    value: "\(viewModel.filteredPinnedItems.count)",
                    systemImage: "pin.fill"
                )

                StatPill(
                    title: "History",
                    value: "\(viewModel.filteredHistoryItems.count)",
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

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.secondary)

            TextField("Search clipboard text", text: $viewModel.searchQuery)
                .textFieldStyle(.plain)
                .focused($isSearchFocused)

            if !viewModel.searchQuery.isEmpty {
                Button {
                    viewModel.searchQuery = ""
                    isSearchFocused = true
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 13, weight: .semibold))
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .help("Clear search")
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.88))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(isSearchFocused ? Color.accentColor.opacity(0.55) : Color.secondary.opacity(0.12))
        }
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
        isPinnedSection: Bool,
        emptyMessage: String?
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
                if let emptyMessage {
                    Text(emptyMessage)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 12)
                }
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

    private func toggleSearch() {
        withAnimation(.easeInOut(duration: 0.16)) {
            isSearchPresented.toggle()
            if !isSearchPresented {
                viewModel.searchQuery = ""
            }
        }

        if isSearchPresented {
            Task { @MainActor in
                isSearchFocused = true
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

private struct SearchEmptyStateView: View {
    let query: String

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 26, weight: .semibold))
                .foregroundStyle(.secondary)
                .frame(width: 54, height: 54)
                .background(Color(nsColor: .controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            Text("No matches")
                .font(.callout.weight(.semibold))

            Text(query.trimmingCharacters(in: .whitespacesAndNewlines))
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
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

private struct WarningBanner: View {
    let message: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "keyboard.badge.exclamationmark")
                .foregroundStyle(.orange)

            Text(message)
                .lineLimit(3)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .font(.caption)
        .padding(10)
        .background(Color.orange.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(Color.orange.opacity(0.18))
        }
    }
}
