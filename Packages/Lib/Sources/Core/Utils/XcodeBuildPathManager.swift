import Foundation
import Dependencies

public protocol XcodeBuildPathManager: Sendable {
    func rootURL(for project: Project, build: BuildModel) -> URL
    func projectURL(for project: Project, build: BuildModel) -> URL
    func xcodeprojURL(for project: Project, build: BuildModel) -> URL
    func derivedDataURL(for project: Project, build: BuildModel) -> URL
    func archiveURL(for project: Project, build: BuildModel) -> URL
    func exportURL(for project: Project, build: BuildModel) -> URL?
}

struct XcodeBuildPathManagerLive: XcodeBuildPathManager {
    var rootURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        .first!
        .appending(path: "xcode-builder")
    }

    func rootURL(for project: Project, build: BuildModel) -> URL {
        rootURL
            .appending(path: project.name)
            .appending(path: build.projectDirName)
    }

    func projectURL(for project: Project, build: BuildModel) -> URL {
        rootURL(for: project, build: build)
            .appending(path: "Project")
    }

    func xcodeprojURL(for project: Project, build: BuildModel) -> URL {
        URL(filePath: projectURL(for: project, build: build).path())
            .appending(path: project.xcodeprojName)
            .appendingPathExtension("xcodeproj")
    }

    func derivedDataURL(for project: Project, build: BuildModel) -> URL {
        rootURL(for: project, build: build)
            .appending(path: "DerivedData")
    }

    func archiveURL(for project: Project, build: BuildModel) -> URL {
        rootURL(for: project, build: build)
            .appending(path: "Archives")
            .appending(path: "\(build.version.displayString).xcarchive")
    }

    func exportURL(for project: Project, build: BuildModel) -> URL? {
        rootURL(for: project, build: build)
            .appending(path: "Exports")
            .appending(path: "\(build.version.displayString)")
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
