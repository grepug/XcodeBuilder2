import Foundation
import SharingGRDB
import GRDB
import Core

public struct DatabaseManager {
    
    public init() {}

    public static func setupDatabase(at url: URL) throws -> DatabaseWriter {
        let dbURL = url.appendingPathExtension("sqlite")
        let dbWriter = try DatabasePool(path: dbURL.path())

        try Self.runMigrations(dbWriter)
        return dbWriter
    }

    public static func setupInMemoryDatabase() throws -> DatabaseWriter {
        let dbWriter = try DatabaseQueue()
        try Self.runMigrations(dbWriter)
        return dbWriter
    }
    
    /// Instance method for running migrations (for testing)
    public func runMigrations(using database: DatabaseWriter) throws {
        try Self.runMigrations(database)
    }

    public static func runMigrations(_ dbWriter: DatabaseWriter) throws {
        var migrator = DatabaseMigrator()

        migrator.registerMigration("v1.0") { db in
            // Projects table
            try #sql(
                """
                CREATE TABLE "projects" (
                    "bundle_identifier" TEXT PRIMARY KEY NOT NULL,
                    "name" TEXT NOT NULL,
                    "display_name" TEXT NOT NULL,
                    "git_repo_url" TEXT NOT NULL,
                    "xcodeproj_name" TEXT NOT NULL,
                    "working_directory" TEXT NOT NULL,
                    "created_at" TEXT NOT NULL
                )
                """
            ).execute(db)

            // Schemes table
            try #sql(
                """
                CREATE TABLE "schemes" (
                    "id" TEXT PRIMARY KEY NOT NULL,
                    "project_bundle_identifier" TEXT NOT NULL,
                    "name" TEXT NOT NULL,
                    "platforms" TEXT NOT NULL,
                    "order" INTEGER NOT NULL,
                    FOREIGN KEY("project_bundle_identifier") REFERENCES "projects"("bundle_identifier") ON DELETE CASCADE
                )
                """
            ).execute(db)

            // Builds table
            try #sql(
                """
                CREATE TABLE "builds" (
                    "id" TEXT PRIMARY KEY NOT NULL,
                    "scheme_id" TEXT NOT NULL,
                    "version_string" TEXT NOT NULL,
                    "build_number" TEXT NOT NULL,
                    "created_at" TEXT NOT NULL,
                    "start_date" TEXT,
                    "end_date" TEXT,
                    "export_options" TEXT NOT NULL,
                    "status" TEXT NOT NULL,
                    "progress" REAL NOT NULL,
                    "commit_hash" TEXT NOT NULL,
                    "device_model" TEXT NOT NULL,
                    "os_version" TEXT NOT NULL,
                    "memory" TEXT NOT NULL,
                    "processor" TEXT NOT NULL,
                    FOREIGN KEY("scheme_id") REFERENCES "schemes"("id") ON DELETE CASCADE
                )
                """
            ).execute(db)

            // Build logs table
            try #sql(
                """
                CREATE TABLE "build_logs" (
                    "id" TEXT PRIMARY KEY NOT NULL,
                    "build_id" TEXT NOT NULL,
                    "category" TEXT NOT NULL,
                    "level" TEXT NOT NULL,
                    "content" TEXT NOT NULL,
                    "created_at" TEXT NOT NULL,
                    FOREIGN KEY("build_id") REFERENCES "builds"("id") ON DELETE CASCADE
                )
                """
            ).execute(db)

            // Crash logs table
            try #sql(
                """
                CREATE TABLE "crash_logs" (
                    "incident_identifier" TEXT PRIMARY KEY NOT NULL,
                    "is_main_thread" INTEGER NOT NULL,
                    "created_at" TEXT NOT NULL,
                    "build_id" TEXT NOT NULL,
                    "content" TEXT NOT NULL,
                    "hardware_model" TEXT NOT NULL,
                    "process" TEXT NOT NULL,
                    "role" TEXT NOT NULL,
                    "date_time" TEXT NOT NULL,
                    "launch_time" TEXT NOT NULL,
                    "os_version" TEXT NOT NULL,
                    "note" TEXT,
                    "fixed" INTEGER NOT NULL,
                    "priority" TEXT NOT NULL,
                    FOREIGN KEY("build_id") REFERENCES "builds"("id") ON DELETE CASCADE
                )
                """
            ).execute(db)
        }

        try migrator.migrate(dbWriter)
    }

    /// Create performance indexes for common queries
    private static func createIndexes(in db: Database) throws {
        // Index for project queries
        try #sql("CREATE INDEX IF NOT EXISTS idx_projects_created_at ON projects(created_at DESC)").execute(db)
        
        // Index for scheme queries by project
        try #sql("CREATE INDEX IF NOT EXISTS idx_schemes_project ON schemes(project_bundle_identifier, \"order\")").execute(db)
        
        // Index for build queries by scheme and date
        try #sql("CREATE INDEX IF NOT EXISTS idx_builds_scheme_date ON builds(scheme_id, created_at DESC)").execute(db)
        
        // Index for build logs by build and level
        try #sql("CREATE INDEX IF NOT EXISTS idx_build_logs_build ON build_logs(build_id, level, created_at)").execute(db)
        
        // Index for crash logs by build
        try #sql("CREATE INDEX IF NOT EXISTS idx_crash_logs_build ON crash_logs(build_id, created_at DESC)").execute(db)
    }

    /// Run database migrations at the specified URL
    /// This method is public to allow external initialization
    public func runMigrations(at databaseURL: URL) async throws {
        let dbWriter = try DatabasePool(path: databaseURL.path())
        try await dbWriter.write { db in
            try Self.runMigrations(dbWriter)
            try Self.createIndexes(in: db)
        }
    }
}
