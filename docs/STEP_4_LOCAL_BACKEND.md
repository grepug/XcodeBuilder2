# Step 4: Local Backend Implementation

**Goal**: Create the SharingGRDB-powered local backend service that implements the BackendService protocol and integrates with the Step 3 BackendQuery system.

## Architecture Review

This step builds on:

- **Step 2**: Backend abstraction layer with Core (backend-agnostic) and LocalBackend (SharingGRDB implementation) targets
- **Step 3**: Universal BackendQuery<T> SharingKey system for type-safe queries

### Current State Analysis

✅ **Package Structure**: Already configured with Core and LocalBackend targets  
✅ **Backend Protocol**: BackendService protocol with AsyncSequence-based reactive APIs  
✅ **SharingGRDB Models**: @Table models already exist in LocalBackend/Models/  
✅ **Value Types**: Backend-agnostic value types in Core/Services/BackendModels.swift  
✅ **Query System**: BackendQuery<T> universal SharingKey system ready for integration

### Implementation Focus

- **LocalBackendService**: Concrete BackendService implementation using SharingGRDB
- **Database Setup**: Migration system with proper schema and indexes
- **Query Integration**: Bridge BackendQuery<T> with SharingGRDB FetchKey pattern
- **Reactive Updates**: AsyncSequence implementations using SharingGRDB ValueObservation

## Files to Create/Update

### 4.1 Database Migration System

**File**: `Packages/Lib/Sources/LocalBackend/Database/DatabaseManager.swift`

**File**: `Packages/Lib/Sources/LocalBackend/Database/DatabaseManager.swift`

```swift
import Foundation
import SharingGRDB
import GRDB
import Core

public struct DatabaseManager {

    public static func setupDatabase() throws -> DatabaseWriter {
        let dbURL = Self.databaseURL()
        let dbWriter = try DatabasePool(path: dbURL.path())

        try Self.runMigrations(dbWriter)
        return dbWriter
    }

    public static func setupInMemoryDatabase() throws -> DatabaseWriter {
        let dbWriter = try DatabaseQueue()
        try Self.runMigrations(dbWriter)
        return dbWriter
    }

    public static func runMigrations(_ dbWriter: DatabaseWriter) throws {
        var migrator = DatabaseMigrator()

        migrator.registerMigration("v1.0") { db in
            // Projects table
            try #sql(
                """
                CREATE TABLE "projects" (
                    "bundle_identifier" TEXT PRIMARY KEY NOT NULL,
                    "name" TEXT NOT NULL,
                    "display_name" TEXT NOT NULL,
                    "git_repo_url" TEXT NOT NULL,
                    "xcodeproj_name" TEXT NOT NULL,
                    "working_directory" TEXT NOT NULL,
                    "created_at" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
                )
                """
            ).execute(db)

            // Schemes table
            try #sql(
                """
                CREATE TABLE "schemes" (
                    "id" TEXT PRIMARY KEY NOT NULL,
                    "name" TEXT NOT NULL,
                    "platforms" TEXT NOT NULL,
                    "project_bundle_identifier" TEXT NOT NULL,
                    "order_index" INTEGER NOT NULL,
                    FOREIGN KEY("project_bundle_identifier") REFERENCES "projects"("bundle_identifier") ON DELETE CASCADE
                )
                """
            ).execute(db)

            // Builds table
            try #sql(
                """
                CREATE TABLE "builds" (
                    "id" TEXT PRIMARY KEY NOT NULL,
                    "scheme_id" TEXT NOT NULL,
                    "version_string" TEXT NOT NULL,
                    "build_number" INTEGER NOT NULL,
                    "created_at" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
                    "start_date" DATETIME,
                    "end_date" DATETIME,
                    "export_options" TEXT NOT NULL,
                    "status" TEXT NOT NULL DEFAULT 'queued',
                    "progress" REAL NOT NULL DEFAULT 0,
                    "commit_hash" TEXT NOT NULL DEFAULT '',
                    "device_metadata" TEXT NOT NULL DEFAULT '',
                    "os_version" TEXT NOT NULL DEFAULT '',
                    "memory" INTEGER NOT NULL DEFAULT 0,
                    "processor" TEXT NOT NULL DEFAULT '',
                    FOREIGN KEY("scheme_id") REFERENCES "schemes"("id") ON DELETE CASCADE
                )
                """
            ).execute(db)

            // Build logs table
            try #sql(
                """
                CREATE TABLE "buildLogs" (
                    "id" TEXT PRIMARY KEY NOT NULL,
                    "build_id" TEXT NOT NULL,
                    "category" TEXT,
                    "level" TEXT NOT NULL,
                    "log_content" TEXT NOT NULL,
                    "created_at" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
                    FOREIGN KEY("build_id") REFERENCES "builds"("id") ON DELETE CASCADE
                )
                """
            ).execute(db)

            // Crash logs table
            try #sql(
                """
                CREATE TABLE "crashLogs" (
                    "incident_identifier" TEXT PRIMARY KEY NOT NULL,
                    "is_main_thread" INTEGER NOT NULL,
                    "created_at" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
                    "build_id" TEXT NOT NULL,
                    "content" TEXT NOT NULL,
                    "hardware_model" TEXT NOT NULL,
                    "process" TEXT NOT NULL,
                    "role" TEXT NOT NULL,
                    "date_time" DATETIME NOT NULL,
                    "launch_time" DATETIME NOT NULL,
                    "os_version" TEXT NOT NULL,
                    "note" TEXT NOT NULL DEFAULT '',
                    "fixed" INTEGER NOT NULL DEFAULT 0,
                    "priority" TEXT NOT NULL DEFAULT 'medium',
                    FOREIGN KEY("build_id") REFERENCES "builds"("id") ON DELETE CASCADE
                )
                """
            ).execute(db)
        }

        migrator.registerMigration("v1.1 - Add indexes") { db in
            try #sql("CREATE INDEX IF NOT EXISTS idx_schemes_project ON schemes(project_bundle_identifier)").execute(db)
            try #sql("CREATE INDEX IF NOT EXISTS idx_builds_scheme ON builds(scheme_id)").execute(db)
            try #sql("CREATE INDEX IF NOT EXISTS idx_builds_version ON builds(version_string)").execute(db)
            try #sql("CREATE INDEX IF NOT EXISTS idx_builds_created ON builds(created_at)").execute(db)
            try #sql("CREATE INDEX IF NOT EXISTS idx_builds_status ON builds(status)").execute(db)
            try #sql("CREATE INDEX IF NOT EXISTS idx_buildLogs_build ON buildLogs(build_id)").execute(db)
            try #sql("CREATE INDEX IF NOT EXISTS idx_buildLogs_level ON buildLogs(level)").execute(db)
            try #sql("CREATE INDEX IF NOT EXISTS idx_crashLogs_build ON crashLogs(build_id)").execute(db)
            try #sql("CREATE INDEX IF NOT EXISTS idx_crashLogs_fixed ON crashLogs(fixed)").execute(db)
        }

        try migrator.migrate(dbWriter)
    }

    private static func databaseURL() -> URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDir = appSupport.appendingPathComponent("XcodeBuilder2", isDirectory: true)
        try? FileManager.default.createDirectory(at: appDir, withIntermediateDirectories: true)
        return appDir.appendingPathComponent("database.sqlite")
    }
}
```

