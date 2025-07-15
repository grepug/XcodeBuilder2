//
//  SharingDB.swift
//  XcodeBuilder2
//
//  Created by Kai Shao on 2025/7/14.
//


import Foundation
import SharingGRDB

extension DatabaseWriter where Self == DatabaseQueue {
    static func observableModelDatabase(path: DatabasePath) -> Self {
        let databaseQueue: DatabaseQueue

        switch path {
        case .stored(let path):
            databaseQueue = try! DatabaseQueue(path: path)
        case .inMemory:
            databaseQueue = try! DatabaseQueue()
        }
        
        print("database path", databaseQueue.path)
        
        var migrator = DatabaseMigrator()
        
        migrator.registerMigration("Create tables") { db in
            try #sql(
                """
                CREATE TABLE "projects" (
                    "bundle_identifier" TEXT PRIMARY KEY NOT NULL,
                    "name" TEXT NOT NULL,
                    "display_name" TEXT NOT NULL,
                    "git_repo_url" TEXT NOT NULL,
                    "xcodeproj_name" TEXT NOT NULL,
                    "created_at" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
                )
                """
            )
            .execute(db)

            try #sql(
                """
                CREATE TABLE "schemes" (
                    "id" TEXT PRIMARY KEY NOT NULL,
                    "name" TEXT NOT NULL,
                    "platforms" TEXT NOT NULL,
                    "project_bundle_identifier" TEXT NOT NULL,
                    "order" INTEGER NOT NULL,
                    FOREIGN KEY("project_bundle_identifier") REFERENCES "projects"(bundle_identifier) ON DELETE CASCADE
                )
                """
            )
            .execute(db)
            
            try #sql(
                """
                CREATE TABLE "builds" (
                    "id" TEXT PRIMARY KEY NOT NULL,
                    "scheme_id" TEXT NOT NULL,
                    "version_string" TEXT NOT NULL,
                    "build_number" INTEGER NOT NULL,
                    "created_at" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
                    "start_date" DATETIME,
                    "end_date" DATETIME,
                    "export_options" TEXT NOT NULL,
                    "status" TEXT NOT NULL DEFAULT 'queued',
                    FOREIGN KEY("scheme_id") REFERENCES "schemes"(id) ON DELETE CASCADE
                )
                """
            )
            .execute(db)
            
            try #sql(
                """
                CREATE TRIGGER prevent_platform_update
                BEFORE UPDATE OF platforms ON schemes
                FOR EACH ROW
                BEGIN
                    SELECT RAISE(ABORT, 'Cannot update platforms once created');
                END
                """
            )
            .execute(db)
        }

        migrator.registerMigration("Create build logs") { db in
            try #sql(
                """
                CREATE TABLE "buildLogs" (
                    "id" TEXT PRIMARY KEY NOT NULL,
                    "build_id" TEXT NOT NULL,
                    "level" TEXT NOT NULL,
                    "log_content" TEXT NOT NULL,
                    "created_at" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
                    FOREIGN KEY("build_id") REFERENCES "builds"(id) ON DELETE CASCADE
                )
                """
            )
            .execute(db)
        }

        migrator.registerMigration("Add progress to build") { db in
            try #sql(
                """
                ALTER TABLE "builds" ADD COLUMN "progress" REAL NOT NULL DEFAULT 0
                """
            )
            .execute(db)
        }

        migrator.registerMigration("Add category to build logs") { db in
            try #sql(
                """
                ALTER TABLE "buildLogs" ADD COLUMN "category" TEXT
                """
            )
            .execute(db)
        }

        try! migrator.migrate(databaseQueue)
        
        return databaseQueue
    }
}

public enum DatabasePath {
    case stored(path: String), inMemory
}

public func setupCacheDatabase(path: DatabasePath = .inMemory) {
    prepareDependencies { $0.defaultDatabase = .observableModelDatabase(path: path) }
}

