import Foundation

// MARK: - Build commands for Xcode projects

public struct XcodeBuildCommand: Sendable {
    public enum Kind: Codable, Sendable {
        case archive, exportArchive, resolvePackageDependencies

        var command: String {
            switch self {
            case .archive: "clean archive"
            case .exportArchive: "-exportArchive"
            case .resolvePackageDependencies: "-resolvePackageDependencies"
            }
        }
    }

    let kind: Kind
    var scheme: SchemeValue
    var version: Version
    var platform: Platform
    var exportOption: ExportOption?
    let projectURL: URL
    let archiveURL: URL
    let derivedDataURL: URL
    let exportURL: URL?

    var sdkString: String {
        guard kind != .exportArchive else {
            return ""
        }

        return platform.destination.commandString
    }

    var exportOptionsPlist: String {
        guard let path = exportOption?.plistURL.path(percentEncoded: false) else {
            return ""
        }

        return "-exportOptionsPlist \"\(path)\""
    }

    var schemeString: String {
        guard kind != .exportArchive else {
            return ""
        }

        return "-scheme \"\(scheme.name)\""
    }
    
    var derivedDataPathString: String {
        guard kind != .exportArchive else {
            return ""
        }
        
        return "-derivedDataPath \(derivedDataURL.path())"
    }

    public var string: String {
        """
        xcodebuild \
        -project \(projectURL.path()) \
        -skipMacroValidation \
        -skipPackagePluginValidation \
        \(derivedDataPathString) \
        -archivePath \(archiveURL.path()) \
        \(schemeString) \
        \(sdkString) \
        \(exportOptionsPlist) \
        \(exportURL.map { "-exportPath \($0.path())" } ?? "") \
        \(kind.command)
        """
    }
    
    public init(kind: Kind, scheme: SchemeValue, version: Version, platform: Platform, exportOption: ExportOption? = nil, projectURL: URL, archiveURL: URL, derivedDataURL: URL, exportURL: URL?) {
        self.kind = kind
        self.scheme = scheme
        self.version = version
        self.platform = platform
        self.exportOption = exportOption
        self.projectURL = projectURL
        self.archiveURL = archiveURL
        self.derivedDataURL = derivedDataURL
        self.exportURL = exportURL
    }
}
