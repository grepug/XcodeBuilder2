# Step 4: Local Backend Implementation

**Goal**: Create the SharingGRDB-powered local backend service that implements the BackendService protocol.

## Files to Create

### 4.1 Package Structure Updates

First, update the `Package.swift` to add the LocalBackend target:

**File**: `Packages/Lib/Package.swift` (update existing file)

```swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Lib",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(name: "Core", targets: ["Core"]),
        .library(name: "LocalBackend", targets: ["LocalBackend"]),
    ],
    dependencies: [
        .package(url: "https://github.com/groue/SharingGRDB", from: "0.2.0"),
        .package(url: "https://github.com/pointfreeco/swift-sharing", from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "Core",
            dependencies: [
                .product(name: "Sharing", package: "swift-sharing"),
            ],
            path: "Sources/Core"
        ),
        .target(
            name: "LocalBackend",
            dependencies: [
                "Core",
                .product(name: "GRDB", package: "GRDB.swift"),
                .product(name: "SharingGRDB", package: "SharingGRDB"),
            ],
            path: "Sources/LocalBackend"
        ),
    ]
)
```

### 4.2 Database Schema with SharingGRDB

**File**: `Packages/Lib/Sources/LocalBackend/Database/DatabaseMigration.swift`

```swift
import Foundation
import SharingGRDB

public struct DatabaseMigration {

    public static func setupMigrations(_ migrator: inout DatabaseMigrator) {

        migrator.registerMigration("Create tables") { db in
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
                    "order" INTEGER NOT NULL,
                    FOREIGN KEY("project_bundle_identifier") REFERENCES "projects"(bundle_identifier) ON DELETE CASCADE
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
                    FOREIGN KEY("scheme_id") REFERENCES "schemes"(id) ON DELETE CASCADE
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
                    FOREIGN KEY("build_id") REFERENCES "builds"(id) ON DELETE CASCADE
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
                    FOREIGN KEY("build_id") REFERENCES "builds"(id) ON DELETE CASCADE
                )
                """
            ).execute(db)
        }

        migrator.registerMigration("Add indexes") { db in
            // Indexes for performance
            try #sql("CREATE INDEX idx_schemes_project ON schemes(project_bundle_identifier)").execute(db)
            try #sql("CREATE INDEX idx_builds_scheme ON builds(scheme_id)").execute(db)
            try #sql("CREATE INDEX idx_builds_version ON builds(version_string)").execute(db)
            try #sql("CREATE INDEX idx_builds_created ON builds(created_at)").execute(db)
            try #sql("CREATE INDEX idx_buildLogs_build ON buildLogs(build_id)").execute(db)
            try #sql("CREATE INDEX idx_buildLogs_level ON buildLogs(level)").execute(db)
            try #sql("CREATE INDEX idx_crashLogs_build ON crashLogs(build_id)").execute(db)
        }
    }
}
```

### 4.3 Local Backend Service Implementation

**File**: `Packages/Lib/Sources/LocalBackend/LocalBackendService.swift`

