import Foundation
import Sharing

/// Universal SharingKey for all backend queries
public struct BackendQuery<Value: Sendable>: Sendable, Hashable, CustomStringConvertible {
    public let key: String

    public init(_ key: String) {
        self.key = key
    }

    public var description: String { "BackendQuery(\(key))" }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(key)
        hasher.combine(ObjectIdentifier(Value.self))
    }

    public static func == (lhs: BackendQuery<Value>, rhs: BackendQuery<Value>) -> Bool {
        return lhs.key == rhs.key
    }
}

// MARK: - Static Factory Methods

public extension BackendQuery {

    // MARK: - Project Queries
    static func allProjectIds() -> BackendQuery<[String]> {
        BackendQuery<[String]>("projects.all.ids")
    }

    static func project(id: String) -> BackendQuery<ProjectValue?> {
        BackendQuery<ProjectValue?>("project.\(id)")
    }

    static func projectVersionStrings() -> BackendQuery<[String: [String]]> {
        BackendQuery<[String: [String]]>("projects.versionStrings")
    }

    static func projectDetail(id: String) -> BackendQuery<ProjectDetailData> {
        BackendQuery<ProjectDetailData>("project.\(id).detail")
    }

    static func buildVersionStrings(projectId: String) -> BackendQuery<[String]> {
        BackendQuery<[String]>("project.\(projectId).buildVersionStrings")
    }

    // MARK: - Scheme Queries
    static func schemeIds(projectId: String) -> BackendQuery<[UUID]> {
        BackendQuery<[UUID]>("project.\(projectId).schemes.ids")
    }

    static func scheme(id: UUID) -> BackendQuery<SchemeValue?> {
        BackendQuery<SchemeValue?>("scheme.\(id.uuidString)")
    }

    // MARK: - Build Queries
    static func buildIds(schemeIds: [UUID], versionString: String?) -> BackendQuery<[UUID]> {
        let schemeIdString = schemeIds.map(\.uuidString).joined(separator: ",")
        let versionSuffix = versionString.map { ".\($0)" } ?? ""
        return BackendQuery<[UUID]>("schemes.\(schemeIdString).builds.ids\(versionSuffix)")
    }

    static func build(id: UUID) -> BackendQuery<BuildModelValue?> {
        BackendQuery<BuildModelValue?>("build.\(id.uuidString)")
    }

    static func latestBuilds(projectId: String, limit: Int) -> BackendQuery<[BuildModelValue]> {
        BackendQuery<[BuildModelValue]>("project.\(projectId).latestBuilds.limit\(limit)")
    }

    // MARK: - Build Log Queries
    static func buildLogIds(buildId: UUID, includeDebug: Bool, category: String?) -> BackendQuery<[UUID]> {
        let debugSuffix = includeDebug ? ".debug" : ""
        let categorySuffix = category.map { ".category\($0)" } ?? ""
        return BackendQuery<[UUID]>("build.\(buildId.uuidString).logs.ids\(debugSuffix)\(categorySuffix)")
    }

    static func buildLog(id: UUID) -> BackendQuery<BuildLogValue?> {
        BackendQuery<BuildLogValue?>("buildLog.\(id.uuidString)")
    }

    // MARK: - Crash Log Queries
    static func crashLogIds(buildId: UUID) -> BackendQuery<[String]> {
        BackendQuery<[String]>("build.\(buildId.uuidString).crashLogs.ids")
    }

    static func crashLog(id: String) -> BackendQuery<CrashLogValue?> {
        BackendQuery<CrashLogValue?>("crashLog.\(id)")
    }
}

// MARK: - Domain Model Convenience Extensions

public extension BackendQuery {

    /// Convert BackendQuery<ProjectValue?> to BackendQuery<Project?>
    static func domainProject(id: String) -> BackendQuery<Project?> {
        BackendQuery<Project?>("project.\(id)")
    }

    /// Convert BackendQuery<SchemeValue?> to BackendQuery<Scheme?>
    static func domainScheme(id: UUID) -> BackendQuery<Scheme?> {
        BackendQuery<Scheme?>("scheme.\(id.uuidString)")
    }

    /// Convert BackendQuery<BuildModelValue?> to BackendQuery<BuildModel?>
    static func domainBuild(id: UUID) -> BackendQuery<BuildModel?> {
        BackendQuery<BuildModel?>("build.\(id.uuidString)")
    }

    /// Convert BackendQuery<BuildLogValue?> to BackendQuery<BuildLog?>
    static func domainBuildLog(id: UUID) -> BackendQuery<BuildLog?> {
        BackendQuery<BuildLog?>("buildLog.\(id.uuidString)")
    }

    /// Convert BackendQuery<CrashLogValue?> to BackendQuery<CrashLog?>
    static func domainCrashLog(id: String) -> BackendQuery<CrashLog?> {
        BackendQuery<CrashLog?>("crashLog.\(id)")
    }

    /// Convert BackendQuery<[BuildModelValue]> to BackendQuery<[BuildModel]>
    static func domainLatestBuilds(projectId: String, limit: Int) -> BackendQuery<[BuildModel]> {
        BackendQuery<[BuildModel]>("project.\(projectId).latestBuilds.limit\(limit)")
    }
}
