import Foundation

/// Core protocol defining backend operations
public protocol BackendService: Sendable {
    // MARK: - Associated Types for AsyncSequences
    associatedtype ProjectIdsSequence: AsyncSequence where ProjectIdsSequence.Element == [String]
    associatedtype ProjectSequence: AsyncSequence where ProjectSequence.Element == ProjectValue?
    associatedtype ProjectVersionStringsSequence: AsyncSequence where ProjectVersionStringsSequence.Element == [String: [String]]
    associatedtype SchemeIdsSequence: AsyncSequence where SchemeIdsSequence.Element == [UUID]
    associatedtype SchemeSequence: AsyncSequence where SchemeSequence.Element == SchemeValue?
    associatedtype BuildIdsSequence: AsyncSequence where BuildIdsSequence.Element == [UUID]
    associatedtype BuildSequence: AsyncSequence where BuildSequence.Element == BuildModelValue?
    associatedtype LatestBuildsSequence: AsyncSequence where LatestBuildsSequence.Element == [BuildModelValue]
    associatedtype BuildLogIdsSequence: AsyncSequence where BuildLogIdsSequence.Element == [UUID]
    associatedtype BuildLogSequence: AsyncSequence where BuildLogSequence.Element == BuildLogValue?
    associatedtype CrashLogIdsSequence: AsyncSequence where CrashLogIdsSequence.Element == [String]
    associatedtype CrashLogSequence: AsyncSequence where CrashLogSequence.Element == CrashLogValue?
    associatedtype ProjectDetailSequence: AsyncSequence where ProjectDetailSequence.Element == ProjectDetailData
    associatedtype BuildVersionStringsSequence: AsyncSequence where BuildVersionStringsSequence.Element == [String]

    // MARK: - Write Operations
    func createProject(_ project: ProjectValue) async throws
    func updateProject(_ project: ProjectValue) async throws
    func deleteProject(id: String) async throws

    func createScheme(_ scheme: SchemeValue) async throws
    func updateScheme(_ scheme: SchemeValue) async throws
    func deleteScheme(id: UUID) async throws

    func createBuild(_ build: BuildModelValue) async throws
    func updateBuild(_ build: BuildModelValue) async throws
    func deleteBuild(id: UUID) async throws

    func createBuildLog(_ log: BuildLogValue) async throws
    func deleteBuildLogs(buildId: UUID) async throws

    func createCrashLog(_ crashLog: CrashLogValue) async throws
    func updateCrashLog(_ crashLog: CrashLogValue) async throws
    func deleteCrashLog(id: String) async throws

    // MARK: - Observation Methods (return AsyncSequence with immediate data + reactive updates)
    func streamAllProjectIds() -> ProjectIdsSequence
    func streamProject(id: String) -> ProjectSequence
    func streamProjectVersionStrings() -> ProjectVersionStringsSequence
    func streamSchemeIds(projectId: String) -> SchemeIdsSequence
    func streamScheme(id: UUID) -> SchemeSequence
    func streamBuildIds(schemeIds: [UUID], versionString: String?) -> BuildIdsSequence
    func streamBuild(id: UUID) -> BuildSequence
    func streamLatestBuilds(projectId: String, limit: Int) -> LatestBuildsSequence
    func streamBuildLogIds(buildId: UUID, includeDebug: Bool, category: String?) -> BuildLogIdsSequence
    func streamBuildLog(id: UUID) -> BuildLogSequence
    func streamCrashLogIds(buildId: UUID) -> CrashLogIdsSequence
    func streamCrashLog(id: String) -> CrashLogSequence
    func streamProjectDetail(id: String) -> ProjectDetailSequence
    func streamBuildVersionStrings(projectId: String) -> BuildVersionStringsSequence
}

// MARK: - Data Transfer Objects
public struct ProjectDetailData: Sendable {
    public let project: ProjectValue
    public let schemeIds: [UUID]
    public let recentBuildIds: [UUID]

    public init(project: ProjectValue, schemeIds: [UUID], recentBuildIds: [UUID]) {
        self.project = project
        self.schemeIds = schemeIds
        self.recentBuildIds = recentBuildIds
    }
}