```swift
import Foundation
import SharingGRDB
import Dependencies
import Core

public final class LocalBackendService: BackendService {
    @Dependency(\.defaultDatabase) var db

    public init() {}

    // MARK: - Write Operations

    public func createProject(_ project: ProjectValue) async throws {
        try await db.write { db in
            try Project
                .insert {
                    Project(
                        bundleIdentifier: project.bundleIdentifier,
                        name: project.name,
                        displayName: project.displayName,
                        gitRepoURL: project.gitRepoURL,
                        xcodeprojName: project.xcodeprojName,
                        workingDirectoryURL: project.workingDirectoryURL,
                        createdAt: project.createdAt
                    )
                }
                .execute(db)
        }
    }

    public func updateProject(_ project: ProjectValue) async throws {
        try await db.write { db in
            try Project
                .where { $0.bundleIdentifier == project.bundleIdentifier }
                .update {
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
            try Project
                .where { $0.bundleIdentifier == id }
                .deleteAll(db)
        }
    }

    public func createScheme(_ scheme: SchemeValue) async throws {
        try await db.write { db in
            try Scheme
                .insert {
                    Scheme(
                        id: scheme.id,
                        projectBundleIdentifier: scheme.projectBundleIdentifier,
                        name: scheme.name,
                        platforms: scheme.platforms,
                        order: scheme.order
                    )
                }
                .execute(db)
        }
    }

    public func updateScheme(_ scheme: SchemeValue) async throws {
        try await db.write { db in
            try Scheme
                .where { $0.id == scheme.id }
                .update {
                    $0.name = scheme.name
                    $0.order = scheme.order
                    // Note: platforms should not be updated according to your current schema
                }
                .execute(db)
        }
    }

    public func deleteScheme(id: UUID) async throws {
        try await db.write { db in
            try Scheme
                .where { $0.id == id }
                .deleteAll(db)
        }
    }

    public func createBuild(_ build: BuildModelValue) async throws {
        try await db.write { db in
            try BuildModel
                .insert {
                    BuildModel(
                        id: build.id,
                        schemeId: build.schemeId,
                        versionString: build.versionString,
                        buildNumber: build.buildNumber,
                        commitHash: build.commitHash,
                        createdAt: build.createdAt,
                        startDate: build.startDate,
                        endDate: build.endDate,
                        status: build.status,
                        progress: build.progress,
                        deviceModel: build.deviceMetadata,
                        osVersion: build.osVersion,
                        memory: build.memory,
                        processor: build.processor,
                        exportOptions: build.exportOptions
                    )
                }
                .execute(db)
        }
    }

    public func updateBuild(_ build: BuildModelValue) async throws {
        try await db.write { db in
            try BuildModel
                .where { $0.id == build.id }
                .update {
                    $0.status = build.status
                    $0.progress = build.progress
                    $0.startDate = build.startDate
                    $0.endDate = build.endDate
                }
                .execute(db)
        }
    }

    public func deleteBuild(id: UUID) async throws {
        try await db.write { db in
            try BuildModel
                .where { $0.id == id }
                .deleteAll(db)
        }
    }

    public func createBuildLog(_ log: BuildLogValue) async throws {
        try await db.write { db in
            try BuildLog
                .insert {
                    BuildLog(
                        id: log.id,
                        buildId: log.buildId,
                        category: log.category,
                        content: log.content,
                        level: BuildLog.Level(rawValue: log.level.rawValue) ?? .info
                    )
                }
                .execute(db)
        }
    }

    public func deleteBuildLogs(buildId: UUID) async throws {
        try await db.write { db in
            try BuildLog
                .where { $0.buildId == buildId }
                .deleteAll(db)
        }
    }

    public func createCrashLog(_ crashLog: CrashLogValue) async throws {
        try await db.write { db in
            try CrashLog
                .insert {
                    CrashLog(
                        incidentIdentifier: crashLog.incidentIdentifier,
                        isMainThread: crashLog.isMainThread,
                        createdAt: crashLog.createdAt,
                        buildId: crashLog.buildId,
                        content: crashLog.content,
                        hardwareModel: crashLog.hardwareModel,
                        process: crashLog.process,
                        role: CrashLogRole(rawValue: crashLog.role.rawValue) ?? .foreground,
                        dateTime: crashLog.dateTime,
                        launchTime: crashLog.launchTime,
                        osVersion: crashLog.osVersion,
                        note: crashLog.note,
                        fixed: crashLog.fixed,
                        priority: CrashLogPriority(rawValue: crashLog.priority.rawValue) ?? .medium
                    )
                }
                .execute(db)
        }
    }

    public func updateCrashLog(_ crashLog: CrashLogValue) async throws {
        try await db.write { db in
            try CrashLog
                .where { $0.incidentIdentifier == crashLog.incidentIdentifier }
                .update {
                    $0.note = crashLog.note
                    $0.fixed = crashLog.fixed
                    $0.priority = CrashLogPriority(rawValue: crashLog.priority.rawValue) ?? .medium
                }
                .execute(db)
        }
    }

    public func deleteCrashLog(id: String) async throws {
        try await db.write { db in
            try CrashLog
                .where { $0.incidentIdentifier == id }
                .deleteAll(db)
        }
    }
}

// MARK: - Observation Methods using FetchKeyRequest Pattern

public extension LocalBackendService {

    func streamAllProjectIds() -> some AsyncSequence<[String]> {
        AllProjectIdsRequest().values(in: db)
    }

    func streamProject(id: String) -> some AsyncSequence<ProjectValue?> {
        ProjectRequest(id: id).values(in: db)
    }

    func streamProjectVersionStrings() -> some AsyncSequence<[String: [String]]> {
        AllProjectVersionStringsRequest().values(in: db)
    }

    func streamSchemeIds(projectId: String) -> some AsyncSequence<[UUID]> {
        SchemeIdsRequest(projectId: projectId).values(in: db)
    }

    func streamScheme(id: UUID) -> some AsyncSequence<SchemeValue?> {
        SchemeRequest(id: id).values(in: db)
    }

    func streamBuildIds(schemeIds: [UUID], versionString: String?) -> some AsyncSequence<[UUID]> {
        BuildIdsRequest(schemeIds: schemeIds, versionString: versionString).values(in: db)
    }

    func streamBuild(id: UUID) -> some AsyncSequence<BuildModelValue?> {
        BuildRequest(id: id).values(in: db)
    }

    func streamLatestBuilds(projectId: String, limit: Int) -> some AsyncSequence<[BuildModelValue]> {
        LatestBuildsRequest(projectId: projectId, limit: limit).values(in: db)
    }

    func streamBuildLogIds(buildId: UUID, includeDebug: Bool, category: String?) -> some AsyncSequence<[UUID]> {
        BuildLogIdsRequest(buildId: buildId, includeDebug: includeDebug, category: category).values(in: db)
    }

    func streamBuildLog(id: UUID) -> some AsyncSequence<BuildLogValue?> {
        BuildLogRequest(id: id).values(in: db)
    }

    func streamCrashLogIds(buildId: UUID) -> some AsyncSequence<[String]> {
        CrashLogIdsRequest(buildId: buildId).values(in: db)
    }

    func streamCrashLog(id: String) -> some AsyncSequence<CrashLogValue?> {
        CrashLogRequest(id: id).values(in: db)
    }

    func streamProjectDetail(id: String) -> some AsyncSequence<ProjectDetailData> {
        ProjectDetailRequest(id: id).values(in: db).compactMap { $0 }
    }

    func streamBuildVersionStrings(projectId: String) -> some AsyncSequence<[String]> {
        BuildVersionStringsRequest(projectId: projectId).values(in: db)
    }
}
```

