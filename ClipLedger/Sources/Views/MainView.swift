import AppKit
import SwiftUI

struct MainView: View {
    @ObservedObject var viewModel: ClipboardViewModel
    @ObservedObject var settings: AppSettings

    let onOpenSettings: () -> Void

    @State private var isShowingClearConfirmation = false
    @State private var recentlyRestoredItemID: UUID?
    @State private var isSearchPresented = false
    @State private var tagEditorItem: ClipboardItem?
    @State private var tagDraft = ""
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
                        pinnedSection(groups: viewModel.filteredPinnedTagGroups)
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
        .sheet(item: $tagEditorItem) { item in
            TagEditorSheet(
                item: item,
                tagDraft: $tagDraft,
                existingTags: viewModel.availablePinnedTags,
                onCancel: {
                    tagEditorItem = nil
                },
                onClear: {
                    viewModel.setTag("", for: item)
                    tagEditorItem = nil
                },
                onSave: {
                    viewModel.setTag(tagDraft, for: item)
                    tagEditorItem = nil
                }
            )
        }
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
            sectionHeader(
                title: title,
                systemImage: systemImage,
                count: items.count,
                isPinnedSection: isPinnedSection
            )

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
                    itemRow(item, isPinnedSection: isPinnedSection)
                }
            }
        }
    }

    private func pinnedSection(groups: [PinnedTagGroup]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(
                title: "Pinned",
                systemImage: "pin.fill",
                count: viewModel.filteredPinnedItems.count,
                isPinnedSection: true
            )

            ForEach(groups) { group in
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 7) {
                        Image(systemName: group.tagName == nil ? "tag.slash" : "tag")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.secondary)

                        Text(group.title)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)

                        Spacer()

                        Text("\(group.items.count)")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .frame(minWidth: 18)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color(nsColor: .controlBackgroundColor).opacity(0.75))
                            .clipShape(Capsule())
                    }
                    .padding(.top, group.id == groups.first?.id ? 0 : 4)

                    ForEach(group.items) { item in
                        itemRow(item, isPinnedSection: true)
                    }
                }
            }
        }
    }

    private func sectionHeader(
        title: String,
        systemImage: String,
        count: Int,
        isPinnedSection: Bool
    ) -> some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(isPinnedSection ? Color.accentColor : .secondary)

            Text(title)
                .font(.subheadline.weight(.semibold))

            Spacer()

            Text("\(count)")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(minWidth: 20)
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(Color(nsColor: .controlBackgroundColor))
                .clipShape(Capsule())
        }
    }

    private func itemRow(_ item: ClipboardItem, isPinnedSection: Bool) -> some View {
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
            },
            onEditTag: isPinnedSection ? {
                editTag(item)
            } : nil
        )
        .onTapGesture {
            restore(item)
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

    private func editTag(_ item: ClipboardItem) {
        tagDraft = item.normalizedTagName ?? ""
        tagEditorItem = item
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

private struct TagEditorSheet: View {
    let item: ClipboardItem
    @Binding var tagDraft: String
    let existingTags: [String]
    let onCancel: () -> Void
    let onClear: () -> Void
    let onSave: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                Image(systemName: "tag")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 34, height: 34)
                    .background(Color.accentColor.opacity(0.14))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text("Pinned Tag")
                        .font(.headline)
                    Text(item.content)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()
            }

            VStack(alignment: .leading, spacing: 7) {
                Text("Tag")
                    .font(.callout.weight(.medium))

                TextField("Examples: Work, Email, Code", text: $tagDraft)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit(onSave)
            }

            if !existingTags.isEmpty {
                VStack(alignment: .leading, spacing: 7) {
                    Text("Existing Tags")
                        .font(.callout.weight(.medium))

                    ScrollView(.horizontal) {
                        HStack(spacing: 8) {
                            ForEach(existingTags, id: \.self) { tag in
                                Button {
                                    tagDraft = tag
                                } label: {
                                    Label(tag, systemImage: "tag")
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                        .padding(.vertical, 1)
                    }
                    .scrollIndicators(.hidden)
                }
            }

            HStack {
                Button("Cancel", action: onCancel)

                Spacer()

                Button("Clear Tag", role: .destructive, action: onClear)
                    .disabled(item.normalizedTagName == nil)

                Button("Save", action: onSave)
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(18)
        .frame(width: 420)
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