### 4.2 Local Backend Service Implementation

**File**: `Packages/Lib/Sources/LocalBackend/LocalBackendService.swift`

```swift
import Foundation
import SharingGRDB
import GRDB
import Dependencies
import Core

public struct LocalBackendService: BackendService {
    @Dependency(\.defaultDatabase) var db

    public init() {
        // Dependencies injection handles database access
    }

    // MARK: - Write Operations

    public func createProject(_ project: ProjectValue) async throws {
        try await db.write { db in
            let dbProject = Project(
                bundleIdentifier: project.bundleIdentifier,
                name: project.name,
                displayName: project.displayName,
                gitRepoURL: project.gitRepoURL,
                xcodeprojName: project.xcodeprojName,
                workingDirectoryURL: project.workingDirectoryURL,
                createdAt: project.createdAt
            )
            try dbProject.insert(db)
        }
    }

    public func updateProject(_ project: ProjectValue) async throws {
        try await db.write { db in
            let dbProject = Project(
                bundleIdentifier: project.bundleIdentifier,
                name: project.name,
                displayName: project.displayName,
                gitRepoURL: project.gitRepoURL,
                xcodeprojName: project.xcodeprojName,
                workingDirectoryURL: project.workingDirectoryURL,
                createdAt: project.createdAt
            )
            try dbProject.update(db)
        }
    }

    public func deleteProject(id: String) async throws {
        try await db.write { db in
            try Project
                .where { $0.bundleIdentifier == id }
                .delete(db)
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
            try dbScheme.insert(db)
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
            try dbScheme.update(db)
        }
    }

    public func deleteScheme(id: UUID) async throws {
        try await db.write { db in
            try Scheme
                .where { $0.id == id }
                .delete(db)
        }
    }

    public func createBuild(_ build: BuildModelValue) async throws {
        try await db.write { db in
            let dbBuild = BuildModel(
                id: build.id,
                schemeId: build.schemeId,
                versionString: build.versionString,
                buildNumber: build.buildNumber,
                createdAt: build.createdAt,
                startDate: build.startDate,
                endDate: build.endDate,
                exportOptions: build.exportOptions,
                status: build.status,
                progress: build.progress,
                commitHash: build.commitHash,
                deviceModel: build.deviceMetadata,
                osVersion: build.osVersion,
                memory: build.memory,
                processor: build.processor
            )
            try dbBuild.insert(db)
        }
    }

    public func updateBuild(_ build: BuildModelValue) async throws {
        try await db.write { db in
            let dbBuild = BuildModel(
                id: build.id,
                schemeId: build.schemeId,
                versionString: build.versionString,
                buildNumber: build.buildNumber,
                createdAt: build.createdAt,
                startDate: build.startDate,
                endDate: build.endDate,
                exportOptions: build.exportOptions,
                status: build.status,
                progress: build.progress,
                commitHash: build.commitHash,
                deviceModel: build.deviceMetadata,
                osVersion: build.osVersion,
                memory: build.memory,
                processor: build.processor
            )
            try dbBuild.update(db)
        }
    }

    public func deleteBuild(id: UUID) async throws {
        try await db.write { db in
            try BuildModel
                .where { $0.id == id }
                .delete(db)
        }
    }

    public func createBuildLog(_ log: BuildLogValue) async throws {
        try await db.write { db in
            let dbLog = BuildLog(
                id: log.id,
                buildId: log.buildId,
                category: log.category,
                content: log.content,
                level: log.level
            )
            try dbLog.insert(db)
        }
    }

    public func deleteBuildLogs(buildId: UUID) async throws {
        try await db.write { db in
            try BuildLog
                .where { $0.buildId == buildId }
                .delete(db)
        }
    }

    public func createCrashLog(_ crashLog: CrashLogValue) async throws {
        try await db.write { db in
            let dbCrashLog = CrashLog(
                incidentIdentifier: crashLog.incidentIdentifier,
                isMainThread: crashLog.isMainThread,
                createdAt: crashLog.createdAt,
                buildId: crashLog.buildId,
                content: crashLog.content,
                hardwareModel: crashLog.hardwareModel,
                process: crashLog.process,
                role: crashLog.role,
                dateTime: crashLog.dateTime,
                launchTime: crashLog.launchTime,
                osVersion: crashLog.osVersion,
                note: crashLog.note,
                fixed: crashLog.fixed,
                priority: crashLog.priority
            )
            try dbCrashLog.insert(db)
        }
    }

    public func updateCrashLog(_ crashLog: CrashLogValue) async throws {
        try await db.write { db in
            let dbCrashLog = CrashLog(
                incidentIdentifier: crashLog.incidentIdentifier,
                isMainThread: crashLog.isMainThread,
                createdAt: crashLog.createdAt,
                buildId: crashLog.buildId,
                content: crashLog.content,
                hardwareModel: crashLog.hardwareModel,
                process: crashLog.process,
                role: crashLog.role,
                dateTime: crashLog.dateTime,
                launchTime: crashLog.launchTime,
                osVersion: crashLog.osVersion,
                note: crashLog.note,
                fixed: crashLog.fixed,
                priority: crashLog.priority
            )
            try dbCrashLog.update(db)
        }
    }

    public func deleteCrashLog(id: String) async throws {
        try await db.write { db in
            try CrashLog
                .where { $0.incidentIdentifier == id }
                .delete(db)
        }
    }
}

// MARK: - Reactive Observation Methods (Backend Service Layer)

// Note: LocalBackendService uses modern @Fetch/@FetchAll/@FetchOne property wrappers
// with publishers.values for reactive AsyncSequence APIs in backend services.
// This approach provides type-safe queries with StructuredQueries syntax (.where/.order/.select)
// and seamless AsyncSequence conversion using the publisher.values pattern.

public extension LocalBackendService {

    func streamAllProjectIds() -> some AsyncSequence<[String]> {
        @FetchAll(
            Project.all
                .order { $0.createdAt.desc }
                .select(\.bundleIdentifier)
        ) var projectIds: [String]

        return $projectIds.publisher.values
    }

    func streamProject(id: String) -> some AsyncSequence<ProjectValue?> {
        @FetchOne(
            Project
                .where { $0.bundleIdentifier == id }
                .order { $0.createdAt.desc }
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

    func streamProjectVersionStrings() -> some AsyncSequence<[String: [String]]> {
        @Fetch(ProjectVersionStringsRequest()) var projectVersions = ProjectVersionStringsRequest.Value()
        return $projectVersions.publisher.values.map(\.versionsByProject)
    }

    func streamSchemeIds(projectId: String) -> some AsyncSequence<[UUID]> {
        @FetchAll(
            Scheme
                .where { $0.projectBundleIdentifier == projectId }
                .order { $0.order }
                .select(\.id)
        ) var schemeIds: [UUID]

        return $schemeIds.publisher.values
    }

    func streamScheme(id: UUID) -> some AsyncSequence<SchemeValue?> {
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

    func streamBuildIds(schemeIds: [UUID], versionString: String?) -> some AsyncSequence<[UUID]> {
        @FetchAll(
            BuildModel.all
                .where { $0.schemeId.in(schemeIds) }
                .where { versionString == nil || $0.versionString == versionString }
                .order { $0.createdAt.desc }
                .select(\.id)
        ) var buildIds: [UUID]

        return $buildIds.publisher.values
    }

    func streamBuild(id: UUID) -> some AsyncSequence<BuildModelValue?> {
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
                    versionString: dbBuild.versionString,
                    buildNumber: dbBuild.buildNumber,
                    createdAt: dbBuild.createdAt,
                    startDate: dbBuild.startDate,
                    endDate: dbBuild.endDate,
                    exportOptions: dbBuild.exportOptions,
                    status: dbBuild.status,
                    progress: dbBuild.progress,
                    commitHash: dbBuild.commitHash,
                    deviceMetadata: dbBuild.deviceModel,
                    osVersion: dbBuild.osVersion,
                    memory: dbBuild.memory,
                    processor: dbBuild.processor
                )
            }
    }

    func streamLatestBuilds(projectId: String, limit: Int) -> some AsyncSequence<[BuildModelValue]> {
        @Fetch(LatestBuildsRequest(projectId: projectId, limit: limit)) var latestBuilds = LatestBuildsRequest.Value()
        return $latestBuilds.publisher.values.map(\.builds)
    }

    func streamBuildLogIds(buildId: UUID, includeDebug: Bool, category: String?) -> some AsyncSequence<[UUID]> {
        @FetchAll(
            BuildLog
                .where { $0.buildId == buildId }
                .where { includeDebug || $0.level != "debug" }
                .where { category == nil || $0.category == category }
                .order { $0.createdAt }
                .select(\.id)
        ) var logIds: [UUID]

        return $logIds.publisher.values
    }

    func streamBuildLog(id: UUID) -> some AsyncSequence<BuildLogValue?> {
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
                    level: dbLog.level,
                    content: dbLog.content,
                    createdAt: dbLog.createdAt
                )
            }
    }

    func streamCrashLogIds(buildId: UUID) -> some AsyncSequence<[String]> {
        @FetchAll(
            CrashLog
                .where { $0.buildId == buildId }
                .order { $0.createdAt.desc }
                .select(\.incidentIdentifier)
        ) var crashLogIds: [String]

        return $crashLogIds.publisher.values
    }

    func streamCrashLog(id: String) -> some AsyncSequence<CrashLogValue?> {
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
                    role: dbCrashLog.role,
                    dateTime: dbCrashLog.dateTime,
                    launchTime: dbCrashLog.launchTime,
                    osVersion: dbCrashLog.osVersion,
                    note: dbCrashLog.note,
                    fixed: dbCrashLog.fixed,
                    priority: dbCrashLog.priority
                )
            }
    }

    func streamProjectDetail(id: String) -> some AsyncSequence<ProjectDetailData> {
        @Fetch(ProjectDetailRequest(projectId: id)) var projectDetail = ProjectDetailRequest.Value()
        return $projectDetail.publisher.values.compactMap(\.projectDetailData)
    }

    func streamBuildVersionStrings(projectId: String) -> some AsyncSequence<[String]> {
        @Fetch(BuildVersionStringsRequest(projectId: projectId)) var buildVersions = BuildVersionStringsRequest.Value()
        return $buildVersions.publisher.values.map(\.versions)
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
                versionString: build.versionString,
                buildNumber: build.buildNumber,
                createdAt: build.createdAt,
                startDate: build.startDate,
                endDate: build.endDate,
                exportOptions: build.exportOptions,
                status: build.status,
                progress: build.progress,
                commitHash: build.commitHash,
                deviceMetadata: build.deviceModel,
                osVersion: build.osVersion,
                memory: build.memory,
                processor: build.processor
            )
        }

        return Value(builds: buildModelValues)
    }
}

/// Custom FetchKeyRequest for fetching project detail with all related data in a single transaction
private struct ProjectDetailRequest: FetchKeyRequest {
    let projectId: String

    struct Value {
        let projectDetailData: ProjectDetailData?

        init() {
            self.projectDetailData = nil
        }

        init(projectDetailData: ProjectDetailData?) {
            self.projectDetailData = projectDetailData
        }
    }

    func fetch(_ db: Database) throws -> Value {
        guard let project = try Project
            .where { $0.bundleIdentifier == projectId }
            .fetchOne(db) else { return Value() }

        let projectValue = ProjectValue(
            bundleIdentifier: project.bundleIdentifier,
            name: project.name,
            displayName: project.displayName,
            gitRepoURL: project.gitRepoURL,
            xcodeprojName: project.xcodeprojName,
            workingDirectoryURL: project.workingDirectoryURL,
            createdAt: project.createdAt
        )

        let schemes = try Scheme
            .where { $0.projectBundleIdentifier == projectId }
            .fetchAll(db)
        let schemeIds = schemes.map(\.id)

        let builds = try BuildModel
            .where { $0.schemeId.in(schemeIds) }
            .order { $0.createdAt.desc() }
            .limit(5)
            .fetchAll(db)
        let recentBuildIds = builds.map(\.id)

        let projectDetailData = ProjectDetailData(
            project: projectValue,
            schemeIds: schemeIds,
            recentBuildIds: recentBuildIds
        )

        return Value(projectDetailData: projectDetailData)
    }
}

/// Custom FetchKeyRequest for fetching build version strings for a project in a single transaction
private struct BuildVersionStringsRequest: FetchKeyRequest {
    let projectId: String

    struct Value {
        let versions: [String]

        init() {
            self.versions = []
        }

        init(versions: [String]) {
            self.versions = versions
        }
    }

    func fetch(_ db: Database) throws -> Value {
        let schemes = try Scheme
            .where { $0.projectBundleIdentifier == projectId }
            .fetchAll(db)

        let schemeIds = schemes.map(\.id)
        let builds = try BuildModel
            .where { $0.schemeId.in(schemeIds) }
            .fetchAll(db)

        let versions = Array(Set(builds.map(\.versionString))).sorted(by: >)
        return Value(versions: versions)
    }
}
```

