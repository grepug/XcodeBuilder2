//
//  SharingDB.swift
//  XcodeBuilder2
//
//  Created by Kai Shao on 2025/7/14.
//


import Foundation
import SharingGRDB
import Core

@Table
struct ProjectModel: Identifiable {
    var id: String {
        bundle_identifier
    }
    
    var bundle_identifier: String
    var name: String
    var display_name: String
    var git_repo_url: URL
    var xcodeproj_name: String
    var created_at: Date = .now
    
    func toProject() -> Project {
        Project(bundleIdentifier: bundle_identifier, name: name, displayName: display_name, gitRepoURL: git_repo_url, xcodeprojName: xcodeproj_name)
    }
    
    static func fromProject(_ project: Project) -> ProjectModel {
        ProjectModel(bundle_identifier: project.bundleIdentifier, name: project.name, display_name: project.displayName, git_repo_url: project.gitRepoURL, xcodeproj_name: project.xcodeprojName)
    }
}

@Table
struct SchemeModel {
    var id: UUID
    var project_bundle_identifier: String
    var name: String
    var platform_json_string: String // JSON encoded array of Platform
    var order: Int
    
    func toScheme() -> Scheme {
        let platforms: [Platform] = try! JSONDecoder().decode([Platform].self, from: Data(platform_json_string.utf8))
        return Scheme(id: id, name: name, platforms: platforms, order: order)
    }
    
    static func fromScheme(_ scheme: Scheme, projectBundleIdentifier: String) -> SchemeModel {
        let platformJsonString = try! JSONEncoder().encode(scheme.platforms).map { String(UnicodeScalar($0)) }.joined()
        return SchemeModel(id: scheme.id, project_bundle_identifier: projectBundleIdentifier, name: scheme.name, platform_json_string: platformJsonString, order: scheme.order)
    }
}

@Table
struct BuildModel: Identifiable {
    var id: UUID
    var scheme_id: UUID
    var version_string: String
    var build_number: Int
    var export_options: String
    var created_at: Date = .now
    var start_date: Date?
    var end_date: Date?
    
    var exportOptions: [ExportOption] {
        get {
            export_options.split(separator: ",").compactMap { optionString in
                ExportOption(rawValue: String(optionString))
            }
        }
        
        set {
            export_options = newValue.map { $0.rawValue }.joined(separator: ",")
        }
    }
    
    init(id: UUID = .init(), scheme_id: UUID = .init(), version_string: String = "1.0.0", build_number: Int = 1, created_at: Date = .now, start_date: Date? = nil, end_date: Date? = nil, export_options: [ExportOption] = []) {
        self.id = id
        self.scheme_id = scheme_id
        self.version_string = version_string
        self.build_number = build_number
        self.created_at = created_at
        self.start_date = start_date
        self.end_date = end_date
        self.export_options = export_options.map { $0.rawValue }.joined(separator: ",")
    }
}

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
                CREATE TABLE "projectModels" (
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
                CREATE TABLE "schemeModels" (
                    "id" TEXT PRIMARY KEY NOT NULL,
                    "name" TEXT NOT NULL,
                    "platform_json_string" TEXT NOT NULL,
                    "project_bundle_identifier" TEXT NOT NULL,
                    "order" INTEGER NOT NULL,
                    FOREIGN KEY("project_bundle_identifier") REFERENCES "projectModels"(bundle_identifier) ON DELETE CASCADE
                )
                """
            )
            .execute(db)
            
            try #sql(
                """
                CREATE TABLE "buildModels" (
                    "id" TEXT PRIMARY KEY NOT NULL,
                    "scheme_id" TEXT NOT NULL,
                    "version_string" TEXT NOT NULL,
                    "build_number" INTEGER NOT NULL,
                    "created_at" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
                    "start_date" DATETIME,
                    "end_date" DATETIME,
                    "export_options" TEXT NOT NULL,
                    FOREIGN KEY("scheme_id") REFERENCES "schemeModels"(id) ON DELETE CASCADE
                )
                """
            )
            .execute(db)
            
            try #sql(
                """
                CREATE TRIGGER prevent_platform_update
                BEFORE UPDATE OF platform_json_string ON schemeModels
                FOR EACH ROW
                BEGIN
                    SELECT RAISE(ABORT, 'Cannot update platform_json_string once created');
                END
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

