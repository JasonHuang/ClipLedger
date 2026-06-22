import AppKit
import Foundation
import SwiftData

@MainActor
final class ClipboardViewModel: ObservableObject {
    @Published private(set) var pinnedItems: [ClipboardItem] = []
    @Published private(set) var historyItems: [ClipboardItem] = []
    @Published var selectedItemID: UUID?
    @Published var errorMessage: String?
    @Published var shortcutWarningMessage: String?

    var onSystemClipboardWritten: (() -> Void)?

    private let modelContext: ModelContext
    private let settings: AppSettings
    private let pasteboard: NSPasteboard
    private let maximumContentLength = 10_000
    private var latestRecordedContent: String?

    init(modelContext: ModelContext, settings: AppSettings, pasteboard: NSPasteboard = .general) {
        self.modelContext = modelContext
        self.settings = settings
        self.pasteboard = pasteboard
    }

    var allDisplayItems: [ClipboardItem] {
        pinnedItems + historyItems
    }

    func reload() {
        do {
            let pinnedDescriptor = FetchDescriptor<ClipboardItem>(
                predicate: #Predicate { item in
                    item.isPinned
                },
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            )
            let historyDescriptor = FetchDescriptor<ClipboardItem>(
                predicate: #Predicate { item in
                    !item.isPinned
                },
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            )

            pinnedItems = try modelContext.fetch(pinnedDescriptor)
            historyItems = try modelContext.fetch(historyDescriptor)
            updateLatestRecordedContent()
            updateSelectionAfterReload()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func recordClipboardContent(_ content: String) {
        guard isValidClipboardContent(content) else { return }

        if settings.removeConsecutiveDuplicates, latestRecordedContent == content {
            return
        }

        let item = ClipboardItem(content: content)
        modelContext.insert(item)
        historyItems.insert(item, at: 0)
        latestRecordedContent = content
        trimLoadedHistoryItemsToLimit()
        updateSelectionAfterReload()

        if !saveChanges() {
            reload()
        }
    }

    func restore(_ item: ClipboardItem) {
        item.usageCount += 1
        if item.usageCount >= AppSettings.autoPinThreshold {
            item.isPinned = true
        }

        pasteboard.clearContents()
        pasteboard.setString(item.content, forType: .string)
        onSystemClipboardWritten?()

        saveChanges()
        enforceHistoryLimit()
        reload()
    }

    func restoreSelectedItem() {
        guard let selectedItem = selectedItem else { return }
        restore(selectedItem)
    }

    func pin(_ item: ClipboardItem) {
        item.isPinned = true
        saveChanges()
        reload()
    }

    func unpin(_ item: ClipboardItem) {
        item.isPinned = false
        saveChanges()
        enforceHistoryLimit()
        reload()
    }

    func delete(_ item: ClipboardItem) {
        modelContext.delete(item)
        saveChanges()
        reload()
    }

    func clearHistory() {
        do {
            let descriptor = FetchDescriptor<ClipboardItem>(
                predicate: #Predicate { item in
                    !item.isPinned
                }
            )
            let items = try modelContext.fetch(descriptor)
            items.forEach(modelContext.delete)
            saveChanges()
            reload()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func enforceHistoryLimitAndReload() {
        enforceHistoryLimit()
        reload()
    }

    func selectNextItem() {
        moveSelection(offset: 1)
    }

    func selectPreviousItem() {
        moveSelection(offset: -1)
    }

    private var selectedItem: ClipboardItem? {
        guard let selectedItemID else { return nil }
        return allDisplayItems.first { $0.id == selectedItemID }
    }

    private func moveSelection(offset: Int) {
        let items = allDisplayItems
        guard !items.isEmpty else {
            selectedItemID = nil
            return
        }

        let currentIndex = selectedItemID.flatMap { selectedID in
            items.firstIndex { $0.id == selectedID }
        } ?? 0
        let nextIndex = min(max(currentIndex + offset, 0), items.count - 1)
        selectedItemID = items[nextIndex].id
    }

    private func updateSelectionAfterReload() {
        let items = allDisplayItems
        guard !items.isEmpty else {
            selectedItemID = nil
            return
        }

        if let selectedItemID, items.contains(where: { $0.id == selectedItemID }) {
            return
        }

        selectedItemID = items.first?.id
    }

    private func isValidClipboardContent(_ content: String) -> Bool {
        guard content.count <= maximumContentLength else { return false }
        return !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func updateLatestRecordedContent() {
        latestRecordedContent = [pinnedItems.first, historyItems.first]
            .compactMap { $0 }
            .max { $0.createdAt < $1.createdAt }?
            .content
    }

    private func trimLoadedHistoryItemsToLimit() {
        let overflowCount = historyItems.count - settings.maximumHistoryCount
        guard overflowCount > 0 else { return }

        for item in historyItems.suffix(overflowCount) {
            modelContext.delete(item)
        }
        historyItems.removeLast(overflowCount)
    }

    private func enforceHistoryLimit() {
        do {
            let descriptor = FetchDescriptor<ClipboardItem>(
                predicate: #Predicate { item in
                    !item.isPinned
                },
                sortBy: [SortDescriptor(\.createdAt, order: .forward)]
            )
            let unpinnedItems = try modelContext.fetch(descriptor)
            let overflowCount = unpinnedItems.count - settings.maximumHistoryCount
            guard overflowCount > 0 else { return }

            for item in unpinnedItems.prefix(overflowCount) {
                modelContext.delete(item)
            }
            saveChanges()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @discardableResult
    private func saveChanges() -> Bool {
        do {
            try modelContext.save()
            errorMessage = nil
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}