### 4.3 Backend Service Factory

**File**: `Packages/Lib/Sources/LocalBackend/LocalBackendService.swift`

**File**: `Packages/Lib/Sources/LocalBackend/LocalBackendFactory.swift`

```swift
import Foundation
import Core
import GRDB
import Dependencies

/// Factory for creating and configuring database connections for LocalBackendService
public struct LocalBackendFactory {

    public static func setupLiveDatabase() throws -> DatabaseWriter {
        return try DatabaseManager.setupDatabase()
    }

    public static func setupTestDatabase() throws -> DatabaseWriter {
        return try DatabaseManager.setupInMemoryDatabase()
    }

    public static func setupDatabase(at databaseURL: URL) throws -> DatabaseWriter {
        let dbWriter = try DatabasePool(path: databaseURL.path())
        try DatabaseManager.runMigrations(dbWriter)
        return dbWriter
    }
}

// MARK: - Dependencies Integration

#if canImport(Dependencies)
extension DatabaseWriter: DependencyKey {
    public static let liveValue: DatabaseWriter = {
        do {
            return try LocalBackendFactory.setupLiveDatabase()
        } catch {
            fatalError("Failed to create live database: \(error)")
        }
    }()

    public static let testValue: DatabaseWriter = {
        do {
            return try LocalBackendFactory.setupTestDatabase()
        } catch {
            fatalError("Failed to create test database: \(error)")
        }
    }()
}

extension DependencyValues {
    public var defaultDatabase: DatabaseWriter {
        get { self[DatabaseWriter.self] }
        set { self[DatabaseWriter.self] = newValue }
    }
}

struct BackendServiceKey: DependencyKey {
    static let liveValue: any BackendService = LocalBackendService()
    static let testValue: any BackendService = LocalBackendService()
}

extension DependencyValues {
    public var backendService: any BackendService {
        get { self[BackendServiceKey.self] }
        set { self[BackendServiceKey.self] = newValue }
    }
}
#endif
```

