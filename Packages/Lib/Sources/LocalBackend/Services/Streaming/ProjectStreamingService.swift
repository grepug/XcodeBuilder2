import Foundation
import SharingGRDB
import GRDB
import Dependencies
import Core

/// Internal service for project-related streaming operations
struct ProjectStreamingService {
    @Dependency(\.defaultDatabase) var db
    
    func streamAllProjectIds() -> some AsyncSequence<[String], Never> {
        @FetchAll(
            Project.all
                .order(by: \.createdAt)
                .select(\.bundleIdentifier)
        ) var projectIds: [String]

        return $projectIds.publisher.values
    }

    func streamProject(id: String) -> some AsyncSequence<ProjectValue?, Never> {
        @FetchOne(
            Project
                .where { $0.bundleIdentifier == id }
                .order(by: \.createdAt)
        ) var project: Project?

        return $project.publisher.values
            .map { dbProject -> ProjectValue? in
                guard let dbProject = dbProject else { return nil }
                return dbProject.toValue()
            }
    }

    func streamProjectVersionStrings() -> some AsyncSequence<[String: [String]], Never> {
        @Fetch(ProjectVersionStringsRequest()) var projectVersions = ProjectVersionStringsRequest.Value()
        return $projectVersions.publisher.values.map(\.versionsByProject)
    }

    func streamProjectDetail(id: String) -> some AsyncSequence<ProjectDetailData?, Never> {
        @Fetch(ProjectDetailRequest(id: id)) 
        var projectDetail: ProjectDetailRequest.Result? = nil

        return $projectDetail.publisher.values.compactMap { result -> ProjectDetailData? in
            guard let result = result else { return nil }
            let projectValue = result.project.toValue()
            return ProjectDetailData(
                project: projectValue,
                schemeIds: result.schemes.map(\.id),
                recentBuildIds: result.builds.prefix(5).map(\.id)
            )
        }
    }
}

// MARK: - FetchKeyRequest Implementations

/// Custom FetchKeyRequest for fetching project version strings with all related data in a single transaction
private struct ProjectVersionStringsRequest: FetchKeyRequest {
    struct Value {
        let versionsByProject: [String: [String]]

        init() {
            self.versionsByProject = [:]
        }

        init(versionsByProject: [String: [String]]) {
            self.versionsByProject = versionsByProject
        }
    }

    func fetch(_ db: Database) throws -> Value {
        let projects = try Project.all.fetchAll(db)
        var result: [String: [String]] = [:]

        for project in projects {
            let schemes = try Scheme
                .where { $0.projectBundleIdentifier == project.bundleIdentifier }
                .fetchAll(db)

            let schemeIds = schemes.map(\.id)
            let builds = try BuildModel
                .where { $0.schemeId.in(schemeIds) }
                .fetchAll(db)

            let versions = Array(Set(builds.map(\.versionString))).sorted()
            result[project.bundleIdentifier] = versions
        }

        return Value(versionsByProject: result)
    }
}
