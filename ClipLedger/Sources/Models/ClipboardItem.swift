import Foundation
import SwiftData

@Model
final class ClipboardItem {
    @Attribute(.unique) var id: UUID
    var content: String
    var createdAt: Date
    var characterCount: Int
    var usageCount: Int
    var isPinned: Bool
    var tagName: String?

    init(
        id: UUID = UUID(),
        content: String,
        createdAt: Date = Date(),
        usageCount: Int = 0,
        isPinned: Bool = false,
        tagName: String? = nil
    ) {
        self.id = id
        self.content = content
        self.createdAt = createdAt
        self.characterCount = content.count
        self.usageCount = usageCount
        self.isPinned = isPinned
        self.tagName = tagName
    }

    var normalizedTagName: String? {
        guard let tagName else { return nil }
        let trimmed = tagName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