### 4.4 FetchKeyRequest Implementations

**File**: `Packages/Lib/Sources/LocalBackend/Requests/LocalBackendRequests.swift`

```swift
import Foundation
import SharingGRDB
import Core

// MARK: - Project Requests

struct AllProjectIdsRequest: FetchKeyRequest {
    func fetch(_ db: Database) throws -> [String] {
        try Project.all
            .order(by: \.createdAt)
            .fetchAll(db)
            .map(\.bundleIdentifier)
    }
}

struct ProjectRequest: FetchKeyRequest {
    let id: String

    func fetch(_ db: Database) throws -> ProjectValue? {
        guard let project = try Project
            .where { $0.bundleIdentifier == id }
            .fetchOne(db) else { return nil }

        return ProjectValue(
            bundleIdentifier: project.bundleIdentifier,
            name: project.name,
            displayName: project.displayName,
            gitRepoURL: project.gitRepoURL,
            xcodeprojName: project.xcodeprojName,
            workingDirectoryURL: project.workingDirectoryURL,
            createdAt: project.createdAt
        )
    }
}

struct AllProjectVersionStringsRequest: FetchKeyRequest {
    func fetch(_ db: Database) throws -> [String: [String]] {
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

        return result
    }
}

// MARK: - Scheme Requests

struct SchemeIdsRequest: FetchKeyRequest {
    let projectId: String

    func fetch(_ db: Database) throws -> [UUID] {
        try Scheme
            .where { $0.projectBundleIdentifier == projectId }
            .order { $0.order }
            .fetchAll(db)
            .map(\.id)
    }
}

struct SchemeRequest: FetchKeyRequest {
    let id: UUID

    func fetch(_ db: Database) throws -> SchemeValue? {
        guard let scheme = try Scheme
            .where { $0.id == id }
            .fetchOne(db) else { return nil }

        return SchemeValue(
            id: scheme.id,
            projectBundleIdentifier: scheme.projectBundleIdentifier,
            name: scheme.name,
            platforms: scheme.platforms,
            order: scheme.order
        )
    }
}

// MARK: - Build Requests

struct BuildIdsRequest: FetchKeyRequest {
    let schemeIds: [UUID]
    let versionString: String?

    func fetch(_ db: Database) throws -> [UUID] {
        var query = BuildModel.where { $0.schemeId.in(schemeIds) }

        if let versionString = versionString {
            query = query.where { $0.versionString == versionString }
        }

        return try query
            .order { $0.createdAt.desc() }
            .fetchAll(db)
            .map(\.id)
    }
}

struct BuildRequest: FetchKeyRequest {
    let id: UUID

    func fetch(_ db: Database) throws -> BuildModelValue? {
        guard let build = try BuildModel
            .where { $0.id == id }
            .fetchOne(db) else { return nil }

        return BuildModelValue(
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
}

struct LatestBuildsRequest: FetchKeyRequest {
    let projectId: String
    let limit: Int

    func fetch(_ db: Database) throws -> [BuildModelValue] {
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

        return builds.map { build in
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
    }
}

struct BuildVersionStringsRequest: FetchKeyRequest {
    let projectId: String

    func fetch(_ db: Database) throws -> [String] {
        let schemes = try Scheme
            .where { $0.projectBundleIdentifier == projectId }
            .fetchAll(db)

        let schemeIds = schemes.map(\.id)
        let builds = try BuildModel
            .where { $0.schemeId.in(schemeIds) }
            .fetchAll(db)

        return Array(Set(builds.map(\.versionString))).sorted(by: >)
    }
}

// MARK: - BuildLog Requests

struct BuildLogIdsRequest: FetchKeyRequest {
    let buildId: UUID
    let includeDebug: Bool
    let category: String?

    func fetch(_ db: Database) throws -> [UUID] {
        var query = BuildLog.where { $0.buildId == buildId }

        if !includeDebug {
            query = query.where { $0.level != .debug }
        }

        if let category = category {
            query = query.where { $0.category == category }
        }

        return try query
            .order { $0.createdAt }
            .fetchAll(db)
            .map(\.id)
    }
}

struct BuildLogRequest: FetchKeyRequest {
    let id: UUID

    func fetch(_ db: Database) throws -> BuildLogValue? {
        guard let log = try BuildLog
            .where { $0.id == id }
            .fetchOne(db) else { return nil }

        return BuildLogValue(
            id: log.id,
            buildId: log.buildId,
            category: log.category,
            level: BuildLogLevel(rawValue: log.level.rawValue) ?? .info,
            content: log.content,
            createdAt: log.createdAt
        )
    }
}

// MARK: - CrashLog Requests

struct CrashLogIdsRequest: FetchKeyRequest {
    let buildId: UUID

    func fetch(_ db: Database) throws -> [String] {
        try CrashLog
            .where { $0.buildId == buildId }
            .order { $0.createdAt.desc() }
            .fetchAll(db)
            .map(\.incidentIdentifier)
    }
}

struct CrashLogRequest: FetchKeyRequest {
    let id: String

    func fetch(_ db: Database) throws -> CrashLogValue? {
        guard let crashLog = try CrashLog
            .where { $0.incidentIdentifier == id }
            .fetchOne(db) else { return nil }

        return CrashLogValue(
            incidentIdentifier: crashLog.incidentIdentifier,
            isMainThread: crashLog.isMainThread,
            createdAt: crashLog.createdAt,
            buildId: crashLog.buildId,
            content: crashLog.content,
            hardwareModel: crashLog.hardwareModel,
            process: crashLog.process,
            role: CrashLogValueRole(rawValue: crashLog.role.rawValue) ?? .foreground,
            dateTime: crashLog.dateTime,
            launchTime: crashLog.launchTime,
            osVersion: crashLog.osVersion,
            note: crashLog.note,
            fixed: crashLog.fixed,
            priority: CrashLogValuePriority(rawValue: crashLog.priority.rawValue) ?? .medium
        )
    }
}
```

