import Foundation
import SharingGRDB
import GRDB
import Dependencies
import Core

/// Internal data service for project CRUD operations
/// This service handles all database operations related to projects
internal struct ProjectDataService {
    @Dependency(\.defaultDatabase) var db
    
    init() {}
    
    /// Create a new project in the database
    func createProject(_ project: ProjectValue) async throws {
        try await db.write { db in
            let dbProject = Project(
                bundleIdentifier: project.bundleIdentifier,
                createdAt: project.createdAt,
                name: project.name,
                displayName: project.displayName,
                gitRepoURL: project.gitRepoURL,
                xcodeprojName: project.xcodeprojName,
                workingDirectoryURL: project.workingDirectoryURL
            )

            try Project.insert { dbProject }.execute(db)
        }
    }
    
    /// Update an existing project in the database
    func updateProject(_ project: ProjectValue) async throws {
        try await db.write { db in
            try Project
                .where { $0.bundleIdentifier == project.bundleIdentifier }
                .update { 
                    $0.bundleIdentifier = project.bundleIdentifier
                    $0.createdAt = project.createdAt
                    $0.name = project.name
                    $0.displayName = project.displayName
                    $0.gitRepoURL = project.gitRepoURL
                    $0.xcodeprojName = project.xcodeprojName
                    $0.workingDirectoryURL = project.workingDirectoryURL
                 }
                .execute(db)
        }
    }
    
    /// Delete a project from the database
    func deleteProject(id: String) async throws {
        try await db.write { db in
            _ = try Project
                .where { $0.bundleIdentifier == id }
                .delete()
                .execute(db)
        }
    }
}
