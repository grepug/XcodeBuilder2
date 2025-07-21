import Foundation
import Sharing

// MARK: - SharedKey Protocol Conformance
// TODO: Complete SharedKey conformance implementation in Step 5

/*
extension BackendQuery: SharedKey {
    // This will be implemented in Step 5 when we integrate with the backend service
    // For now, this file serves as a placeholder for the required conformance
}
*/

// MARK: - Backend Query Error

public enum BackendQueryError: Error {
    case notImplemented
    case invalidConfiguration
}
