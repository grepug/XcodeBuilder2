import Foundation
import SharingGRDB
import Dependencies
import Core

/// Service responsible for build-related streaming operations
public struct BuildStreamingService: Sendable {
    /// Initialize the build streaming service
    public init() {}

    // MARK: - Build Streaming Methods

    /// Stream a specific build by ID
    public func streamBuild(id: UUID) -> some AsyncSequence<BuildModelValue?, Never> {
        @FetchOne(
            BuildModel
                .where { $0.id == id }
        ) var build: BuildModel?

        return $build.publisher.values
            .map { dbBuild -> BuildModelValue? in
                guard let dbBuild = dbBuild else { return nil }
                return dbBuild.toValue()
            }
    }

    /// Stream latest builds for a specific project
    public func streamLatestBuilds(projectId: String, limit: Int) -> some AsyncSequence<[BuildModelValue], Never> {
        @Fetch(LatestBuildsRequest(projectId: projectId, limit: limit)) var latestBuilds = LatestBuildsRequest.Value()
        return $latestBuilds.publisher.values.map(\.builds)
    }

    /// Stream build version strings for a specific project
    public func streamBuildVersionStrings(projectId: String) -> some AsyncSequence<[String], Never> {
        @Fetch(BuildVersionStringsRequest(projectId: projectId)) 
        var buildVersions: [String] = []
        return $buildVersions.publisher.values
    }
}

// MARK: - Custom FetchKeyRequests

/// Custom FetchKeyRequest for fetching latest builds for a project with all data in a single transaction
private struct LatestBuildsRequest: FetchKeyRequest {
    let projectId: String
    let limit: Int

    struct Value {
        let builds: [BuildModelValue]

        init() {
            self.builds = []
        }

        init(builds: [BuildModelValue]) {
            self.builds = builds
        }
    }

    func fetch(_ db: Database) throws -> Value {
        // Get schemes for the project
        let schemes = try Scheme
            .where { $0.projectBundleIdentifier == projectId }
            .fetchAll(db)

        let schemeIds = schemes.map(\.id)
        guard !schemeIds.isEmpty else { return Value() }

        // Get latest builds
        let builds = try BuildModel
            .where { $0.schemeId.in(schemeIds) }
            .order { $0.createdAt.desc() }
            .limit(limit)
            .fetchAll(db)

        let buildValues = builds.map { $0.toValue() }
        return Value(builds: buildValues)
    }
}

/// Custom FetchKeyRequest for fetching build version strings
private struct BuildVersionStringsRequest: FetchKeyRequest {
    let projectId: String

    func fetch(_ db: Database) throws -> [String] {
        let schemes = try Scheme
            .where { $0.projectBundleIdentifier == projectId }
            .fetchAll(db)

        let schemeIds = schemes.map(\.id)
        let builds = try BuildModel
            .where { $0.schemeId.in(schemeIds) }
            .fetchAll(db)

        let versions = Array(Set(builds.map(\.versionString))).sorted(by: >)
        return versions
    }
}
