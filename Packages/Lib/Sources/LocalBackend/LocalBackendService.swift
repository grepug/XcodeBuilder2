import Foundation
import SharingGRDB
import GRDB
import Dependencies
import Core

public struct LocalBackendService: BackendService {
    @Dependency(\.defaultDatabase) var db
    @Dependency(\.localBuildJobManager) var buildJobManager
    
    // Internal data services - not exposed in public API
    @Dependency(\.projectDataService) private var projectService
    @Dependency(\.schemeDataService) private var schemeService
    @Dependency(\.buildDataService) private var buildService
    @Dependency(\.logDataService) private var logService

    public init() {
        // Dependencies injection handles database access and build job management
    }

    // MARK: - Write Operations

    public func createProject(_ project: ProjectValue) async throws {
        try await projectService.createProject(project)
    }

    public func updateProject(_ project: ProjectValue) async throws {
        try await projectService.updateProject(project)
    }

    public func deleteProject(id: String) async throws {
        try await projectService.deleteProject(id: id)
    }

    public func createScheme(_ scheme: SchemeValue) async throws {
        try await schemeService.createScheme(scheme)
    }

    public func updateScheme(_ scheme: SchemeValue) async throws {
        try await schemeService.updateScheme(scheme)
    }

    public func deleteScheme(id: UUID) async throws {
        try await schemeService.deleteScheme(id: id)
    }

    public func createBuild(_ build: BuildModelValue) async throws {
        try await buildService.createBuild(build)
    }

    public func updateBuild(_ build: BuildModelValue) async throws {
        try await buildService.updateBuild(build)
    }

    public func deleteBuild(id: UUID) async throws {
        try await buildService.deleteBuild(id: id)
    }

    public func createBuildLog(_ log: BuildLogValue) async throws {
        try await logService.createBuildLog(log)
    }

    public func deleteBuildLogs(buildId: UUID) async throws {
        try await logService.deleteBuildLogs(buildId: buildId)
    }

    public func createCrashLog(_ crashLog: CrashLogValue) async throws {
        try await logService.createCrashLog(crashLog)
    }

    public func updateCrashLog(_ crashLog: CrashLogValue) async throws {
        try await logService.updateCrashLog(crashLog)
    }

    public func deleteCrashLog(id: String) async throws {
        try await logService.deleteCrashLog(id: id)
    }
    
    // MARK: - Build Job Operations (Step 6) - LOCAL IMPLEMENTATION
    
    /// Create a build job using XcodeBuildJob - LOCAL ONLY
    public func createBuildJob(payload: XcodeBuildPayload) async throws {
        try await buildJobManager.createBuildJob(payload: payload)
    }
    
    /// Start a build job and return progress stream - LOCAL CLI EXECUTION
    public func startBuildJob(buildId: UUID) -> some AsyncSequence<BuildProgressUpdate, Error> {
        return AsyncThrowingStream<BuildProgressUpdate, Error> { continuation in
            Task {
                let stream = await buildJobManager.startBuildJob(buildId: buildId)
                for try await update in stream {
                    continuation.yield(update)
                }
                continuation.finish()
            }
        }
    }
    
    /// Cancel a running build job - LOCAL CLI CANCELLATION
    public func cancelBuildJob(buildId: UUID) async throws {
        await buildJobManager.cancelBuildJob(buildId: buildId)
    }
    
    /// Delete a build job - LOCAL CLEANUP
    public func deleteBuildJob(buildId: UUID) async throws {
        try await buildJobManager.deleteBuildJob(buildId: buildId)
    }
    
    /// Get build job status - query from database or in-memory tracking
    public func getBuildJobStatus(buildId: UUID) async throws -> BuildJobStatus? {
        // For now, return nil - this will be implemented when we have proper state tracking
        // The synchronous protocol requirement makes it difficult to use the actor
        return nil
    }
    
    // MARK: - Git Repository Operations (LOCAL IMPLEMENTATION)
    
    /// Fetch available versions/tags from a remote repository
    public func fetchVersions(remoteURL: URL) async throws -> [Version] {
        return try await GitCommand.fetchVersions(remoteURL: remoteURL)
    }
    
