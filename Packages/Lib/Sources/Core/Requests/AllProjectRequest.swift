import Foundation
import SharingGRDB
import GRDB

public struct AllProjectRequest: FetchKeyRequest {
    public struct Value: Sendable {
        public var projects: [Project] = []
        public var schemes: [String: [Scheme]] = [:]

        public init(projects: [Project] = [], schemes: [String: [Scheme]] = [:]) {
            self.projects = projects
            self.schemes = schemes
        }
    }
    
    public init() {}
    
    public func fetch(_ db: Database) throws -> Value {
        // Use join to get project-scheme pairs, sorted by project creation date
        let projectSchemePairs = try Project.all
            .join(Scheme.all, on: { $0.bundleIdentifier == $1.projectBundleIdentifier })
            .order(by: \.createdAt)
            .fetchAll(db)
        
        // Extract unique projects and group schemes by project
        var projectsSet: Set<Project> = []
        var schemesByProject: [String: [Scheme]] = [:]
        
        for (project, scheme) in projectSchemePairs {
            projectsSet.insert(project)
            schemesByProject[project.bundleIdentifier, default: []].append(scheme)
        }
        
        return Value(
            projects: Array(projectsSet),
            schemes: schemesByProject
        )
    }
}
