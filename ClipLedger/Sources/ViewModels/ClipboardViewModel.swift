import AppKit
import Foundation
import SwiftData

struct PinnedTagGroup: Identifiable {
    let tagName: String?
    let items: [ClipboardItem]

    var id: String {
        tagName ?? "__clipledger_untagged__"
    }

    var title: String {
        tagName ?? "No Tag"
    }
}

@MainActor
final class ClipboardViewModel: ObservableObject {
    @Published private(set) var pinnedItems: [ClipboardItem] = []
    @Published private(set) var historyItems: [ClipboardItem] = []
    @Published var selectedItemID: UUID?
    @Published var errorMessage: String?
    @Published var shortcutWarningMessage: String?
    @Published var searchQuery = "" {
        didSet {
            updateSelectionAfterReload()
        }
    }

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

    var filteredPinnedItems: [ClipboardItem] {
        filteredItems(from: pinnedItems)
    }

    var filteredPinnedTagGroups: [PinnedTagGroup] {
        pinnedTagGroups(from: filteredPinnedItems)
    }

    var filteredHistoryItems: [ClipboardItem] {
        filteredItems(from: historyItems)
    }

    var filteredDisplayItems: [ClipboardItem] {
        filteredPinnedItems + filteredHistoryItems
    }

    var isSearching: Bool {
        !normalizedSearchQuery.isEmpty
    }

    var availablePinnedTags: [String] {
        Array(Set(pinnedItems.compactMap(\.normalizedTagName)))
            .sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
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
        item.tagName = nil
        saveChanges()
        enforceHistoryLimit()
        reload()
    }

    func setTag(_ tagName: String, for item: ClipboardItem) {
        let normalizedTagName = Self.normalizedTagName(tagName)
        item.tagName = normalizedTagName
        saveChanges()
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
        return filteredDisplayItems.first { $0.id == selectedItemID }
    }

    private func moveSelection(offset: Int) {
        let items = filteredDisplayItems
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
        let items = filteredDisplayItems
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

    private var normalizedSearchQuery: String {
        searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func filteredItems(from items: [ClipboardItem]) -> [ClipboardItem] {
        let query = normalizedSearchQuery
        guard !query.isEmpty else { return items }

        return items.filter { item in
            item.content.range(of: query, options: [.caseInsensitive, .diacriticInsensitive]) != nil ||
                (item.normalizedTagName?.range(of: query, options: [.caseInsensitive, .diacriticInsensitive]) != nil)
        }
    }

    private func pinnedTagGroups(from items: [ClipboardItem]) -> [PinnedTagGroup] {
        let groupedItems = Dictionary(grouping: items) { item in
            item.normalizedTagName
        }
        let taggedGroups = groupedItems
            .compactMap { tagName, items -> PinnedTagGroup? in
                guard let tagName else { return nil }
                return PinnedTagGroup(tagName: tagName, items: items)
            }
            .sorted { lhs, rhs in
                lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
            }

        if let untaggedItems = groupedItems[nil], !untaggedItems.isEmpty {
            return taggedGroups + [PinnedTagGroup(tagName: nil, items: untaggedItems)]
        }

        return taggedGroups
    }

    private static func normalizedTagName(_ tagName: String) -> String? {
        let trimmed = tagName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
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
