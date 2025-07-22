import Foundation
import SharingGRDB
import Dependencies
import Core

/// Service responsible for log-related streaming operations
public struct LogStreamingService: Sendable {
    /// Initialize the log streaming service
    public init() {}

    // MARK: - Log Streaming Methods

    /// Stream build log IDs for a specific build
    public func streamBuildLogIds(buildId: UUID, includeDebug: Bool, category: String?) -> some AsyncSequence<[UUID], Never> {
        @FetchAll(
            BuildLog
                .where { $0.buildId == buildId }
                .where { includeDebug || $0.level != BuildLogLevel.debug }
                .where { category == nil || $0.category == category }
                .order(by: \.createdAt)
                .select(\.id)
        ) var logIds: [UUID]

        return $logIds.publisher.values
    }

    /// Stream a specific build log by ID
    public func streamBuildLog(id: UUID) -> some AsyncSequence<BuildLogValue?, Never> {
        @FetchOne(
            BuildLog
                .where { $0.id == id }
        ) var buildLog: BuildLog?

        return $buildLog.publisher.values
            .map { dbLog -> BuildLogValue? in
                guard let dbLog = dbLog else { return nil }
                return dbLog.toValue()
            }
    }

    /// Stream crash log IDs for a specific build
    public func streamCrashLogIds(buildId: UUID) -> some AsyncSequence<[String], Never> {
        @FetchAll(
            CrashLog
                .where { $0.buildId == buildId }
                .order { $0.createdAt.desc() }
                .select(\.incidentIdentifier)
        ) var crashLogIds: [String]

        return $crashLogIds.publisher.values
    }

    /// Stream a specific crash log by ID
    public func streamCrashLog(id: String) -> some AsyncSequence<CrashLogValue?, Never> {
        @FetchOne(
            CrashLog
                .where { $0.incidentIdentifier == id }
        ) var crashLog: CrashLog?

        return $crashLog.publisher.values
            .map { dbCrashLog -> CrashLogValue? in
                guard let dbCrashLog = dbCrashLog else { return nil }
                return dbCrashLog.toValue()
            }
    }
}
