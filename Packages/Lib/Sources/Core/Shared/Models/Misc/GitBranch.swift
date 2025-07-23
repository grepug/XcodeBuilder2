import Foundation

/// Git branch information - shared value type for representing remote repository branches
/// Used by GitCommand.fetchBranches() and BackendService.fetchBranches() across Client/Server boundaries
public struct GitBranch: Sendable, Hashable {
    public let name: String
    public let commitHash: String
    
    public init(name: String, commitHash: String) {
        self.name = name
        self.commitHash = commitHash
    }
}
