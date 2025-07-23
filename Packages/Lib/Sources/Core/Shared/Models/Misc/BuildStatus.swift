import Foundation

public enum BuildStatus: String, Codable, Sendable, Hashable {
    case queued
    case running
    case completed
    case failed
    case cancelled
    
    public var title: String {
        switch self {
        case .queued: "Queued"
        case .running: "Running"
        case .completed: "Completed"
        case .failed: "Failed"
        case .cancelled: "Cancelled"
        }
    }
}