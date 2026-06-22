import AppKit
import SwiftData
import XCTest
@testable import ClipLedger

@MainActor
final class ClipboardViewModelTests: XCTestCase {
    private var defaults: UserDefaults!
    private var defaultsSuiteName: String!
    private var retainedContainers: [ModelContainer]!

    override func setUp() async throws {
        try await super.setUp()
        defaultsSuiteName = "ClipLedgerTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: defaultsSuiteName)
        retainedContainers = []
    }

    override func tearDown() async throws {
        retainedContainers = nil
        defaults.removePersistentDomain(forName: defaultsSuiteName)
        defaults = nil
        defaultsSuiteName = nil
        try await super.tearDown()
    }

    func testRecordClipboardContentIgnoresInvalidAndConsecutiveDuplicateContent() throws {
        let viewModel = try makeViewModel()

        viewModel.recordClipboardContent("   \n\t")
        XCTAssertTrue(viewModel.historyItems.isEmpty)

        viewModel.recordClipboardContent("Hello")
        viewModel.recordClipboardContent("Hello")

        XCTAssertEqual(viewModel.historyItems.count, 1)
        XCTAssertEqual(viewModel.historyItems.first?.content, "Hello")

        viewModel.recordClipboardContent(String(repeating: "x", count: 10_001))
        XCTAssertEqual(viewModel.historyItems.count, 1)
    }

    func testHistoryLimitDeletesOldestUnpinnedItemsOnly() throws {
        let viewModel = try makeViewModel(maximumHistoryCount: 50)

        viewModel.recordClipboardContent("Pinned")
        let pinned = try XCTUnwrap(viewModel.historyItems.first)
        viewModel.pin(pinned)

        for index in 1...51 {
            viewModel.recordClipboardContent("Item \(index)")
        }

        XCTAssertEqual(viewModel.pinnedItems.map(\.content), ["Pinned"])
        XCTAssertEqual(viewModel.historyItems.count, 50)
        XCTAssertEqual(viewModel.historyItems.first?.content, "Item 51")
        XCTAssertFalse(viewModel.historyItems.contains { $0.content == "Item 1" })
    }

    func testRestoreIncrementsUsageWritesPasteboardAndAutoPinsAtThreshold() throws {
        let pasteboard = NSPasteboard.withUniqueName()
        let viewModel = try makeViewModel(pasteboard: pasteboard)

        viewModel.recordClipboardContent("Reusable")

        for _ in 0..<AppSettings.autoPinThreshold {
            let item = try XCTUnwrap((viewModel.historyItems + viewModel.pinnedItems).first)
            viewModel.restore(item)
        }

        let pinned = try XCTUnwrap(viewModel.pinnedItems.first)
        XCTAssertEqual(pinned.content, "Reusable")
        XCTAssertEqual(pinned.usageCount, AppSettings.autoPinThreshold)
        XCTAssertEqual(pasteboard.string(forType: .string), "Reusable")
    }

    func testSearchFiltersPinnedAndHistoryItemsCaseInsensitively() throws {
        let viewModel = try makeViewModel()

        viewModel.recordClipboardContent("Project Alpha")
        viewModel.recordClipboardContent("Meeting Beta")
        let alpha = try XCTUnwrap(viewModel.historyItems.first { $0.content == "Project Alpha" })
        viewModel.pin(alpha)

        viewModel.searchQuery = "alpha"

        XCTAssertEqual(viewModel.filteredPinnedItems.map(\.content), ["Project Alpha"])
        XCTAssertTrue(viewModel.filteredHistoryItems.isEmpty)

        viewModel.searchQuery = "MEETING"

        XCTAssertTrue(viewModel.filteredPinnedItems.isEmpty)
        XCTAssertEqual(viewModel.filteredHistoryItems.map(\.content), ["Meeting Beta"])

        viewModel.searchQuery = ""

        XCTAssertEqual(viewModel.filteredPinnedItems.map(\.content), ["Project Alpha"])
        XCTAssertEqual(viewModel.filteredHistoryItems.map(\.content), ["Meeting Beta"])
    }

    func testRestoreSelectedItemUsesFilteredSearchResults() throws {
        let pasteboard = NSPasteboard.withUniqueName()
        let viewModel = try makeViewModel(pasteboard: pasteboard)

        viewModel.recordClipboardContent("Alpha")
        viewModel.recordClipboardContent("Beta")
        viewModel.recordClipboardContent("Gamma")

        viewModel.searchQuery = "beta"
        viewModel.restoreSelectedItem()

        XCTAssertEqual(pasteboard.string(forType: .string), "Beta")
        XCTAssertEqual(viewModel.filteredDisplayItems.map(\.content), ["Beta"])
        XCTAssertEqual(viewModel.filteredDisplayItems.first?.usageCount, 1)
    }

    func testTenThousandHistoryOperationsMaintainLimitAndOrdering() throws {
        let measureOptions = XCTMeasureOptions()
        measureOptions.iterationCount = 1

        measure(metrics: [XCTClockMetric()], options: measureOptions) {
            do {
                let viewModel = try makeViewModel(maximumHistoryCount: 200)

                for index in 0..<10_000 {
                    viewModel.recordClipboardContent("Bulk Item \(index)")
                }

                XCTAssertNil(viewModel.errorMessage)
                XCTAssertTrue(viewModel.pinnedItems.isEmpty)
                XCTAssertEqual(viewModel.historyItems.count, 200)
                XCTAssertEqual(viewModel.historyItems.first?.content, "Bulk Item 9999")
                XCTAssertEqual(viewModel.historyItems.last?.content, "Bulk Item 9800")
            } catch {
                XCTFail("Failed to build performance test model: \(error)")
            }
        }
    }

    private func makeViewModel(
        maximumHistoryCount: Int = 100,
        pasteboard: NSPasteboard = .withUniqueName()
    ) throws -> ClipboardViewModel {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: ClipboardItem.self, configurations: configuration)
        retainedContainers.append(container)

        let settings = AppSettings(defaults: defaults)
        settings.maximumHistoryCount = maximumHistoryCount

        return ClipboardViewModel(
            modelContext: container.mainContext,
            settings: settings,
            pasteboard: pasteboard
        )
    }
}
