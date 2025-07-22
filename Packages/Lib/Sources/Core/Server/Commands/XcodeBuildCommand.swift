import Foundation

public struct Version: Sendable, Hashable, Codable, Comparable {
    public static func < (lhs: Version, rhs: Version) -> Bool {
        if lhs.version == rhs.version {
            return lhs.buildNumber < rhs.buildNumber
        }
        return lhs.version < rhs.version
    }
    
    public var version: String
    public var buildNumber: Int
    public var commitHash: String

    public var displayString: String {
        "\(tagName)_\(commitHash.prefix(6))"
    }
    
    public var tagName: String {
        "v\(version)_\(buildNumber)"
    }
    
    public init(version: String = "0.0.0", buildNumber: Int = 0, commitHash: String = "") {
        self.version = version
        self.buildNumber = buildNumber
        self.commitHash = commitHash
    }
    
    public func validate() throws(VersionValidationError) {
        // Basic validation for version format
        let versionRegex = #"^\d+\.\d+\.\d+$"#
        let buildNumberRegex = #"^\d+$"#
        
        let versionMatches = version.range(of: versionRegex, options: .regularExpression) != nil
        let buildNumberMatches = String(buildNumber).range(of: buildNumberRegex, options: .regularExpression) != nil
        
        guard versionMatches else {
            throw VersionValidationError.invalidVersionFormat
        }
        
        guard buildNumberMatches else {
            throw VersionValidationError.invalidBuildNumberFormat
        }
    }
}

public enum VersionValidationError: LocalizedError {
    case invalidVersionFormat
    case invalidBuildNumberFormat

    public var errorDescription: String? {
        switch self {
        case .invalidVersionFormat:
            return "Invalid version format. Expected format is 'X.Y.Z'."
        case .invalidBuildNumberFormat:
            return "Invalid build number format. Expected a numeric value."
        }
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
