import Foundation

// MARK: - Build Job Value Types (Step 6)

/// Clean value type for build progress updates - backend-agnostic
public struct BuildProgressUpdate: Sendable {
    public let buildId: UUID
    public let progress: Double
    public let message: String
    public let timestamp: Date
    
    public init(buildId: UUID, progress: Double, message: String, timestamp: Date = Date()) {
        self.buildId = buildId
        self.progress = progress
        self.message = message
        self.timestamp = timestamp
    }
}

/// Build job status - backend-agnostic
public enum BuildJobStatus: Sendable {
    case idle
    case running(progress: Double)
    case completed
    case failed(Error)
    case cancelled
}

/// Clean payload for build jobs - backend-agnostic
/// Can be used by local builds, sent over HTTP, or passed to cloud APIs
public struct BuildJobPayload: Sendable {
    public let projectPath: String
    public let scheme: String
    public let configuration: String
    public let sdk: String?
    public let destination: String?
    public let archivePath: String?
    public let exportPath: String?
    public let exportMethod: String?
    public let teamID: String?
    public let bundleIdentifier: String?
    public let versionNumber: String?
    public let buildNumber: String?
    
    public init(
        projectPath: String,
        scheme: String,
        configuration: String,
        sdk: String? = nil,
        destination: String? = nil,
        archivePath: String? = nil,
        exportPath: String? = nil,
        exportMethod: String? = nil,
        teamID: String? = nil,
        bundleIdentifier: String? = nil,
        versionNumber: String? = nil,
        buildNumber: String? = nil
    ) {
        self.projectPath = projectPath
        self.scheme = scheme
        self.configuration = configuration
        self.sdk = sdk
        self.destination = destination
        self.archivePath = archivePath
        self.exportPath = exportPath
        self.exportMethod = exportMethod
        self.teamID = teamID
        self.bundleIdentifier = bundleIdentifier
        self.versionNumber = versionNumber
        self.buildNumber = buildNumber
    }
}