## Implementation Checklist

### ✅ Pre-Implementation Status

- [x] **Package Structure**: LocalBackend target exists with SharingGRDB dependencies
- [x] **Backend Protocol**: BackendService protocol defined with AsyncSequence APIs
- [x] **SharingGRDB Models**: @Table models exist in LocalBackend/Models/
- [x] **Core Value Types**: Backend-agnostic value types in Core/Services/BackendModels.swift
- [x] **BackendQuery System**: Universal BackendQuery<T> SharingKey from Step 3

### 📝 Implementation Tasks

#### Phase 1: Database Layer (15 min)

- [ ] Create `DatabaseManager.swift` with migration system
- [ ] Verify existing @Table models align with database schema
- [ ] Test database creation and migration system
- [ ] Test foreign key constraints and indexes

#### Phase 2: Backend Service (25 min)

- [ ] Create `LocalBackendService.swift` implementing BackendService protocol
- [ ] Implement all write operations (create, update, delete)
- [ ] Implement all stream operations using ValueObservation
- [ ] Verify proper conversion between SharingGRDB models and Core value types

#### Phase 3: Factory & Integration (10 min)

- [ ] Create `LocalBackendFactory.swift` for service instantiation
- [ ] Add Dependencies framework integration for DI
- [ ] Update `LocalBackend.swift` main file to export public API

