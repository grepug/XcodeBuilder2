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
                print("Project with bundle identifier \(id) not found")
                return nil
            }
        
        let schemes = try Scheme
            .where { $0.projectBundleIdentifier == id }
            .fetchAll(db)
            .sorted()
        
        let builds = try BuildModel
            .where { $0.schemeId.in(schemes.map(\.id)) }
            .order { $0.createdAt.desc() }
            .fetchAll(db)
        
        return .init(project: project, builds: builds, schemes: schemes)
    }
}
