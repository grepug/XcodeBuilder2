import Foundation
import SharingGRDB

@Table("buildLogs")
public struct BuildLog: Identifiable, Sendable {
    public var id: UUID

    @Column("build_id")
    public var buildId: UUID

    public var level: Level

    @Column("log_content")
    public var content: String

    @Column("created_at")
    public var createdAt: Date = .now

    public init(id: UUID = UUID(), buildId: UUID, content: String, level: Level = .info) {
        self.id = id
        self.buildId = buildId
        self.content = content
        self.level = level
    }
}

extension BuildLog {
    public enum Level: String, Sendable, QueryBindable {
        case info
        case warning
        case error
        case debug
    }
}