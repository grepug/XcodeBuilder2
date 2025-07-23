import Foundation

// MARK: - Backend Model Protocols

// MARK: Project Protocol
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

// MARK: Scheme Protocol  
public protocol SchemeProtocol: Sendable, Identifiable, Hashable {
    var id: UUID { get }
    var projectBundleIdentifier: String { get }
    var name: String { get }
    var platforms: [Platform] { get }
    var order: Int { get }
}

// MARK: Build Model Protocol
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
