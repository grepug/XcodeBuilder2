import Foundation
import SharingGRDB
import Core

@Table
public struct Scheme: Codable, Sendable, Hashable, Identifiable, Comparable {
    public var id: UUID

    @Column("project_bundle_identifier")
    public var projectBundleIdentifier: String

    public var name: String

    @Column(as: [Platform].JSONRepresentation.self)
    public var platforms: [Platform]

    public var order: Int
    
    public static func < (lhs: Scheme, rhs: Scheme) -> Bool {
        lhs.order < rhs.order
    }

    public init(
        id: UUID = UUID(), 
        projectBundleIdentifier: String = "",
        name: String = "", 
        platforms: [Platform] = [], 
        order: Int = 0,
    ) {
        self.id = id
        self.projectBundleIdentifier = projectBundleIdentifier
        self.name = name
        self.platforms = platforms
        self.order = order
    }
}
