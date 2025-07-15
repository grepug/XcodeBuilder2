import Foundation
import SharingGRDB

public struct ProjectDetailRequest: FetchKeyRequest {
    var id: String
    
    public struct Result: Sendable {
        public let project: Project
        public let builds: [BuildModel]
        public let schemes: [Scheme]
    }

    public init(id: String) {
        self.id = id
    }
    
    public func fetch(_ db: Database) throws -> Result? {
        guard let project = (try Project.where { $0.bundleIdentifier == id }
            .fetchOne(db)) else {
                return nil
            }
        
        let builds = try BuildModel
            .join(Scheme.where { $0.projectBundleIdentifier == id }, on: { $0.0.schemeId == $0.1.id })
            .where { a, b in b.projectBundleIdentifier == id }
            .fetchAll(db)
            .map { $0.0 }

        let schemes = try Scheme
            .where { $0.projectBundleIdentifier == id }
            .fetchAll(db)
            .sorted()
        
        return .init(project: project, builds: builds, schemes: schemes)
    }
}