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
    var exportOptions: [ExportOption] { get }
    var status: BuildStatus { get }
    var progress: Double { get }
    var commitHash: String { get }
    var deviceMetadata: String { get }
    var osVersion: String { get }
    var memory: Int { get }
    var processor: String { get }
    
    // Computed properties for compatibility
    var version: Version { get }
    var projectDirName: String { get }
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
    public let exportOptions: [ExportOption]
    public let status: BuildStatus
    public let progress: Double
    public let commitHash: String
    public let deviceMetadata: String
    public let osVersion: String
    public let memory: Int
    public let processor: String
    
    // Computed properties
    public var version: Version {
        Version(version: versionString, buildNumber: buildNumber)
    }
    
    public var projectDirName: String {
        "\(versionString)_\(buildNumber)"
    }

    public init(
        id: UUID = UUID(),
        schemeId: UUID,
        versionString: String,
        buildNumber: Int,
        createdAt: Date = .now,
        startDate: Date? = nil,
        endDate: Date? = nil,
        exportOptions: [ExportOption] = [],
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
    public var buildId: UUID
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

// MARK: - Supporting Enums (Backend-Agnostic)

public enum BuildStatus: String, Codable, Sendable, Hashable, CaseIterable {
    case queued
    case running
    case completed
    case failed
    case cancelled
    
    public var title: String {
        switch self {
        case .queued: "Queued"
        case .running: "Running"
        case .completed: "Completed"
        case .failed: "Failed"
        case .cancelled: "Cancelled"
        }
    }
}

public enum CrashLogRole: String, Codable, Sendable, Hashable, CaseIterable {
    case foreground
    case background
}

public enum CrashLogPriority: String, Codable, Sendable, Hashable, CaseIterable {
    case urgent
    case high
    case medium
    case low
}

// MARK: - Log Categories
public enum BuildLogCategory: String, Codable, Sendable, Hashable, CaseIterable {
    case clone
    case resolveDependencies
    case archive
    case export
    case cleanup
}

// MARK: - Type Aliases for Backward Compatibility
public typealias Project = any ProjectProtocol
public typealias Scheme = any SchemeProtocol
public typealias BuildModel = any BuildModelProtocol
public typealias CrashLog = any CrashLogProtocol
public typealias BuildLog = any BuildLogProtocol

// MARK: - Nested type aliases for compatibility
public enum BuildLogCompat {
    public typealias Level = BuildLogLevel
}