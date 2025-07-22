import Foundation
import SharingGRDB
import GRDB
import Dependencies
import Core

/// Internal data service for build CRUD operations
/// This service handles all database operations related to builds
internal struct BuildDataService {
    @Dependency(\.defaultDatabase) var db
    
    init() {}
    
    /// Create a new build in the database
    func createBuild(_ build: BuildModelValue) async throws {
        try await db.write { db in
            let version = Version(version: build.versionString, buildNumber: build.buildNumber, commitHash: build.commitHash)
            let deviceMetadata = build.deviceMetadata

            let dbBuild = BuildModel(
                id: build.id,
                schemeId: build.schemeId,
                version: version,
                createdAt: build.createdAt,
                startDate: build.startDate,
                endDate: build.endDate,
                exportOptions: build.exportOptions,
                commitHash: build.commitHash,
                status: BuildStatus(rawValue: build.status.rawValue) ?? .queued,
                progress: build.progress,
                deviceMetadata: deviceMetadata
            )
            try BuildModel.insert { dbBuild }.execute(db)
        }
    }
    
    /// Update an existing build in the database
    func updateBuild(_ build: BuildModelValue) async throws {
        try await db.write { db in
            let version = Version(version: build.versionString, buildNumber: build.buildNumber, commitHash: build.commitHash)
            let deviceMetadata = build.deviceMetadata
            
            let dbBuild = BuildModel(
                id: build.id,
                schemeId: build.schemeId,
                version: version,
                createdAt: build.createdAt,
                startDate: build.startDate,
                endDate: build.endDate,
                exportOptions: build.exportOptions,
                commitHash: build.commitHash,
                status: BuildStatus(rawValue: build.status.rawValue) ?? .queued,
                progress: build.progress,
                deviceMetadata: deviceMetadata
            )
            try BuildModel.update(dbBuild).execute(db)
        }
    }
    
    /// Delete a build from the database
    func deleteBuild(id: UUID) async throws {
        try await db.write { db in
            _ = try BuildModel
                .where { $0.id == id }
                .delete()
                .execute(db)
        }
    }
}
