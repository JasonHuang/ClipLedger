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

    init(
        id: UUID = UUID(),
        content: String,
        createdAt: Date = Date(),
        usageCount: Int = 0,
        isPinned: Bool = false
    ) {
        self.id = id
        self.content = content
        self.createdAt = createdAt
        self.characterCount = content.count
        self.usageCount = usageCount
        self.isPinned = isPinned
    }
}
