import Foundation

public enum ExportOption: String, Codable, Sendable, CaseIterable, Identifiable, Comparable {
    case releaseTesting = "Release Testing"
    case appStore = "App Store"
    
    public static func < (lhs: ExportOption, rhs: ExportOption) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
    
    public var id: Self {
        self
    }

    public var message: String {
        switch self {
        case .releaseTesting:
            return "测试包，请在 https://ipa-tester.zeabur.app 查看"
        case .appStore:
            return "正式包，请在 TestFlight 中查看"
        }
    }

    public var plistURL: URL {
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            .first!.appendingPathComponent("XcodeBuilder2")
            .appending(component: "exportOptions_\(rawValue).plist")
        
        let data = plistContent.data(using: .utf8)!
        try! data.write(to: url)

        return url
    }

    public var plistContent: String {
        switch self {
        case .releaseTesting:
            """
            <?xml version="1.0" encoding="UTF-8"?>
            <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
            <plist version="1.0">
            <dict>
                <key>method</key>
                <string>release-testing</string>
            </dict>
            </plist>

            """
        case .appStore:
            """
            <?xml version="1.0" encoding="UTF-8"?>
            <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
            <plist version="1.0">
            <dict>
                <key>iCloudContainerEnvironmnet</key>
                <string>Production</string>
                <key>method</key>
                <string>app-store-connect</string>
                <key>destination</key>
                <string>upload</string>
            </dict>
            </plist>
            """
        }
    }
}
