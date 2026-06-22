import SwiftUI

struct MainView: View {
    @ObservedObject var viewModel: ClipboardViewModel
    @ObservedObject var settings: AppSettings

    let onOpenSettings: () -> Void

    @State private var isShowingClearConfirmation = false

    var body: some View {
        VStack(spacing: 0) {
            header

            Divider()

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 18) {
                    if !viewModel.pinnedItems.isEmpty {
                        itemSection(
                            title: "Pinned",
                            items: viewModel.pinnedItems,
                            isPinnedSection: true
                        )
                    }

                    itemSection(
                        title: "History",
                        items: viewModel.historyItems,
                        isPinnedSection: false
                    )

                    if viewModel.allDisplayItems.isEmpty {
                        EmptyStateView()
                    }
                }
                .padding(16)
            }

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .lineLimit(2)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
            }

            Divider()
            footer
        }
        .frame(width: 440, height: 620)
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
        HStack(spacing: 10) {
            Text("ClipLedger")
                .font(.title3.weight(.semibold))

            Spacer()

            Button {} label: {
                Image(systemName: "magnifyingglass")
            }
            .disabled(true)
            .help("Search")

            Button(action: onOpenSettings) {
                Image(systemName: "gearshape")
            }
            .help("Settings")
        }
        .buttonStyle(.borderless)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var footer: some View {
        HStack {
            Button(role: .destructive) {
                isShowingClearConfirmation = true
            } label: {
                Label("Clear History", systemImage: "trash")
            }
            .disabled(viewModel.historyItems.isEmpty)

            Spacer()

            Button(action: onOpenSettings) {
                Label("Settings", systemImage: "gearshape")
            }
        }
        .padding(16)
    }

    private func itemSection(
        title: String,
        items: [ClipboardItem],
        isPinnedSection: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
                Text("\(items.count)")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            }

            if items.isEmpty {
                Text("No history yet")
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
                        onRestore: {
                            viewModel.restore(item)
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
                        viewModel.restore(item)
                    }
                }
            }
        }
    }
}
