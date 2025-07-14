import Foundation

public struct GitCommand {
    let path: String

    func clone(remoteURL: URL, branch: String? = nil, tag: String? = nil, onlyLatestDepth: Bool = true) async throws {
        var command = "git clone \(remoteURL.absoluteString) \(path)"
        
        if let tag {
            command += " --branch \(tag)"
        } else if let branch {
            command += " --branch \(branch)"
        }
        
        if onlyLatestDepth {
            command += " --depth 1"
        }
        
        print("git command:", command)

        try await runShellCommand2(command).get()
    }
    
    public static func fetchVersions(remoteURL: URL) async throws -> [Version] {
        let command = "git ls-remote --tags \(remoteURL.absoluteString)"
        let res = try await runShellCommandComplete(command).combinedOutput
        let lines = res.split(separator: "\n")
        
        print("lines", lines)
        
        var versions: [Version] = []
        
        for line in lines {
            let matches = line.matches(of: #/v([\d\.]+.?)_(\d+)$/#)
            
            guard !matches.isEmpty else {
                continue
            }
            
            let versionString = String(matches[0].output.1)
            let buildNumberString = String(matches[0].output.2)
            
            guard let buildNumber = Int(buildNumberString) else {
                continue
            }
            
            let version = Version(version: versionString, buildNumber: buildNumber)
            
            versions.append(version)
        }
        
        return versions
    }
}

//xcodebuild -project /Users/kai/Documents/xcode-builder/context/v2.1.3_263/ContextApp.xcodeproj -skipMacroValidation -skipPackagePluginValidation -derivedDataPath /Users/kai/Documents/xcode-builder/context/v2.1.3_263/DerivedData -archivePath /Users/kai/Documents/xcode-builder/context/v2.1.3_263/Archives/v2.1.3_263.xcarchive -scheme "Beta Release" -destination "generic/platform=iOS"  -exportPath /Users/kai/Documents/xcode-builder/context/v2.1.3_263/Exports/v2.1.3_263 -resolvePackageDependencies
