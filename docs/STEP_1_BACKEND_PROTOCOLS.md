# Step 1: Backend Protocols

**Goal**: Define core protocols and value types that form the foundation of the backend abstraction layer.

## Files to Create

### 1.1 Backend Model Protocols

**File**: `Packages/Lib/Sources/Core/Services/BackendModels.swift`

```swift
import Foundation

// MARK: - Backend Model Protocols
public protocol ProjectProtocol: Sendable, Identifiable {
    var bundleIdentifier: String { get }
    var name: String { get }
    var displayName: String { get }
    var gitRepoURL: URL { get }
    var xcodeprojName: String { get }
    var workingDirectoryURL: URL { get }
    var createdAt: Date { get }
    var id: String { get }
}

public protocol SchemeProtocol: Sendable, Identifiable {
    var id: UUID { get }
    var projectBundleIdentifier: String { get }
    var name: String { get }
    var platforms: [Platform] { get }
    var order: Int { get }
}

public protocol BuildModelProtocol: Sendable, Identifiable {
    var id: UUID { get }
    var schemeId: UUID { get }
    var versionString: String { get }
    var buildNumber: Int { get }
    var createdAt: Date { get }
    var startDate: Date? { get }
    var endDate: Date? { get }
    var exportOptions: ExportOption { get }
    var status: BuildStatus { get }
    var progress: Double { get }
    var commitHash: String { get }
    var deviceMetadata: String { get }
    var osVersion: String { get }
    var memory: Int { get }
    var processor: String { get }
}

public protocol BuildLogProtocol: Sendable, Identifiable {
    var id: UUID { get }
    var buildId: UUID { get }
    var category: String? { get }
    var level: BuildLogLevel { get }
    var content: String { get }
    var createdAt: Date { get }
}

public protocol CrashLogProtocol: Sendable, Identifiable {
    var incidentIdentifier: String { get }
    var isMainThread: Bool { get }
    var createdAt: Date { get }
    var buildId: UUID { get }
    var content: String { get }
    var hardwareModel: String { get }
    var process: String { get }
    var role: CrashLogRole { get }
    var dateTime: Date { get }
    var launchTime: Date { get }
    var osVersion: String { get }
    var note: String { get }
    var fixed: Bool { get }
    var priority: CrashLogPriority { get }
    var id: String { get }
}

// MARK: - Supporting Enums
public enum BuildLogLevel: String, Sendable, CaseIterable {
    case info, warning, error, debug
}
```

### 1.2 Backend Value Types

Add to the same file (`BackendModels.swift`):

