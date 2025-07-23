import Foundation

/// Version information for builds
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
            return "Version must be in format x.y.z"
        case .invalidBuildNumberFormat:
            return "Build number must be a positive integer"
        }
    }
}
