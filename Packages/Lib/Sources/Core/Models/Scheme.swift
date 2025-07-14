import Foundation

public struct Scheme: Codable, Sendable, Hashable, Identifiable {
    let name: String
    
    let platforms: [Platform]

    public var id: String {
        name
    }
    
    public init(name: String, platforms: [Platform]) {
        self.name = name
        self.platforms = platforms
    }
}