```swift
// MARK: - Value Types for Backend Communication
public struct ProjectValue: ProjectProtocol {
    public let bundleIdentifier: String
    public let name: String
    public let displayName: String
    public let gitRepoURL: URL
    public let xcodeprojName: String
    public let workingDirectoryURL: URL
    public let createdAt: Date

    public var id: String { bundleIdentifier }

    public init(
        bundleIdentifier: String,
        name: String,
        displayName: String,
        gitRepoURL: URL,
        xcodeprojName: String,
        workingDirectoryURL: URL,
        createdAt: Date = .now
    ) {
        self.bundleIdentifier = bundleIdentifier
        self.name = name
        self.displayName = displayName
        self.gitRepoURL = gitRepoURL
        self.xcodeprojName = xcodeprojName
        self.workingDirectoryURL = workingDirectoryURL
        self.createdAt = createdAt
    }
}

public struct SchemeValue: SchemeProtocol {
    public let id: UUID
    public let projectBundleIdentifier: String
    public let name: String
    public let platforms: [Platform]
    public let order: Int

    public init(
        id: UUID = UUID(),
        projectBundleIdentifier: String,
        name: String,
        platforms: [Platform],
        order: Int
    ) {
        self.id = id
        self.projectBundleIdentifier = projectBundleIdentifier
        self.name = name
        self.platforms = platforms
        self.order = order
    }
}

public struct BuildModelValue: BuildModelProtocol {
    public let id: UUID
    public let schemeId: UUID
    public let versionString: String
    public let buildNumber: Int
    public let createdAt: Date
    public let startDate: Date?
    public let endDate: Date?
    public let exportOptions: ExportOption
    public let status: BuildStatus
    public let progress: Double
    public let commitHash: String
    public let deviceMetadata: String
    public let osVersion: String
    public let memory: Int
    public let processor: String

    public init(
        id: UUID = UUID(),
        schemeId: UUID,
        versionString: String,
        buildNumber: Int,
        createdAt: Date = .now,
        startDate: Date? = nil,
        endDate: Date? = nil,
        exportOptions: ExportOption = .init(),
        status: BuildStatus = .queued,
        progress: Double = 0,
        commitHash: String = "",
        deviceMetadata: String = "",
        osVersion: String = "",
        memory: Int = 0,
        processor: String = ""
    ) {
        self.id = id
        self.schemeId = schemeId
        self.versionString = versionString
        self.buildNumber = buildNumber
        self.createdAt = createdAt
        self.startDate = startDate
        self.endDate = endDate
        self.exportOptions = exportOptions
        self.status = status
        self.progress = progress
        self.commitHash = commitHash
        self.deviceMetadata = deviceMetadata
        self.osVersion = osVersion
        self.memory = memory
        self.processor = processor
    }
}

public struct BuildLogValue: BuildLogProtocol {
    public let id: UUID
    public let buildId: UUID
    public let category: String?
    public let level: BuildLogLevel
    public let content: String
    public let createdAt: Date

    public init(
        id: UUID = UUID(),
        buildId: UUID,
        category: String? = nil,
        level: BuildLogLevel = .info,
        content: String,
        createdAt: Date = .now
    ) {
        self.id = id
        self.buildId = buildId
        self.category = category
        self.level = level
        self.content = content
        self.createdAt = createdAt
    }
}

public struct CrashLogValue: CrashLogProtocol {
    public let incidentIdentifier: String
    public let isMainThread: Bool
    public let createdAt: Date
    public let buildId: UUID
    public let content: String
    public let hardwareModel: String
    public let process: String
    public let role: CrashLogRole
    public let dateTime: Date
    public let launchTime: Date
    public let osVersion: String
    public let note: String
    public let fixed: Bool
    public let priority: CrashLogPriority

    public var id: String { incidentIdentifier }

    public init(
        incidentIdentifier: String,
        isMainThread: Bool,
        createdAt: Date = .now,
        buildId: UUID,
        content: String,
        hardwareModel: String,
        process: String,
        role: CrashLogRole,
        dateTime: Date,
        launchTime: Date,
        osVersion: String,
        note: String = "",
        fixed: Bool = false,
        priority: CrashLogPriority = .medium
    ) {
        self.incidentIdentifier = incidentIdentifier
        self.isMainThread = isMainThread
        self.createdAt = createdAt
        self.buildId = buildId
        self.content = content
        self.hardwareModel = hardwareModel
        self.process = process
        self.role = role
        self.dateTime = dateTime
        self.launchTime = launchTime
        self.osVersion = osVersion
        self.note = note
        self.fixed = fixed
        self.priority = priority
    }
}
```

### 1.3 Backend Service Protocol

**File**: `Packages/Lib/Sources/Core/Services/BackendServiceProtocol.swift`

```swift
import Foundation

/// Core protocol defining backend operations
public protocol BackendService: Sendable {
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
    func streamAllProjectIds() -> some AsyncSequence<[String]>
    func streamProject(id: String) -> some AsyncSequence<ProjectValue?>
    func streamProjectVersionStrings() -> some AsyncSequence<[String: [String]]>
    func streamSchemeIds(projectId: String) -> some AsyncSequence<[UUID]>
    func streamScheme(id: UUID) -> some AsyncSequence<SchemeValue?>
    func streamBuildIds(schemeIds: [UUID], versionString: String?) -> some AsyncSequence<[UUID]>
    func streamBuild(id: UUID) -> some AsyncSequence<BuildModelValue?>
    func streamLatestBuilds(projectId: String, limit: Int) -> some AsyncSequence<[BuildModelValue]>
    func streamBuildLogIds(buildId: UUID, includeDebug: Bool, category: String?) -> some AsyncSequence<[UUID]>
    func streamBuildLog(id: UUID) -> some AsyncSequence<BuildLogValue?>
    func streamCrashLogIds(buildId: UUID) -> some AsyncSequence<[String]>
    func streamCrashLog(id: String) -> some AsyncSequence<CrashLogValue?>
    func streamProjectDetail(id: String) -> some AsyncSequence<ProjectDetailData>
    func streamBuildVersionStrings(projectId: String) -> some AsyncSequence<[String]>
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
```

### 1.4 Backend Type Protocol

**File**: `Packages/Lib/Sources/Core/Services/BackendType.swift`

```swift
import Foundation

/// Protocol defining different backend types
public protocol BackendType: Sendable {
    /// Create a backend service instance
    func createService() throws -> BackendService

    /// Display name for the backend type
    var displayName: String { get }

    /// Unique identifier for the backend type
    var identifier: String { get }
}
```

## Implementation Checklist

- [ ] Create `BackendModels.swift` with protocols and value types
- [ ] Create `BackendServiceProtocol.swift` with service interface
- [ ] Create `BackendType.swift` with backend type protocol
- [ ] Verify all protocols are `Sendable` for async operations
- [ ] Ensure value types have proper initializers
- [ ] Test protocol conformance compiles correctly

## Next Step

After completing this step, proceed to [Step 2: Protocol Conversions](./STEP_2_PROTOCOL_CONVERSIONS.md) to implement the generic conversion system.
