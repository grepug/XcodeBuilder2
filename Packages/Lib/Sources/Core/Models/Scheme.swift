import Foundation

public struct Scheme: Codable, Sendable, Hashable, Identifiable {
    public var name: String
    public var platforms: [Platform]

    public var id: String {
        name
    }
    
    public init(name: String, platforms: [Platform]) {
        self.name = name
        self.platforms = platforms
    }
}