    /// Fetch available branches from a remote repository
    public func fetchBranches(remoteURL: URL) async throws -> [GitBranch] {
        return try await GitCommand.fetchBranches(remoteURL: remoteURL)
    }
}

// MARK: - Reactive Observation Methods (Backend Service Layer)

public extension LocalBackendService {

    func streamAllProjectIds() -> some AsyncSequence<[String], Never> {
        @FetchAll(
            Project.all
                .order(by: \.createdAt)
                .select(\.bundleIdentifier)
        ) var projectIds: [String]

        return $projectIds.publisher.values
    }

    func streamProject(id: String) -> some AsyncSequence<ProjectValue?, Never> {
        @FetchOne(
            Project
                .where { $0.bundleIdentifier == id }
                .order(by: \.createdAt)
        ) var project: Project?

        return $project.publisher.values
            .map { dbProject -> ProjectValue? in
                guard let dbProject = dbProject else { return nil }
                return dbProject.toValue()
            }
    }

    func streamProjectVersionStrings() -> some AsyncSequence<[String: [String]], Never> {
        @Fetch(ProjectVersionStringsRequest()) var projectVersions = ProjectVersionStringsRequest.Value()
        return $projectVersions.publisher.values.map(\.versionsByProject)
    }

    func streamSchemeIds(projectId: String) -> some AsyncSequence<[UUID], Never> {
        @FetchAll(
            Scheme
                .where { $0.projectBundleIdentifier == projectId }
                .order(by: \.order)
                .select(\.id)
        ) var schemeIds: [UUID]

        return $schemeIds.publisher.values
    }

    func streamScheme(id: UUID) -> some AsyncSequence<SchemeValue?, Never> {
        @FetchOne(
            Scheme
                .where { $0.id == id }
        ) var scheme: Scheme?

        return $scheme.publisher.values
            .map { dbScheme -> SchemeValue? in
                guard let dbScheme = dbScheme else { return nil }
                return dbScheme.toValue()
            }
    }

    func streamScheme(buildId: UUID) -> some AsyncSequence<SchemeValue?, Never> {
        @Fetch(SchemeByBuildIdRequest(buildId: buildId)) var scheme: SchemeValue? = nil
        return $scheme.publisher.values
    }

    func streamSchemes(projectId: String) -> some AsyncSequence<[SchemeValue], Never> {
        @FetchAll(
            Scheme
                .where { $0.projectBundleIdentifier == projectId }
                .order(by: \.order)
        ) var schemes: [Scheme]

        return $schemes.publisher.values
            .map { dbSchemes -> [SchemeValue] in
                dbSchemes.map { dbScheme in
                    dbScheme.toValue()
                }
            }
    }

    func streamBuildIds(schemeIds: [UUID], versionString: String?) -> some AsyncSequence<[UUID], Never> {
        @FetchAll(
            BuildModel.all
                .where { $0.schemeId.in(schemeIds) }
                .where { versionString == nil || $0.versionString == versionString }
                .order { $0.createdAt.desc() }
                .select(\.id)
        ) var buildIds: [UUID]

        return $buildIds.publisher.values
    }

    func streamBuild(id: UUID) -> some AsyncSequence<BuildModelValue?, Never> {
        @FetchOne(
            BuildModel
                .where { $0.id == id }
        ) var build: BuildModel?

        return $build.publisher.values
            .map { dbBuild -> BuildModelValue? in
                guard let dbBuild = dbBuild else { return nil }
                return dbBuild.toValue()
            }
    }

    func streamLatestBuilds(projectId: String, limit: Int) -> some AsyncSequence<[BuildModelValue], Never> {
        @Fetch(LatestBuildsRequest(projectId: projectId, limit: limit)) var latestBuilds = LatestBuildsRequest.Value()
        return $latestBuilds.publisher.values.map(\.builds)
    }

