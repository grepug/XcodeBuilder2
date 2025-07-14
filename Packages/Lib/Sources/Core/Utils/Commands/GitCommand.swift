import Foundation

struct GitCommand {
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
}