#### Phase 4: Testing (20 min)

- [ ] Create comprehensive Swift Testing test suite
- [ ] Test CRUD operations with real database
- [ ] Test reactive observations with ValueObservation
- [ ] Test database migrations and schema consistency
- [ ] Test error handling and edge cases

### 🏗️ Build Verification

- [ ] **Both targets compile**: `swift build` succeeds
- [ ] **Test target compiles**: All dependencies resolve correctly
- [ ] **No warnings**: Clean compilation with no deprecation warnings
- [ ] **LocalBackend exports**: All public APIs properly exposed

### 🧪 Testing Requirements

#### Critical Test Coverage

- [ ] **Database Operations**: CRUD for all entity types
- [ ] **Reactive Streams**: ValueObservation delivers updates
- [ ] **Data Conversion**: Proper mapping between @Table and Value types
- [ ] **Migration System**: Database schema creation and updates
- [ ] **Error Handling**: Database connection and constraint failures

#### Performance Tests

- [ ] **Query Performance**: Indexes improve query speed
- [ ] **Reactive Performance**: ValueObservation doesn't leak memory
- [ ] **Large Dataset**: Service handles realistic data volumes

## Next Steps Integration

After Step 4 completion:

- **Step 5**: Complete BackendQuery<T> SharedKey protocol conformance
- **Step 6**: Integrate LocalBackendService with BackendQuery observation system
- **Step 7**: Update UI to use reactive @Shared(BackendQuery) properties

## Usage Examples After Implementation

```swift
// In your app setup - Configure database in entry point
@main
struct MyApp: App {
    init() {
        prepareDependencies {
            $0.defaultDatabase = try! LocalBackendFactory.setupLiveDatabase()
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

// In your views or models
@Dependency(\.backendService) var backendService

// Write operations
let project = ProjectValue(bundleIdentifier: "com.example.app", ...)
try await backendService.createProject(project)

// Direct database access for custom queries
@Dependency(\.defaultDatabase) var database
let customData = try await database.read { db in
    try Project.filter(someCondition).fetchAll(db)
}

// Reactive observations using @FetchAll property wrappers
@FetchAll(Project.all.order { $0.createdAt.desc }) var projects: [Project]

// Direct integration with BackendQuery (Step 5)
@Shared(.allProjectIds()) var projectIds: [String]

// Testing setup
@Test(.dependency(\.defaultDatabase, try LocalBackendFactory.setupTestDatabase()))
func myTest() {
    @Dependency(\.backendService) var service
    // Test code here
}

// Preview setup
#Preview {
    let _ = prepareDependencies {
        $0.defaultDatabase = try! LocalBackendFactory.setupTestDatabase()
    }
    ContentView()
}
```

