import Foundation
import SharingGRDB
import GRDB

public struct AllProjectRequest: FetchKeyRequest {
    public struct Value: Sendable {
        public var projects: [Project] = []
        public var versionStrings: [String: [String]] = [:]

        public init(projects: [Project] = [], versionStrings: [String: [String]] = [:]) {
            self.projects = projects
            self.versionStrings = versionStrings
        }
    }
    
    public init() {}
    
    public func fetch(_ db: Database) throws -> Value {
        // Get all projects ordered by creation date
        let projects = try Project.all.order(by: \.createdAt).fetchAll(db)
        
        // Get the latest version string for each project
        // This implements the SQL logic to find the latest build for each project
        var projectVersions: [String: [String]] = [:]
        
        for project in projects {
            // For each project, find its schemes and then all builds
            let schemes = try Scheme
                .where { $0.projectBundleIdentifier == project.bundleIdentifier }
                .fetchAll(db)
            
            let schemeIds = schemes.map { $0.id }
            
            // Find all builds for this project's schemes, ordered by creation date desc
            let builds = try BuildModel
                .where { $0.schemeId.in(schemeIds) }
                .order { $0.createdAt.desc() }
                .fetchAll(db)
                
            // Extract unique version strings and maintain descending order
            var uniqueVersions: [String] = []
            var seenVersions: Set<String> = []
            
            for build in builds {
                if !seenVersions.contains(build.versionString) {
                    uniqueVersions.append(build.versionString)
                    seenVersions.insert(build.versionString)
                }
            }
            
            projectVersions[project.bundleIdentifier] = uniqueVersions
        }
        
        return Value(
            projects: projects,
            versionStrings: projectVersions
        )
    }
}
