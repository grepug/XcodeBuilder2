import Foundation
import Dependencies

public protocol XcodeBuildPathManager: Sendable {
    func projectURL(for project: Project, version: Version) -> URL
    func xcodeprojURL(for project: Project, version: Version) -> URL
    func derivedDataURL(for project: Project, version: Version) -> URL
    func archiveURL(for project: Project, version: Version) -> URL
    func exportURL(for project: Project, version: Version) -> URL?
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
            .appending(path: version.displayString)
    }

    func projectURL(for project: Project, version: Version) -> URL {
        rootURL(for: project, version: version)
            .appending(path: "Project")
    }

    func xcodeprojURL(for project: Project, version: Version) -> URL {
        URL(filePath: projectURL(for: project, version: version).path())
            .appending(path: project.xcodeprojName)
            .appendingPathExtension("xcodeproj")
    }

    func derivedDataURL(for project: Project, version: Version) -> URL {
        rootURL(for: project, version: version)
            .appending(path: "DerivedData")
    }

    func archiveURL(for project: Project, version: Version) -> URL {
        rootURL(for: project, version: version)
            .appending(path: "Archives")
            .appending(path: "\(version.displayString).xcarchive")
    }

    func exportURL(for project: Project, version: Version) -> URL? {
        rootURL(for: project, version: version)
            .appending(path: "Exports")
            .appending(path: "\(version.displayString)")
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
