import Foundation
import SharingGRDB
import GRDB
import Dependencies
import Core

public struct LocalBackendService: BackendService {
    @Dependency(\.defaultDatabase) var db
    @Dependency(\.localBuildJobManager) var buildJobManager

    public init() {
        // Dependencies injection handles database access and build job management
    }

    // MARK: - Write Operations

    public func createProject(_ project: ProjectValue) async throws {
        try await db.write { db in
            let dbProject = Project(
                bundleIdentifier: project.bundleIdentifier,
                createdAt: project.createdAt,
                name: project.name,
                displayName: project.displayName,
                gitRepoURL: project.gitRepoURL,
                xcodeprojName: project.xcodeprojName,
                workingDirectoryURL: project.workingDirectoryURL
            )

            try Project.insert { dbProject }.execute(db)
        }
    }

    public func updateProject(_ project: ProjectValue) async throws {
        try await db.write { db in
            try Project
                .where { $0.bundleIdentifier == project.bundleIdentifier }
                .update { 
                    $0.bundleIdentifier = project.bundleIdentifier
                    $0.createdAt = project.createdAt
                    $0.name = project.name
                    $0.displayName = project.displayName
                    $0.gitRepoURL = project.gitRepoURL
                    $0.xcodeprojName = project.xcodeprojName
                    $0.workingDirectoryURL = project.workingDirectoryURL
                 }
                .execute(db)
        }
    }

    public func deleteProject(id: String) async throws {
        try await db.write { db in
            _ = try Project
                .where { $0.bundleIdentifier == id }
                .delete()
                .execute(db)
        }
    }

    public func createScheme(_ scheme: SchemeValue) async throws {
        try await db.write { db in
            let dbScheme = Scheme(
                id: scheme.id,
                projectBundleIdentifier: scheme.projectBundleIdentifier,
                name: scheme.name,
                platforms: scheme.platforms,
                order: scheme.order
            )
            try Scheme.insert { dbScheme }.execute(db)
        }
    }

    public func updateScheme(_ scheme: SchemeValue) async throws {
        try await db.write { db in
            let dbScheme = Scheme(
                id: scheme.id,
                projectBundleIdentifier: scheme.projectBundleIdentifier,
                name: scheme.name,
                platforms: scheme.platforms,
                order: scheme.order
            )
            try Scheme.update(dbScheme).execute(db)
        }
    }

    public func deleteScheme(id: UUID) async throws {
        try await db.write { db in
            _ = try Scheme
                .where { $0.id == id }
                .delete()
                .execute(db)
        }
    }

    public func createBuild(_ build: BuildModelValue) async throws {
        try await db.write { db in
            let version = Version(version: build.versionString, buildNumber: build.buildNumber, commitHash: build.commitHash)
            let deviceMetadata = build.deviceMetadata

            let dbBuild = BuildModel(
                id: build.id,
                schemeId: build.schemeId,
                version: version,
                createdAt: build.createdAt,
                startDate: build.startDate,
                endDate: build.endDate,
                exportOptions: build.exportOptions,
                commitHash: build.commitHash,
                status: BuildStatus(rawValue: build.status.rawValue) ?? .queued,
                progress: build.progress,
                deviceMetadata: deviceMetadata
            )
            try BuildModel.insert { dbBuild }.execute(db)
        }
    }

    public func updateBuild(_ build: BuildModelValue) async throws {
        try await db.write { db in
            let version = Version(version: build.versionString, buildNumber: build.buildNumber, commitHash: build.commitHash)
            let deviceMetadata = build.deviceMetadata
            
            let dbBuild = BuildModel(
                id: build.id,
                schemeId: build.schemeId,
                version: version,
                createdAt: build.createdAt,
                startDate: build.startDate,
                endDate: build.endDate,
                exportOptions: build.exportOptions,
                commitHash: build.commitHash,
                status: BuildStatus(rawValue: build.status.rawValue) ?? .queued,
                progress: build.progress,
                deviceMetadata: deviceMetadata
            )
            try BuildModel.update(dbBuild).execute(db)
        }
    }

    public func deleteBuild(id: UUID) async throws {
        try await db.write { db in
            _ = try BuildModel
                .where { $0.id == id }
                .delete()
                .execute(db)
        }
    }

    public func createBuildLog(_ log: BuildLogValue) async throws {
        try await db.write { db in
            let level = BuildLog.Level(rawValue: log.level.rawValue) ?? .info
            let dbLog = BuildLog(
                id: log.id,
                buildId: log.buildId,
                category: log.category,
                content: log.content,
                level: level
            )
            try BuildLog.insert { dbLog }.execute(db)
        }
    }

    public func deleteBuildLogs(buildId: UUID) async throws {
        try await db.write { db in
            _ = try BuildLog
                .where { $0.buildId == buildId }
                .delete()
                .execute(db)
        }
    }

    public func createCrashLog(_ crashLog: CrashLogValue) async throws {
        try await db.write { db in
            let role = CrashLogRole(rawValue: crashLog.role.rawValue) ?? .foreground
            let priority = CrashLogPriority(rawValue: crashLog.priority.rawValue) ?? .medium
            
            let dbCrashLog = CrashLog(
                incidentIdentifier: crashLog.incidentIdentifier,
                isMainThread: crashLog.isMainThread,
                createdAt: crashLog.createdAt,
                buildId: crashLog.buildId,
                content: crashLog.content,
                hardwareModel: crashLog.hardwareModel,
                process: crashLog.process,
                role: role,
                dateTime: crashLog.dateTime,
                launchTime: crashLog.launchTime,
                osVersion: crashLog.osVersion,
                note: crashLog.note,
                fixed: crashLog.fixed,
                priority: priority
            )
            try CrashLog.insert { dbCrashLog }.execute(db)
        }
    }