## Swift Testing Implementation

### 4.4 Database Manager Tests

**File**: `Packages/Lib/Tests/XcodeBuilderTests/LocalBackendTests.swift`

```swift
import Testing
import Foundation
import Dependencies
import DependenciesTestSupport
@testable import LocalBackend
@testable import Core

@Suite("Database Manager Tests", .dependency(\.defaultDatabase, try DatabaseManager.setupInMemoryDatabase()))
struct DatabaseManagerTests {
    @Dependency(\.defaultDatabase) var database

    @Test("In-memory database setup")
    func testInMemoryDatabaseSetup() throws {
        #expect(database != nil)

        // Test that tables exist
        try database.read { db in
            let tableExists = try Int.fetchOne(db, sql: #sql(
                """
                SELECT COUNT(*) FROM sqlite_master
                WHERE type='table' AND name='projects'
                """
            ))
            #expect(tableExists == 1)
        }
    }

    @Test("Migration system creates all tables")
    func testMigrationSystem() throws {
        try database.read { db in
            let expectedTables = ["projects", "schemes", "builds", "buildLogs", "crashLogs"]

            for tableName in expectedTables {
                let count = try Int.fetchOne(db, sql: #sql(
                    """
                    SELECT COUNT(*) FROM sqlite_master
                    WHERE type='table' AND name=?
                    """
                ), arguments: [tableName])
                #expect(count == 1, "Table \(tableName) should exist")
            }
        }
    }

    @Test("Database indexes are created")
    func testDatabaseIndexes() throws {
        try database.read { db in
            let indexCount = try Int.fetchOne(db, sql: #sql(
                """
                SELECT COUNT(*) FROM sqlite_master
                WHERE type='index' AND name LIKE 'idx_%'
                """
            ))
            #expect(indexCount >= 7, "Should have created performance indexes")
        }
    }
}

@Suite("LocalBackendService CRUD Tests")
struct LocalBackendServiceCRUDTests {
    @Dependency(\.backendService) var service

    @Test("Create and retrieve project", .dependency(\.defaultDatabase, try DatabaseManager.setupInMemoryDatabase()))
    func testProjectCRUD() async throws {
        let project = ProjectValue(
            bundleIdentifier: "com.example.test",
            name: "TestApp",
            displayName: "Test Application",
            gitRepoURL: URL(string: "https://github.com/test/repo")!,
            xcodeprojName: "TestApp.xcodeproj",
            workingDirectoryURL: URL(fileURLWithPath: "/tmp/test"),
            createdAt: Date()
        )

        // Create
        try await service.createProject(project)

        // Read - Use @FetchOne for reactive testing
        @FetchOne(Project.where { $0.bundleIdentifier == "com.example.test" }) var foundProject: Project?
        try await $foundProject.load()

        #expect(foundProject != nil)
        #expect(foundProject?.bundleIdentifier == "com.example.test")
        #expect(foundProject?.name == "TestApp")

        // Update
        let updatedProject = ProjectValue(
            bundleIdentifier: "com.example.test",
            name: "UpdatedTestApp",
            displayName: "Updated Test Application",
            gitRepoURL: project.gitRepoURL,
            xcodeprojName: project.xcodeprojName,
            workingDirectoryURL: project.workingDirectoryURL,
            createdAt: project.createdAt
        )

        try await service.updateProject(updatedProject)
        try await $foundProject.load()
        #expect(foundProject?.name == "UpdatedTestApp")

        // Delete
        try await service.deleteProject(id: "com.example.test")
        try await $foundProject.load()
        #expect(foundProject == nil)
    }

    @Test("Scheme CRUD with foreign key constraints", .dependency(\.defaultDatabase, try DatabaseManager.setupInMemoryDatabase()))
    func testSchemeCRUD() async throws {
        @Dependency(\.defaultDatabase) var database

        // First create a project
        let project = ProjectValue(
            bundleIdentifier: "com.example.test",
            name: "TestApp",
            displayName: "Test Application",
            gitRepoURL: URL(string: "https://github.com/test/repo")!,
            xcodeprojName: "TestApp.xcodeproj",
            workingDirectoryURL: URL(fileURLWithPath: "/tmp/test"),
            createdAt: Date()
        )
        try await service.createProject(project)

        let schemeId = UUID()
        let scheme = SchemeValue(
            id: schemeId,
            projectBundleIdentifier: "com.example.test",
            name: "TestScheme",
            platforms: [.iOS],
            order: 1
        )

        // Create
        try await service.createScheme(scheme)

        // Read using direct database access
        let foundScheme = try await database.read { db in
            try Scheme.where { $0.id == schemeId }.fetchOne(db)
        }

        #expect(foundScheme != nil)
        #expect(foundScheme?.id == schemeId)
        #expect(foundScheme?.name == "TestScheme")

        // Delete
        try await service.deleteScheme(id: schemeId)

        let deletedScheme = try await database.read { db in
            try Scheme.where { $0.id == schemeId }.fetchOne(db)
        }
        #expect(deletedScheme == nil)
    }
}

@Suite("LocalBackendService Reactive Tests")
struct LocalBackendServiceReactiveTests {

    @Test("Reactive streams work with @FetchAll", .dependency(\.defaultDatabase, try DatabaseManager.setupInMemoryDatabase()))
    func testReactiveStreams() async throws {
        @Dependency(\.backendService) var service

        // Use @FetchAll property wrapper for reactive testing
        @FetchAll(Project.all.order { $0.createdAt.desc }) var projects: [Project]

        // Initial state should be empty
        try await $projects.load()
        #expect(projects.isEmpty)

        // Add a project
        let project = ProjectValue(
            bundleIdentifier: "com.example.reactive",
            name: "ReactiveApp",
            displayName: "Reactive Application",
            gitRepoURL: URL(string: "https://github.com/test/reactive")!,
            xcodeprojName: "ReactiveApp.xcodeproj",
            workingDirectoryURL: URL(fileURLWithPath: "/tmp/reactive"),
            createdAt: Date()
        )

        try await service.createProject(project)

        // Load updated data
        try await $projects.load()
        #expect(projects.count == 1)
        #expect(projects.first?.bundleIdentifier == "com.example.reactive")
    }

    @Test("Complex reactive queries", .dependency(\.defaultDatabase, try DatabaseManager.setupInMemoryDatabase()))
    func testComplexQueries() async throws {
        @Dependency(\.backendService) var service
        @Dependency(\.defaultDatabase) var database

        // Set up test data
        let project = ProjectValue(
            bundleIdentifier: "com.example.complex",
            name: "ComplexApp",
            displayName: "Complex Application",
            gitRepoURL: URL(string: "https://github.com/test/complex")!,
            xcodeprojName: "ComplexApp.xcodeproj",
            workingDirectoryURL: URL(fileURLWithPath: "/tmp/complex"),
            createdAt: Date()
        )
        try await service.createProject(project)

        let schemeId = UUID()
        let scheme = SchemeValue(
            id: schemeId,
            projectBundleIdentifier: "com.example.complex",
            name: "ComplexScheme",
            platforms: [.iOS],
            order: 1
        )
        try await service.createScheme(scheme)

        // Test complex query using @FetchAll
        @FetchAll(
            Scheme
                .where { $0.projectBundleIdentifier == "com.example.complex" }
                .order { $0.order }
        ) var projectSchemes: [Scheme]

        try await $projectSchemes.load()
        #expect(projectSchemes.count == 1)
        #expect(projectSchemes.first?.name == "ComplexScheme")
    }
}

@Suite("LocalBackendService Performance Tests")
struct LocalBackendServicePerformanceTests {

    @Test("Bulk operations performance", .dependency(\.defaultDatabase, try DatabaseManager.setupInMemoryDatabase()))
    func testBulkOperationsPerformance() async throws {
        @Dependency(\.backendService) var service
        let startTime = Date()
        let count = 100

        // Create many projects
        for i in 0..<count {
            let project = ProjectValue(
                bundleIdentifier: "com.example.perf\(i)",
                name: "PerfApp\(i)",
                displayName: "Performance Application \(i)",
                gitRepoURL: URL(string: "https://github.com/test/perf\(i)")!,
                xcodeprojName: "PerfApp\(i).xcodeproj",
                workingDirectoryURL: URL(fileURLWithPath: "/tmp/perf\(i)"),
                createdAt: Date()
            )
            try await service.createProject(project)
        }

        let creationTime = Date().timeIntervalSince(startTime)
        print("Created \(count) projects in \(creationTime) seconds")

        // Verify retrieval performance using @FetchAll
        @FetchAll(Project.all.order { $0.createdAt.desc }) var allProjects: [Project]
        let retrievalStartTime = Date()
        try await $allProjects.load()
        let retrievalTime = Date().timeIntervalSince(retrievalStartTime)

        print("Retrieved \(allProjects.count) projects in \(retrievalTime) seconds")

        #expect(allProjects.count == count)
        #expect(creationTime < 5.0, "Bulk creation should complete within 5 seconds")
        #expect(retrievalTime < 0.1, "Retrieval should complete within 0.1 seconds")
    }
}
```

