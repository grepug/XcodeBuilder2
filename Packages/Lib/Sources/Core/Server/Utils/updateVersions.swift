import Foundation

func updateVersions(url: URL, version: String, buildNumber: String) {
    // Update Info.plist files
    let fileManager = FileManager.default
    if let enumerator = fileManager.enumerator(at: url, includingPropertiesForKeys: [.nameKey]) {
        for case let fileURL as URL in enumerator {
            if fileURL.lastPathComponent == "Info.plist" {
                print("Processing \(fileURL.path)...")
                if let plist = NSMutableDictionary(contentsOf: fileURL) {
                    plist["CFBundleShortVersionString"] = version
                    plist["CFBundleVersion"] = buildNumber
                    plist.write(to: fileURL, atomically: true)
                    print("  Updated Info.plist Version: \(version), Build: \(buildNumber)")
                }
            }
        }
    }

    // Update project.pbxproj files
    if let enumerator = fileManager.enumerator(at: url, includingPropertiesForKeys: [.nameKey]) {
        for case let fileURL as URL in enumerator {
            if fileURL.lastPathComponent == "project.pbxproj" {
                print("Processing \(fileURL.path)...")
                do {
                    var content = try String(contentsOf: fileURL, encoding: .utf8)
                    // Update MARKETING_VERSION
                    content = content.replacingOccurrences(
                        of: #"MARKETING_VERSION = [^;]+"#,
                        with: "MARKETING_VERSION = \(version)",
                        options: .regularExpression
                    )
                    // Update CURRENT_PROJECT_VERSION
                    content = content.replacingOccurrences(
                        of: #"CURRENT_PROJECT_VERSION = [^;]+"#,
                        with: "CURRENT_PROJECT_VERSION = \(buildNumber)",
                        options: .regularExpression
                    )
                    try content.write(to: fileURL, atomically: true, encoding: .utf8)
                    print("  Updated \(fileURL.lastPathComponent) with Version: \(version), Build: \(buildNumber)")
                } catch {
                    print("Error processing \(fileURL.path): \(error)")
                }
            }
        }
    }

    print("All project files updated successfully!")
}
