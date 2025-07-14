import Foundation

public struct Scheme: Codable, Sendable, Hashable, Identifiable, Comparable {
    public var id: UUID
    public var name: String
    public var platforms: [Platform]
    public var order: Int
    
    public static func < (lhs: Scheme, rhs: Scheme) -> Bool {
        lhs.order < rhs.order
    }

    public init(id: UUID = UUID(), name: String = "", platforms: [Platform] = [], order: Int = 0) {
        self.id = id
        self.name = name
        self.platforms = platforms
        self.order = order
    }
}