### 4.5 Performance and Integration Tests

**File**: `Packages/Lib/Tests/XcodeBuilderTests/LocalBackendPerformanceTests.swift`

```swift
import Testing
import Foundation
@testable import LocalBackend
@testable import Core

@Suite("LocalBackend Performance Tests")
struct LocalBackendPerformanceTests {

    @Test("Bulk operations performance", .dependency(\.defaultDatabase, try DatabaseManager.setupInMemoryDatabase()))
    func testBulkOperationsPerformance() async throws {
        @Dependency(\.backendService) var service

        let startTime = Date()

        // Create 100 projects
        for i in 0..<100 {
            let project = ProjectValue(
                bundleIdentifier: "com.example.perf\(i)",
                name: "PerfApp\(i)",
                displayName: "Performance Application \(i)",
                gitRepoURL: URL(string: "https://github.com/test/perf\(i)")!,
                xcodeprojName: "PerfApp\(i).xcodeproj",
                workingDirectoryURL: URL(fileURLWithPath: "/tmp/perf\(i)"),
                createdAt: Date()
            )
            try await service.createProject(project)
        }

        let creationTime = Date().timeIntervalSince(startTime)
        print("Created 100 projects in \(creationTime) seconds")

        // Verify retrieval performance
        let retrievalStartTime = Date()
        var allProjectIds: [String] = []
        for await projectIds in service.streamAllProjectIds() {
            allProjectIds = projectIds
            break
        }

        let retrievalTime = Date().timeIntervalSince(retrievalStartTime)
        print("Retrieved \(allProjectIds.count) project IDs in \(retrievalTime) seconds")

        #expect(allProjectIds.count == 100)
        #expect(creationTime < 5.0, "Bulk creation should complete within 5 seconds")
        #expect(retrievalTime < 0.1, "Retrieval should complete within 0.1 seconds")
    }

    @Test("Reactive stream performance with many updates", .dependency(\.defaultDatabase, try DatabaseManager.setupInMemoryDatabase()))
    func testReactiveStreamPerformance() async throws {
        @Dependency(\.backendService) var service

        var updateCount = 0
        let expectedUpdates = 10

        let streamTask = Task {
            for await _ in service.streamAllProjectIds() {
                updateCount += 1
                if updateCount >= expectedUpdates + 1 { // +1 for initial empty state
                    break
                }
            }
        }

        // Give stream time to start
        try await Task.sleep(nanoseconds: 100_000_000)

        let startTime = Date()

        // Create projects rapidly
        for i in 0..<expectedUpdates {
            let project = ProjectValue(
                bundleIdentifier: "com.example.rapid\(i)",
                name: "RapidApp\(i)",
                displayName: "Rapid Application \(i)",
                gitRepoURL: URL(string: "https://github.com/test/rapid\(i)")!,
                xcodeprojName: "RapidApp\(i).xcodeproj",
                workingDirectoryURL: URL(fileURLWithPath: "/tmp/rapid\(i)"),
                createdAt: Date()
            )
            try await service.createProject(project)
        }

        await streamTask.value
        let totalTime = Date().timeIntervalSince(startTime)

        print("Processed \(updateCount) reactive updates in \(totalTime) seconds")

        #expect(updateCount >= expectedUpdates)
        #expect(totalTime < 3.0, "Reactive updates should complete within 3 seconds")
    }

    @Test("Query performance with indexes", .dependency(\.defaultDatabase, try DatabaseManager.setupInMemoryDatabase()))
    func testQueryPerformanceWithIndexes() async throws {
        @Dependency(\.backendService) var service

        // Create test data with multiple builds per scheme
        let project = ProjectValue(
            bundleIdentifier: "com.example.query",
            name: "QueryApp",
            displayName: "Query Performance Test",
            gitRepoURL: URL(string: "https://github.com/test/query")!,
            xcodeprojName: "QueryApp.xcodeproj",
            workingDirectoryURL: URL(fileURLWithPath: "/tmp/query"),
            createdAt: Date()
        )
        try await service.createProject(project)

        let schemeId = UUID()
        let scheme = SchemeValue(
            id: schemeId,
            projectBundleIdentifier: "com.example.query",
            name: "QueryScheme",
            platforms: [.iOS],
            order: 1
        )
        try await service.createScheme(scheme)

        // Create 1000 builds for performance testing
        for i in 0..<1000 {
            let build = BuildModelValue(
                id: UUID(),
                schemeId: schemeId,
                versionString: "1.0.\(i % 10)", // 10 different versions
                buildNumber: i + 1,
                createdAt: Date().addingTimeInterval(-Double(i)), // Spread over time
                startDate: nil,
                endDate: nil,
                exportOptions: [],
                status: i % 2 == 0 ? .completed : .queued,
                progress: 0.0,
                commitHash: "abc\(i)",
                deviceMetadata: "MacBook Pro",
                osVersion: "macOS 14.0",
                memory: 16,
                processor: "M1 Pro"
            )
            try await service.createBuild(build)
        }

        // Test latest builds query performance
        let queryStartTime = Date()
        var latestBuilds: [BuildModelValue] = []
        for await builds in service.streamLatestBuilds(projectId: "com.example.query", limit: 50) {
            latestBuilds = builds
            break
        }
        let queryTime = Date().timeIntervalSince(queryStartTime)

        print("Latest builds query with 1000 records took \(queryTime) seconds")

        #expect(latestBuilds.count == 50)
        #expect(queryTime < 0.5, "Latest builds query should complete within 0.5 seconds")

        // Verify builds are properly ordered by creation date
        let isProperlyOrdered = latestBuilds.enumerated().allSatisfy { index, build in
            index == latestBuilds.count - 1 || build.createdAt >= latestBuilds[index + 1].createdAt
        }
        #expect(isProperlyOrdered, "Results should be ordered by creation date (newest first)")
    }
}
```
