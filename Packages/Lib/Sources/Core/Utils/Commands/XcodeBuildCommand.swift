import Foundation

public struct Version: Sendable {
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

struct XcodeBuildCommand: Sendable {
    enum Kind: Codable {
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
    let project: Project
    var scheme: Scheme
    var version: Version
    var platform: Platform
    var exportOption: ExportOption?
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

    var string: String {
        """
        xcodebuild \
        -project \(project.path) \
        -skipMacroValidation \
        -skipPackagePluginValidation \
        \(derivedDataPath) \
        -archivePath \(archivePath) \
        \(schemeString) \
        \(sdkString) \
        \(exportOptionsPlist) \
        \(exportPath.map { "-exportPath \($0)" } ?? "") \
        \(kind.command)
        """
    }
}
