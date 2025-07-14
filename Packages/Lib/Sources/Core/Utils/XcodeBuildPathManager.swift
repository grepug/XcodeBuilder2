import Foundation
import Dependencies

public protocol XcodeBuildPathManager: Sendable {
    func projectPath(for project: Project, version: Version) -> String
    func xcodeprojPath(for project: Project, version: Version) -> String
    func derivedDataPath(for project: Project, version: Version) -> String
    func archivePath(for project: Project, version: Version) -> String
    func exportPath(for project: Project, version: Version) -> String?
}

struct XcodeBuildPathManagerLive: XcodeBuildPathManager {
    var rootURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        .first!
        .appending(path: "xcode-builder")
    }

    func rootURL(for project: Project, version: Version) -> URL {
        rootURL
            .appending(path: project.name)
            .appending(path: version.version)
            .appending(path: version.tagName)
    }

    func projectPath(for project: Project, version: Version) -> String {
        rootURL(for: project, version: version)
            .appending(path: "Project")
            .path()
    }

    func xcodeprojPath(for project: Project, version: Version) -> String {
        rootURL(for: project, version: version)
            .appending(path: "\(project.xcodeprojName).xcodeproj")
            .path()
    }

    func derivedDataPath(for project: Project, version: Version) -> String {
        rootURL(for: project, version: version)
            .appending(path: "DerivedData")
            .appending(path: "\(project.name)_\(version.string)")
            .path()
    }

    func archivePath(for project: Project, version: Version) -> String {
        rootURL(for: project, version: version)
            .appending(path: "Archives")
            .appending(path: "\(version.tagName).xcarchive")
            .path()
    }

    func exportPath(for project: Project, version: Version) -> String? {
        rootURL(for: project, version: version)
            .appending(path: "Exports")
            .appending(path: "\(version.tagName)")
            .path()
    }
}

public struct XcodeBuildPathManagerKey: DependencyKey {
    public static let liveValue: XcodeBuildPathManager = XcodeBuildPathManagerLive()
}

public extension DependencyValues {
    var xcodeBuildPathManager: XcodeBuildPathManager {
        get { self[XcodeBuildPathManagerKey.self] }
        set { self[XcodeBuildPathManagerKey.self] = newValue }
    }
}