### 4.5 Local Backend Type

**File**: `Packages/Lib/Sources/LocalBackend/LocalBackendType.swift`

```swift
import Foundation
import SharingGRDB
import Core

/// Local backend type using SharingGRDB/SQLite
public struct LocalBackendType: BackendType {
    private let databaseURL: URL

    public init(databaseURL: URL = Self.defaultDatabaseURL()) {
        self.databaseURL = databaseURL
    }

    public var displayName: String { "Local Database" }
    public var identifier: String { "local" }

    public func createService() throws -> BackendService {
        let dbWriter: DatabaseWriter

        if databaseURL.path == ":memory:" {
            dbWriter = try DatabaseQueue()
        } else {
            dbWriter = try DatabaseQueue(path: databaseURL.path)
        }

        // Set up migrations
        var migrator = DatabaseMigrator()
        DatabaseMigration.setupMigrations(&migrator)

        try migrator.migrate(dbWriter)

        return LocalBackendService(dbWriter: dbWriter)
    }

    /// Expose database writer for SharingGRDB integration
    public var databaseWriterForSharing: DatabaseWriter {
        get throws {
            let dbWriter: DatabaseWriter

            if databaseURL.path == ":memory:" {
                dbWriter = try DatabaseQueue()
            } else {
                dbWriter = try DatabaseQueue(path: databaseURL.path)
            }

            var migrator = DatabaseMigrator()
            DatabaseMigration.setupMigrations(&migrator)

            try migrator.migrate(dbWriter)

            return dbWriter
        }
    }

    private static func defaultDatabaseURL() -> URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDir = appSupport.appendingPathComponent("XcodeBuilder2", isDirectory: true)
        try? FileManager.default.createDirectory(at: appDir, withIntermediateDirectories: true)
        return appDir.appendingPathComponent("database.sqlite")
    }
}
```

