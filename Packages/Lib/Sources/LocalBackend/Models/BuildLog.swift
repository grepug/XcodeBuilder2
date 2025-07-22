import Foundation
import SharingGRDB
import Core

@Table("buildLogs")
public struct BuildLog: Identifiable, Sendable, BuildLogProtocol {
    public var id: UUID

    @Column("build_id")
    public var buildId: UUID

    public var category: String?

    public var level: BuildLogLevel

    @Column("log_content")
    public var content: String

    @Column("created_at")
    public var createdAt: Date = .now

    public init(id: UUID = UUID(), buildId: UUID, category: String? = nil, content: String, level: BuildLogLevel = .info) {
        self.id = id
        self.buildId = buildId
        self.category = category
        self.content = content
        self.level = level
    }
}
