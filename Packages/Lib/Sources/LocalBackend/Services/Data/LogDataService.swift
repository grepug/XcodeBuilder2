import Foundation
import SharingGRDB
import GRDB
import Dependencies
import Core

/// Internal data service for log CRUD operations
/// This service handles all database operations related to build logs and crash logs
internal struct LogDataService {
    @Dependency(\.defaultDatabase) var db
    
    init() {}
    
    /// Create a new build log in the database
    func createBuildLog(_ log: BuildLogValue) async throws {
        try await db.write { db in
            let dbLog = BuildLog(
                id: log.id,
                buildId: log.buildId,
                category: log.category,
                content: log.content,
                level: log.level
            )
            try BuildLog.insert { dbLog }.execute(db)
        }
    }
    
    /// Delete all build logs for a specific build
    func deleteBuildLogs(buildId: UUID) async throws {
        try await db.write { db in
            _ = try BuildLog
                .where { $0.buildId == buildId }
                .delete()
                .execute(db)
        }
    }
    
    /// Create a new crash log in the database
    func createCrashLog(_ crashLog: CrashLogValue) async throws {
        try await db.write { db in
            let role = CrashLogRole(rawValue: crashLog.role.rawValue) ?? .foreground
            let priority = CrashLogPriority(rawValue: crashLog.priority.rawValue) ?? .medium
            
            let dbCrashLog = CrashLog(
                incidentIdentifier: crashLog.incidentIdentifier,
                isMainThread: crashLog.isMainThread,
                createdAt: crashLog.createdAt,
                buildId: crashLog.buildId,
                content: crashLog.content,
                hardwareModel: crashLog.hardwareModel,
                process: crashLog.process,
                role: role,
                dateTime: crashLog.dateTime,
                launchTime: crashLog.launchTime,
                osVersion: crashLog.osVersion,
                note: crashLog.note,
                fixed: crashLog.fixed,
                priority: priority
            )
            try CrashLog.insert { dbCrashLog }.execute(db)
        }
    }
    
    /// Update an existing crash log in the database
    func updateCrashLog(_ crashLog: CrashLogValue) async throws {
        try await db.write { db in
            let role = CrashLogRole(rawValue: crashLog.role.rawValue) ?? .foreground
            let priority = CrashLogPriority(rawValue: crashLog.priority.rawValue) ?? .medium
            
            let dbCrashLog = CrashLog(
                incidentIdentifier: crashLog.incidentIdentifier,
                isMainThread: crashLog.isMainThread,
                createdAt: crashLog.createdAt,
                buildId: crashLog.buildId,
                content: crashLog.content,
                hardwareModel: crashLog.hardwareModel,
                process: crashLog.process,
                role: role,
                dateTime: crashLog.dateTime,
                launchTime: crashLog.launchTime,
                osVersion: crashLog.osVersion,
                note: crashLog.note,
                fixed: crashLog.fixed,
                priority: priority
            )
            try CrashLog.update(dbCrashLog).execute(db)
        }
    }
    
    /// Delete a crash log from the database
    func deleteCrashLog(id: String) async throws {
        try await db.write { db in
            _ = try CrashLog
                .where { $0.incidentIdentifier == id }
                .delete()
                .execute(db)
        }
    }
}