    public func updateCrashLog(_ crashLog: CrashLogValue) async throws {
        try await db.write { db in
            let role = CrashLogRole(rawValue: crashLog.role.rawValue) ?? .foreground
            let priority = CrashLogPriority(rawValue: crashLog.priority.rawValue) ?? .medium
            
            let dbCrashLog = CrashLog(
                incidentIdentifier: crashLog.incidentIdentifier,
                isMainThread: crashLog.isMainThread,
                createdAt: crashLog.createdAt,
                buildId: crashLog.buildId,
                content: crashLog.content,
                hardwareModel: crashLog.hardwareModel,
                process: crashLog.process,
                role: role,
                dateTime: crashLog.dateTime,
                launchTime: crashLog.launchTime,
                osVersion: crashLog.osVersion,
                note: crashLog.note,
                fixed: crashLog.fixed,
                priority: priority
            )
            try CrashLog.update(dbCrashLog).execute(db)
        }
    }

    public func deleteCrashLog(id: String) async throws {
        try await db.write { db in
            _ = try CrashLog
                .where { $0.incidentIdentifier == id }
                .delete()
                .execute(db)
        }
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
    public func cancelBuildJob(buildId: UUID) async {
        await buildJobManager.cancelBuildJob(buildId: buildId)
    }
    
    /// Delete a build job - LOCAL CLEANUP
    public func deleteBuildJob(buildId: UUID) async throws {
        try await buildJobManager.deleteBuildJob(buildId: buildId)
    }
    
    /// Get build job status - query from database or in-memory tracking
    public func getBuildJobStatus(buildId: UUID) -> BuildJobStatus? {
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
                return ProjectValue(
                    bundleIdentifier: dbProject.bundleIdentifier,
                    name: dbProject.name,
                    displayName: dbProject.displayName,
                    gitRepoURL: dbProject.gitRepoURL,
                    xcodeprojName: dbProject.xcodeprojName,
                    workingDirectoryURL: dbProject.workingDirectoryURL,
                    createdAt: dbProject.createdAt
                )
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
                return SchemeValue(
                    id: dbScheme.id,
                    projectBundleIdentifier: dbScheme.projectBundleIdentifier,
                    name: dbScheme.name,
                    platforms: dbScheme.platforms,
                    order: dbScheme.order
                )
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
                return BuildModelValue(
                    id: dbBuild.id,
                    schemeId: dbBuild.schemeId,
                    version: dbBuild.version,
                    createdAt: dbBuild.createdAt,
                    startDate: dbBuild.startDate,
                    endDate: dbBuild.endDate,
                    exportOptions: dbBuild.exportOptions,
                    status: Core.BuildStatus(rawValue: dbBuild.status.rawValue) ?? .queued,
                    progress: dbBuild.progress,
                    deviceMetadata: dbBuild.deviceMetadata,
                    osVersion: dbBuild.osVersion,
                    memory: dbBuild.memory,
                    processor: dbBuild.processor
                )
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
                .where { includeDebug || $0.level != BuildLog.Level.debug }
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
                return BuildLogValue(
                    id: dbLog.id,
                    buildId: dbLog.buildId,
                    category: dbLog.category,
                    level: Core.BuildLogLevel(rawValue: dbLog.level.rawValue) ?? .info,
                    content: dbLog.content,
                    createdAt: dbLog.createdAt
                )
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
                return CrashLogValue(
                    incidentIdentifier: dbCrashLog.incidentIdentifier,
                    isMainThread: dbCrashLog.isMainThread,
                    createdAt: dbCrashLog.createdAt,
                    buildId: dbCrashLog.buildId,
                    content: dbCrashLog.content,
                    hardwareModel: dbCrashLog.hardwareModel,
                    process: dbCrashLog.process,
                    role: Core.CrashLogRole(rawValue: dbCrashLog.role.rawValue) ?? .foreground,
                    dateTime: dbCrashLog.dateTime,
                    launchTime: dbCrashLog.launchTime,
                    osVersion: dbCrashLog.osVersion,
                    note: dbCrashLog.note,
                    fixed: dbCrashLog.fixed,
                    priority: Core.CrashLogPriority(rawValue: dbCrashLog.priority.rawValue) ?? .medium
                )
            }
    }

    func streamProjectDetail(id: String) -> some AsyncSequence<ProjectDetailData?, Never> {
        @Fetch(ProjectDetailRequest(id: id)) 
        var projectDetail: ProjectDetailRequest.Result? = nil

        return $projectDetail.publisher.values.compactMap { result -> ProjectDetailData? in
            guard let result = result else { return nil }
            let projectValue = ProjectValue(
                bundleIdentifier: result.project.bundleIdentifier,
                name: result.project.name,
                displayName: result.project.displayName,
                gitRepoURL: result.project.gitRepoURL,
                xcodeprojName: result.project.xcodeprojName,
                workingDirectoryURL: result.project.workingDirectoryURL,
                createdAt: result.project.createdAt
            )
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
            BuildModelValue(
                id: build.id,
                schemeId: build.schemeId,
                version: build.version,
                createdAt: build.createdAt,
                startDate: build.startDate,
                endDate: build.endDate,
                exportOptions: build.exportOptions,
                status: Core.BuildStatus(rawValue: build.status.rawValue) ?? .queued,
                progress: build.progress,
                deviceMetadata: build.deviceMetadata,
                osVersion: build.osVersion,
                memory: build.memory,
                processor: build.processor
            )
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
