import Foundation

/// Backend-agnostic build payload for Xcode builds
/// Uses Value types for cross-module compatibility
public struct XcodeBuildPayload: Sendable {
    public enum GitCloneKind: Sendable {
        case tag
        case branch(String)
    }
    
    public let project: ProjectValue
    public let scheme: SchemeValue
    public let gitCloneKind: GitCloneKind
    public let exportOptions: [ExportOption]
    public let build: BuildModelValue
    
    public var version: Version {
        Version(
            version: build.versionString,
            buildNumber: build.buildNumber,
            commitHash: build.commitHash
        )
    }
    
    public var buildId: UUID {
        build.id
    }

    public init(project: ProjectValue, scheme: SchemeValue, build: BuildModelValue, gitCloneKind: GitCloneKind, exportOptions: [ExportOption]) {
        self.project = project
        self.scheme = scheme
        self.build = build
        self.gitCloneKind = gitCloneKind
        self.exportOptions = exportOptions
    }
}

/// Progress information for build jobs
public struct XcodeBuildProgress: Sendable {
    public let progress: Double
    public let message: String
    public var isFinished = false
    
    public init(progress: Double, message: String, isFinished: Bool = false) {
        self.progress = progress
        self.message = message
        self.isFinished = isFinished
    }
}
