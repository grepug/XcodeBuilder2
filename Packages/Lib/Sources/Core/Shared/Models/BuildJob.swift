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
