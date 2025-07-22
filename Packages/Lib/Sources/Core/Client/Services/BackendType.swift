import Foundation

/// Protocol defining different backend types
public protocol BackendType: Sendable {
    /// Create a backend service instance
    func createService() throws -> any BackendService

    /// Display name for the backend type
    var displayName: String { get }

    /// Unique identifier for the backend type
    var identifier: String { get }
}