    func streamBuildLogIds(buildId: UUID, includeDebug: Bool, category: String?) -> some AsyncSequence<[UUID], Never> {
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

    func streamBuildLog(id: UUID) -> some AsyncSequence<BuildLogValue?, Never> {
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

    func streamCrashLogIds(buildId: UUID) -> some AsyncSequence<[String], Never> {
        @FetchAll(
            CrashLog
                .where { $0.buildId == buildId }
                .order { $0.createdAt.desc() }
                .select(\.incidentIdentifier)
        ) var crashLogIds: [String]

        return $crashLogIds.publisher.values
    }

    func streamCrashLog(id: String) -> some AsyncSequence<CrashLogValue?, Never> {
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

    func streamProjectDetail(id: String) -> some AsyncSequence<ProjectDetailData?, Never> {
        @Fetch(ProjectDetailRequest(id: id)) 
        var projectDetail: ProjectDetailRequest.Result? = nil

        return $projectDetail.publisher.values.compactMap { result -> ProjectDetailData? in
            guard let result = result else { return nil }
            let projectValue = result.project.toValue()
            return ProjectDetailData(
                project: projectValue,
                schemeIds: result.schemes.map(\.id),
                recentBuildIds: result.builds.prefix(5).map(\.id)
            )
        }
    }

    func streamBuildVersionStrings(projectId: String) -> some AsyncSequence<[String], Never> {
        @Fetch(BuildVersionStringsRequest(projectId: projectId)) 
        var buildVersions = BuildVersionStringsRequest.Value()
        return $buildVersions.publisher.values
    }
}

// MARK: - FetchKeyRequest Implementations

/// Custom FetchKeyRequest for fetching project version strings with all related data in a single transaction
private struct ProjectVersionStringsRequest: FetchKeyRequest {
    struct Value {
        let versionsByProject: [String: [String]]

        init() {
            self.versionsByProject = [:]
        }

        init(versionsByProject: [String: [String]]) {
            self.versionsByProject = versionsByProject
        }
    }

    func fetch(_ db: Database) throws -> Value {
        let projects = try Project.all.fetchAll(db)
        var result: [String: [String]] = [:]

        for project in projects {
            let schemes = try Scheme
                .where { $0.projectBundleIdentifier == project.bundleIdentifier }
                .fetchAll(db)

            let schemeIds = schemes.map(\.id)
            let builds = try BuildModel
                .where { $0.schemeId.in(schemeIds) }
                .fetchAll(db)

            let versions = Array(Set(builds.map(\.versionString))).sorted()
            result[project.bundleIdentifier] = versions
        }

        return Value(versionsByProject: result)
    }
}

/// Custom FetchKeyRequest for fetching latest builds for a project with all data in a single transaction
private struct LatestBuildsRequest: FetchKeyRequest {
    let projectId: String
    let limit: Int

    struct Value {
        let builds: [BuildModelValue]

        init() {
            self.builds = []
        }

        init(builds: [BuildModelValue]) {
            self.builds = builds
        }
    }

    func fetch(_ db: Database) throws -> Value {
        // Get schemes for the project
        let schemes = try Scheme
            .where { $0.projectBundleIdentifier == projectId }
            .fetchAll(db)

        let schemeIds = schemes.map(\.id)

        // Get latest builds
        let builds = try BuildModel
            .where { $0.schemeId.in(schemeIds) }
            .order { $0.createdAt.desc() }
            .limit(limit)
            .fetchAll(db)

        let buildModelValues = builds.map { build in
            build.toValue()
        }

        return Value(builds: buildModelValues)
    }
}

/// Custom FetchKeyRequest for fetching build version strings for a project in a single transaction
private struct BuildVersionStringsRequest: FetchKeyRequest {
    let projectId: String

    func fetch(_ db: Database) throws -> [String] {
        let schemes = try Scheme
            .where { $0.projectBundleIdentifier == projectId }
            .fetchAll(db)

        let schemeIds = schemes.map(\.id)
        let builds = try BuildModel
            .where { $0.schemeId.in(schemeIds) }
            .fetchAll(db)

        let versions = Array(Set(builds.map(\.versionString))).sorted(by: >)
        return versions
    }
}

/// Custom FetchKeyRequest for fetching scheme by build ID
private struct SchemeByBuildIdRequest: FetchKeyRequest {
    let buildId: UUID
    
    func fetch(_ db: Database) throws -> SchemeValue? {
        // Get the build to find its scheme ID
        guard let build = try BuildModel.where({ $0.id == buildId }).fetchOne(db) else {
            return nil
        }
        
        // Get the scheme
        let scheme = try Scheme
            .where { $0.id == build.schemeId }
            .fetchOne(db)
        
        return scheme?.toValue()
    }
}
