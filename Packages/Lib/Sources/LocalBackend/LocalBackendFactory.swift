import Foundation
import SharingGRDB
import GRDB
import Dependencies
import Core

/// Factory for creating LocalBackend instances with proper dependency injection
public struct LocalBackendFactory {
    
    /// Creates a LocalBackendService with dependency injection configured
    public static func createBackendService() -> LocalBackendService {
        return LocalBackendService()
    }
    
    /// Sets up the dependencies for LocalBackend usage
    /// This should be called during application initialization
    public static func configureDependencies(databaseURL: URL? = nil) async throws {
        // Setup the database URL - default to application support directory
        let dbURL = databaseURL ?? defaultDatabaseURL()
        
        // Create database manager and run migrations
        let databaseManager = DatabaseManager()
        try await databaseManager.runMigrations(at: dbURL)
        
        // Configure dependencies
        withDependencies {
            $0.defaultDatabase = .observableModelDatabase(path: .stored(path: dbURL.path()))
        } operation: {
            // Dependencies are now configured for the application
        }
    }
    
    /// Creates the default database URL in the application support directory
    private static func defaultDatabaseURL() -> URL {
        let applicationSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDirectory = applicationSupport.appendingPathComponent("XcodeBuilder2")
        
        // Create directory if it doesn't exist
        try? FileManager.default.createDirectory(at: appDirectory, withIntermediateDirectories: true)
        
        return appDirectory.appendingPathComponent("XcodeBuilder2.sqlite")
    }
}
