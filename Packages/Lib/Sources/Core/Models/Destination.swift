import Foundation
import SharingGRDB

public enum Platform: String, Codable, Sendable, Hashable, Identifiable, CaseIterable, QueryBindable {
    case iOS
    case macOS
    case macCatalyst
    
    public var id: Self {
        self
    }

    public var destination: Destination {
        switch self {
        case .iOS: .iOS
        case .macOS: .macOS
        case .macCatalyst: .macCatalyst
        }
    }
}

public struct Destination: Codable, Sendable, Hashable, Identifiable {
    enum SDK: String, Codable {
        case iphoneos
        case macosx
    }

    let name: String
    let sdk: SDK
    let commandString: String

    public var id: String {
        name
    }

    static let iOS = Destination(
        name: "iOS", 
        sdk: .iphoneos,
        commandString: "-destination \"generic/platform=iOS\"",
    )

    static let macOS = Destination(
        name: "macOS",
        sdk: .macosx,
        commandString: "-sdk macosx"
    )

    static let macCatalyst = Destination(
        name: "macCatalyst",
        sdk: .macosx,
        commandString: "-sdk macosx SUPPORTS_MACCATALYST=YES"
    )
}
