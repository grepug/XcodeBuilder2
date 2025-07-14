import Foundation

public struct GitCommand {
    let path: String

    func clone(remoteURL: URL, branch: String? = nil, tag: String? = nil, onlyLatestDepth: Bool = false) async throws {
        var command = "git clone \(remoteURL.absoluteString) \(path)"
        
        if let branch = branch {
            command += " --branch \(branch)"
        }
        if let tag = tag {
            command += " --tag \(tag)"
        }
        if onlyLatestDepth {
            command += " --depth 1"
        }

        try await runShellCommandComplete(command)
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
