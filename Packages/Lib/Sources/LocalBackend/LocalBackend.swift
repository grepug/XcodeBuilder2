// LocalBackend module exports
// Main entry point for LocalBackend functionality

import Foundation

// Re-export main types
@_exported import Core

// Export LocalBackend service and factory
public typealias LocalBackend = LocalBackendService
public typealias BackendFactory = LocalBackendFactory

// Export database manager for initialization
public typealias DatabaseConfig = DatabaseManager
