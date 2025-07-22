import Foundation
import SharingGRDB
import GRDB
import Dependencies
import Core

/// Internal data service for scheme CRUD operations
/// This service handles all database operations related to schemes
internal struct SchemeDataService {
    @Dependency(\.defaultDatabase) var db
    
    init() {}
    
    /// Create a new scheme in the database
    func createScheme(_ scheme: SchemeValue) async throws {
        try await db.write { db in
            let dbScheme = Scheme(
                id: scheme.id,
                projectBundleIdentifier: scheme.projectBundleIdentifier,
                name: scheme.name,
                platforms: scheme.platforms,
                order: scheme.order
            )
            try Scheme.insert { dbScheme }.execute(db)
        }
    }
    
    /// Update an existing scheme in the database
    func updateScheme(_ scheme: SchemeValue) async throws {
        try await db.write { db in
            let dbScheme = Scheme(
                id: scheme.id,
                projectBundleIdentifier: scheme.projectBundleIdentifier,
                name: scheme.name,
                platforms: scheme.platforms,
                order: scheme.order
            )
            try Scheme.update(dbScheme).execute(db)
        }
    }
    
    /// Delete a scheme from the database
    func deleteScheme(id: UUID) async throws {
        try await db.write { db in
            _ = try Scheme
                .where { $0.id == id }
                .delete()
                .execute(db)
        }
    }
}
