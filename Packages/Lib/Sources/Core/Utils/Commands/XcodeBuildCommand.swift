import Foundation

public struct Version: Sendable, Hashable, Codable, Comparable {
    public static func < (lhs: Version, rhs: Version) -> Bool {
        if lhs.version == rhs.version {
            return lhs.buildNumber < rhs.buildNumber
        }
        return lhs.version < rhs.version
    }
    
    public let version: String
    public let buildNumber: Int
    public let commitHash: String
    public let branchName: String?

    public var displayString: String {
        if let branchName = branchName {
            return "\(branchName)_\(commitHash.prefix(6))"
        } else {
            return "\(tagName)_\(commitHash.prefix(6))"
        }
    }
    
    public var tagName: String {
        "v\(version)_\(buildNumber)"
    }
    
    public init(version: String, buildNumber: Int, commitHash: String = "", branchName: String? = nil) {
        self.version = version
        self.buildNumber = buildNumber
        self.commitHash = commitHash
        self.branchName = branchName
    }
}

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
    var scheme: Scheme
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
    
    public init(kind: Kind, scheme: Scheme, version: Version, platform: Platform, exportOption: ExportOption? = nil, projectURL: URL, archiveURL: URL, derivedDataURL: URL, exportURL: URL?) {
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
