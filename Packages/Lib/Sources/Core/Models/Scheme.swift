import Foundation

public struct Scheme: Codable, Sendable, Hashable, Identifiable {
    public var id: UUID
    public var name: String
    public var platforms: [Platform]

    public init(id: UUID = UUID(), name: String = "", platforms: [Platform] = []) {
        self.id = id
        self.name = name
        self.platforms = platforms
    }
}
