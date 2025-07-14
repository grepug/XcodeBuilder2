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

    public var string: String {
        "\(version).\(buildNumber)"
    }

    public var tagName: String {
        "v\(version)_\(buildNumber)"
    }
    
    public init(version: String, buildNumber: Int) {
        self.version = version
        self.buildNumber = buildNumber
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
    let projectPath: String
    let archivePath: String
    let derivedDataPath: String
    let exportPath: String?

    var sdkString: String {
        guard kind != .exportArchive else {
            return ""
        }

        return platform.destination.commandString
    }

    var exportOptionsPlist: String {
        guard let path = exportOption?.plistURL.path() else {
            return ""
        }

        return "-exportOptionsPlist \(path)"
    }

    var schemeString: String {
        guard kind != .exportArchive else {
            return ""
        }

        return "-scheme \"\(scheme.name)\""
    }

    public var string: String {
        """
        xcodebuild \
        -project \(projectPath) \
        -skipMacroValidation \
        -skipPackagePluginValidation \
        -derivedDataPath \(derivedDataPath) \
        -archivePath \(archivePath) \
        \(schemeString) \
        \(sdkString) \
        \(exportOptionsPlist) \
        \(exportPath.map { "-exportPath \($0)" } ?? "") \
        \(kind.command)
        """
    }
    
    public init(kind: Kind, scheme: Scheme, version: Version, platform: Platform, exportOption: ExportOption? = nil, projectPath: String, archivePath: String, derivedDataPath: String, exportPath: String?) {
        self.kind = kind
        self.scheme = scheme
        self.version = version
        self.platform = platform
        self.exportOption = exportOption
        self.projectPath = projectPath
        self.archivePath = archivePath
        self.derivedDataPath = derivedDataPath
        self.exportPath = exportPath
    }
}
