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
    
    // Internal streaming services - not exposed in public API
    @Dependency(\.projectStreamingService) private var projectStreamingService
    @Dependency(\.schemeStreamingService) private var schemeStreamingService
    @Dependency(\.buildStreamingService) private var buildStreamingService
    @Dependency(\.logStreamingService) private var logStreamingService

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
        return projectStreamingService.streamAllProjectIds()
    }

    func streamProject(id: String) -> some AsyncSequence<ProjectValue?, Never> {
        return projectStreamingService.streamProject(id: id)
    }

    func streamProjectVersionStrings() -> some AsyncSequence<[String: [String]], Never> {
        return projectStreamingService.streamProjectVersionStrings()
    }

    func streamSchemeIds(projectId: String) -> some AsyncSequence<[UUID], Never> {
        return schemeStreamingService.streamSchemeIds(projectId: projectId)
    }

    func streamScheme(id: UUID) -> some AsyncSequence<SchemeValue?, Never> {
        return schemeStreamingService.streamScheme(id: id)
    }

    func streamScheme(buildId: UUID) -> some AsyncSequence<SchemeValue?, Never> {
        return schemeStreamingService.streamScheme(buildId: buildId)
    }

    func streamSchemes(projectId: String) -> some AsyncSequence<[SchemeValue], Never> {
        return schemeStreamingService.streamSchemes(projectId: projectId)
    }

    func streamBuildIds(schemeIds: [UUID], versionString: String?) -> some AsyncSequence<[UUID], Never> {
        return schemeStreamingService.streamBuildIds(schemeIds: schemeIds, versionString: versionString)
    }

    func streamBuild(id: UUID) -> some AsyncSequence<BuildModelValue?, Never> {
        return buildStreamingService.streamBuild(id: id)
    }

    func streamLatestBuilds(projectId: String, limit: Int) -> some AsyncSequence<[BuildModelValue], Never> {
        return buildStreamingService.streamLatestBuilds(projectId: projectId, limit: limit)
    }

    func streamBuildLogIds(buildId: UUID, includeDebug: Bool, category: String?) -> some AsyncSequence<[UUID], Never> {
        return logStreamingService.streamBuildLogIds(buildId: buildId, includeDebug: includeDebug, category: category)
    }

    func streamBuildLog(id: UUID) -> some AsyncSequence<BuildLogValue?, Never> {
        return logStreamingService.streamBuildLog(id: id)
    }

    func streamCrashLogIds(buildId: UUID) -> some AsyncSequence<[String], Never> {
        return logStreamingService.streamCrashLogIds(buildId: buildId)
    }

    func streamCrashLog(id: String) -> some AsyncSequence<CrashLogValue?, Never> {
        return logStreamingService.streamCrashLog(id: id)
    }

    func streamProjectDetail(id: String) -> some AsyncSequence<ProjectDetailData?, Never> {
        return projectStreamingService.streamProjectDetail(id: id)
    }

    func streamBuildVersionStrings(projectId: String) -> some AsyncSequence<[String], Never> {
        return buildStreamingService.streamBuildVersionStrings(projectId: projectId)
    }
}
