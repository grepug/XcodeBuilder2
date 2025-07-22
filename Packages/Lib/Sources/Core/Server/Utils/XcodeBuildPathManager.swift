import Foundation
import Dependencies


public protocol XcodeBuildPathManager: Sendable {
    var rootURL: URL { get }
    func rootURL(for project: ProjectValue, build: BuildModelValue) -> URL
    func projectURL(for project: ProjectValue, build: BuildModelValue) -> URL
    func xcodeprojURL(for project: ProjectValue, build: BuildModelValue) -> URL
    func derivedDataURL(for project: ProjectValue, build: BuildModelValue) -> URL
    func archiveURL(for project: ProjectValue, build: BuildModelValue) -> URL
    func exportURL(for project: ProjectValue, build: BuildModelValue) -> URL?
    func findFile(named fileName: String, in searchURL: URL) -> URL?
}

struct XcodeBuildPathManagerLive: XcodeBuildPathManager {
    var rootURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        .first!
        .appending(path: "xcode-builder")
    }

    func rootURL(for project: ProjectValue, build: BuildModelValue) -> URL {
        rootURL
            .appending(path: project.name)
            .appending(path: build.projectDirName)
    }

    func projectURL(for project: ProjectValue, build: BuildModelValue) -> URL {
        rootURL(for: project, build: build)
            .appending(path: "ProjectValue")
    }

    func xcodeprojURL(for project: ProjectValue, build: BuildModelValue) -> URL {
        URL(filePath: projectURL(for: project, build: build).path())
            .appending(path: project.xcodeprojName)
            .appendingPathExtension("xcodeproj")
    }

    func derivedDataURL(for project: ProjectValue, build: BuildModelValue) -> URL {
        rootURL(for: project, build: build)
            .appending(path: "DerivedData")
    }

    func archiveURL(for project: ProjectValue, build: BuildModelValue) -> URL {
        rootURL(for: project, build: build)
            .appending(path: "Archives")
            .appending(path: "\(build.version.displayString).xcarchive")
    }

    func exportURL(for project: ProjectValue, build: BuildModelValue) -> URL? {
        rootURL(for: project, build: build)
            .appending(path: "Exports")
            .appending(path: "\(build.version.displayString)")
    }
    
    func findFile(named fileName: String, in searchURL: URL) -> URL? {
        let fileManager = FileManager.default
        
        // First check if the search URL exists
        guard fileManager.fileExists(atPath: searchURL.path()) else {
            return nil
        }
        
        // Use FileManager.enumerator to recursively search for the file
        if let enumerator = fileManager.enumerator(at: searchURL, 
                                                 includingPropertiesForKeys: [.isRegularFileKey], 
                                                 options: [.skipsHiddenFiles, .skipsPackageDescendants]) {
            for case let fileURL as URL in enumerator {
                if fileURL.lastPathComponent == fileName {
                    return fileURL
                }
            }
        }
        
        return nil
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
