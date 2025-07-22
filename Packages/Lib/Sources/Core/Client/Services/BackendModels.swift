import Foundation

// MARK: - Backend Model Protocols
public protocol ProjectProtocol: Sendable, Identifiable, Hashable {
    var bundleIdentifier: String { get }
    var name: String { get }
    var displayName: String { get }
    var gitRepoURL: URL { get }
    var xcodeprojName: String { get }
    var workingDirectoryURL: URL { get }
    var createdAt: Date { get }
    var id: String { get }
}

public protocol SchemeProtocol: Sendable, Identifiable, Hashable {
    var id: UUID { get }
    var projectBundleIdentifier: String { get }
    var name: String { get }
    var platforms: [Platform] { get }
    var order: Int { get }
}

public protocol BuildModelProtocol: Sendable, Identifiable, Hashable {
    var id: UUID { get }
    var schemeId: UUID { get }
    var versionString: String { get set }
    var buildNumber: Int { get set }
    var createdAt: Date { get }
    var startDate: Date? { get }
    var endDate: Date? { get }
    var exportOptions: [ExportOption] { get }
    var status: BuildStatus { get }
    var progress: Double { get }
    var commitHash: String { get set }
    var deviceMetadata: DeviceMetadata { get }
    var osVersion: String { get }
    var memory: Int { get }
    var processor: String { get }
    
    // Computed properties for compatibility
    var version: Version { get }
    var projectDirName: String { get }
}

public extension BuildModelProtocol {
    var duration: TimeInterval {
        guard let start = startDate, let end = endDate else { return 0 }
        return end.timeIntervalSince(start)
    }
    
    var version: Version {
        get {
            Version(version: versionString, buildNumber: buildNumber, commitHash: commitHash)
        }
        
        set {
            versionString = newValue.version
            buildNumber = newValue.buildNumber
            commitHash = newValue.commitHash
        }
    }
}

public protocol BuildLogProtocol: Sendable, Identifiable {
    var id: UUID { get }
    var buildId: UUID { get }
    var category: String? { get }
    var level: BuildLogLevel { get }
    var content: String { get }
    var createdAt: Date { get }
}

public protocol CrashLogProtocol: Sendable, Identifiable, Hashable {
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

public extension CrashLogProtocol {
    var parsedThreads: [CrashLogThread] {
        parseThreadInfo(content: content)
    }
}

// MARK: - Supporting Enums
public enum BuildLogLevel: String, Sendable, CaseIterable {
    case info, warning, error, debug
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

// MARK: - Value Types for Backend Communication
public struct ProjectValue: ProjectProtocol, Sendable {
    public var bundleIdentifier: String
    public var name: String
    public var displayName: String
    public var gitRepoURL: URL
    public var xcodeprojName: String
    public var workingDirectoryURL: URL
    public var createdAt: Date

    public var id: String { bundleIdentifier }

    public init(
        bundleIdentifier: String = "",
        name: String = "",
        displayName: String = "",
        gitRepoURL: URL = URL(string: "https://github.com")!,
        xcodeprojName: String = "",
        workingDirectoryURL: URL = URL(fileURLWithPath: ""),
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

public struct SchemeValue: SchemeProtocol, Sendable {
    public let id: UUID
    public var projectBundleIdentifier: String
    public var name: String
    public var platforms: [Platform]
    public var order: Int

    public init(
        id: UUID = UUID(),
        projectBundleIdentifier: String = "",
        name: String = "",
        platforms: [Platform] = [],
        order: Int = 0,
    ) {
        self.id = id
        self.projectBundleIdentifier = projectBundleIdentifier
        self.name = name
        self.platforms = platforms
        self.order = order
    }
}

public struct BuildModelValue: BuildModelProtocol, Sendable {
    public let id: UUID
    public var schemeId: UUID
    public var versionString: String
    public var buildNumber: Int
    public var createdAt: Date
    public var startDate: Date?
    public var endDate: Date?
    public var exportOptions: [ExportOption]
    public var status: BuildStatus
    public var progress: Double
    public var commitHash: String
    public var deviceMetadata: DeviceMetadata
    public var osVersion: String
    public var memory: Int
    public var processor: String
    
    // Computed properties
    public var version: Version {
        Version(version: versionString, buildNumber: buildNumber)
    }
    
    public var projectDirName: String {
        "\(versionString)_\(buildNumber)"
    }

    public init(
        id: UUID = UUID(),
        schemeId: UUID = .init(),
        version: Version = .init(),
        createdAt: Date = .now,
        startDate: Date? = nil,
        endDate: Date? = nil,
        exportOptions: [ExportOption] = [],
        status: BuildStatus = .queued,
        progress: Double = 0,
        deviceMetadata: DeviceMetadata = .init(),
        osVersion: String = "",
        memory: Int = 0,
        processor: String = ""
    ) {
        self.id = id
        self.schemeId = schemeId
        self.versionString = version.version
        self.buildNumber = version.buildNumber
        self.commitHash = version.commitHash
        self.createdAt = createdAt
        self.startDate = startDate
        self.endDate = endDate
        self.exportOptions = exportOptions
        self.status = status
        self.progress = progress
        self.deviceMetadata = deviceMetadata
        self.osVersion = osVersion
        self.memory = memory
        self.processor = processor
    }
}

public struct BuildLogValue: BuildLogProtocol, Sendable {
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

public struct CrashLogValue: CrashLogProtocol, Sendable {
    public var incidentIdentifier: String
    public var isMainThread: Bool
    public var createdAt: Date
    public var buildId: UUID
    public var content: String
    public var hardwareModel: String
    public var process: String
    public var role: CrashLogRole
    public var dateTime: Date
    public var launchTime: Date
    public var osVersion: String
    public var note: String
    public var fixed: Bool
    public var priority: CrashLogPriority

    public var id: String { incidentIdentifier }

    public init(
        incidentIdentifier: String = "",
        isMainThread: Bool = false,
        createdAt: Date = .now,
        buildId: UUID = .init(),
        content: String = "",
        hardwareModel: String = "",
        process: String = "",
        role: CrashLogRole = .foreground,
        dateTime: Date = .now,
        launchTime: Date = .now,
        osVersion: String = "",
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
