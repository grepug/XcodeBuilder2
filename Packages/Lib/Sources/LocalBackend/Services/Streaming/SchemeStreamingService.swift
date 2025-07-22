import Foundation
import SharingGRDB
import Dependencies
import Core

/// Service responsible for scheme-related streaming operations
public struct SchemeStreamingService: Sendable {
    /// Initialize the scheme streaming service
    public init() {}

    // MARK: - Scheme Streaming Methods

    /// Stream scheme IDs for a specific project
    public func streamSchemeIds(projectId: String) -> some AsyncSequence<[UUID], Never> {
        @FetchAll(
            Scheme
                .where { $0.projectBundleIdentifier == projectId }
                .order(by: \.order)
                .select(\.id)
        ) var schemeIds: [UUID]

        return $schemeIds.publisher.values
    }

    /// Stream a specific scheme by ID
    public func streamScheme(id: UUID) -> some AsyncSequence<SchemeValue?, Never> {
        @FetchOne(
            Scheme
                .where { $0.id == id }
        ) var scheme: Scheme?

        return $scheme.publisher.values
            .map { dbScheme -> SchemeValue? in
                guard let dbScheme = dbScheme else { return nil }
                return dbScheme.toValue()
            }
    }

    /// Stream a scheme by build ID
    public func streamScheme(buildId: UUID) -> some AsyncSequence<SchemeValue?, Never> {
        @Fetch(SchemeByBuildIdRequest(buildId: buildId)) var scheme: SchemeValue? = nil
        return $scheme.publisher.values
    }

    /// Stream all schemes for a specific project
    public func streamSchemes(projectId: String) -> some AsyncSequence<[SchemeValue], Never> {
        @FetchAll(
            Scheme
                .where { $0.projectBundleIdentifier == projectId }
                .order(by: \.order)
        ) var schemes: [Scheme]

        return $schemes.publisher.values
            .map { dbSchemes -> [SchemeValue] in
                dbSchemes.map { dbScheme in
                    dbScheme.toValue()
                }
            }
    }

    /// Stream build IDs for specific schemes, optionally filtered by version string
    public func streamBuildIds(schemeIds: [UUID], versionString: String?) -> some AsyncSequence<[UUID], Never> {
        @FetchAll(
            BuildModel.all
                .where { $0.schemeId.in(schemeIds) }
                .where { versionString == nil || $0.versionString == versionString }
                .order { $0.createdAt.desc() }
                .select(\.id)
        ) var buildIds: [UUID]

        return $buildIds.publisher.values
    }
}

// MARK: - Custom FetchKeyRequest for Scheme by Build ID

/// Custom FetchKeyRequest for fetching a scheme by build ID
private struct SchemeByBuildIdRequest: FetchKeyRequest {
    let buildId: UUID
    
    func fetch(_ db: Database) throws -> SchemeValue? {
        // Get the build to find its scheme ID
        guard let build = try BuildModel.where({ $0.id == buildId }).fetchOne(db) else {
            return nil
        }
        
        // Get the scheme
        let scheme = try Scheme
            .where { $0.id == build.schemeId }
            .fetchOne(db)
        
        return scheme?.toValue()
    }
}