## Implementation Checklist

- [ ] Update `Package.swift` to add LocalBackend target with SharingGRDB dependency
- [ ] Create `DatabaseMigration.swift` with SharingGRDB migration setup using `#sql()` macros
- [ ] Create `LocalBackendRequests.swift` with all FetchKeyRequest implementations
- [ ] Create `LocalBackendService.swift` using SharingGRDB APIs and FetchKeyRequest pattern
- [ ] Create `LocalBackendType.swift` for backend instantiation with DatabaseWriter support
- [ ] Add proper model conversion between Core models and SharingGRDB models
- [ ] Test database operations:
  - [ ] CRUD operations work with SharingGRDB `.insert{}`, `.update{}`, `.deleteAll()`
  - [ ] FetchKeyRequest implementations return live data
  - [ ] Foreign key constraints work
  - [ ] Indexes improve query performance
- [ ] Test database migration runs successfully with DatabaseMigrator
- [ ] Test SharingGRDB reactive queries work with `.values(in:)`

## Usage Examples

```swift
// Create and use the local backend
let backendType = LocalBackendType()
let backendService = try backendType.createService()

// Write operations using SharingGRDB syntax
let project = ProjectValue(
    bundleIdentifier: "com.example.app",
    name: "MyApp",
    displayName: "My App",
    gitRepoURL: URL(string: "https://github.com/user/repo")!,
    xcodeprojName: "MyApp.xcodeproj",
    workingDirectoryURL: URL(fileURLWithPath: "/path/to/project")
)
try await backendService.createProject(project)

// Observation using FetchKeyRequest pattern
for await projectIds in backendService.streamAllProjectIds() {
    print("Current project IDs: \(projectIds)")
}

// Direct SharingGRDB usage in your app
@Shared(.database(AllProjectRequest()))
private var allProjects: AllProjectRequest.Value = AllProjectRequest.Value()
```

## Next Step

After completing this step, proceed to [Step 5: SharingGRDB Protocol Conformance](./STEP_5_SHARING_GRDB_CONFORMANCE.md) to integrate the local backend with SharingGRDB for reactive UI updates.
