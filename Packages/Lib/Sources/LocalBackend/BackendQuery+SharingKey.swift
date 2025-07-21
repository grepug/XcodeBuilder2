import Foundation
import Sharing
import Dependencies

// MARK: - Backend Query Types

public enum BackendQueryType: Sendable {
  case allProjectIds
  case project(id: String)
  case projectVersionStrings
  case schemeIds(projectId: String)
  case scheme(id: UUID)
  case buildIds(schemeIds: [UUID], versionString: String?)
  case build(id: UUID)
  case latestBuilds(projectId: String, limit: Int)
  case projectDetail(id: String)
  case buildVersionStrings(projectId: String)
  
  public var id: String {
    switch self {
    case .allProjectIds: "allProjectIds"
    case .project(let id): "project-\(id)"
    case .projectVersionStrings: "projectVersionStrings"
    case .schemeIds(let projectId): "schemeIds-\(projectId)"
    case .scheme(let id): "scheme-\(id)"
    case .buildIds(let schemeIds, let versionString): "buildIds-\(schemeIds.map { $0.uuidString }.joined(separator:","))-\(versionString ?? "nil")"
    case .build(let id): "build-\(id)"
    case .latestBuilds(let projectId, let limit): "latestBuilds-\(projectId)-\(limit)"
    case .projectDetail(let id): "projectDetail-\(id)"
    case .buildVersionStrings(let projectId): "buildVersionStrings-\(projectId)"
    }
  }
}

// MARK: - Backend Query Key

public struct BackendQueryKey<Value: Sendable>: SharedReaderKey {
  public let query: BackendQueryType
  public let id: String
  
  public init(_ query: BackendQueryType) {
    self.query = query
    self.id = query.id
  }
  
  public func load(context: LoadContext<Value>, continuation: LoadContinuation<Value>) {
    Task {
      @Dependency(\.backendService) var backendService
      
      do {
        let result: Any
        
        switch query {
        case .allProjectIds:
          var projectIds: [String] = []
          for await ids in backendService.streamAllProjectIds() {
            projectIds = ids
            break
          }
          result = projectIds
          
        case .project(let id):
          var project: ProjectValue?
          for await proj in backendService.streamProject(id: id) {
            project = proj
            break
          }
          result = project as Any
          
        case .projectVersionStrings:
          var versionStrings: [String: [String]] = [:]
          for await versions in backendService.streamProjectVersionStrings() {
            versionStrings = versions
            break
          }
          result = versionStrings
          
        case .schemeIds(let projectId):
          var schemeIds: [UUID] = []
          for await ids in backendService.streamSchemeIds(projectId: projectId) {
            schemeIds = ids
            break
          }
          result = schemeIds
          
        case .scheme(let id):
          var scheme: SchemeValue?
          for await sch in backendService.streamScheme(id: id) {
            scheme = sch
            break
          }
          result = scheme as Any
          
        case .buildIds(let schemeIds, let versionString):
          var buildIds: [UUID] = []
          for await ids in backendService.streamBuildIds(schemeIds: schemeIds, versionString: versionString) {
            buildIds = ids
            break
          }
          result = buildIds
          
        case .build(let id):
          var build: BuildModelValue?
          for await bld in backendService.streamBuild(id: id) {
            build = bld
            break
          }
          result = build as Any
          
        case .latestBuilds(let projectId, let limit):
          var builds: [BuildModelValue] = []
          for await latestBuilds in backendService.streamLatestBuilds(projectId: projectId, limit: limit) {
            builds = latestBuilds
            break
          }
          result = builds
          
        case .projectDetail(let id):
          var projectDetail: ProjectDetailData?
          for await detail in backendService.streamProjectDetail(id: id) {
            projectDetail = detail
            break
          }
          result = projectDetail as Any
          
        case .buildVersionStrings(let projectId):
          var versionStrings: [String] = []
          for await versions in backendService.streamBuildVersionStrings(projectId: projectId) {
            versionStrings = versions
            break
          }
          result = versionStrings
        }
        
        if let typedResult = result as? Value {
          continuation.resume(returning: typedResult)
        } else {
          throw BackendQueryError.typeMismatch
        }
      } catch {
        continuation.resume(throwing: error)
      }
    }
  }
  
  public func subscribe(
    context: LoadContext<Value>, 
    subscriber: SharedSubscriber<Value>
  ) -> SharedSubscription {
    // Return empty subscription for now - could be enhanced with database observers
    return SharedSubscription {}
  }
}

// MARK: - Backend Query Error

public enum BackendQueryError: Error {
  case typeMismatch
  case notImplemented
  case invalidConfiguration
}

// MARK: - Convenience Extensions

extension SharedReaderKey where Self == BackendQueryKey<[String]> {
  /// Shared key for retrieving all project IDs from the backend
  public static var allProjectIds: Self {
    BackendQueryKey(.allProjectIds)
  }
}

extension SharedReaderKey where Self == BackendQueryKey<ProjectValue?> {
  /// Shared key for retrieving a specific project from the backend
  public static func project(id: String) -> Self {
    BackendQueryKey(.project(id: id))
  }
}

extension SharedReaderKey where Self == BackendQueryKey<[String: [String]]> {
  /// Shared key for retrieving project version strings from the backend
  public static var projectVersionStrings: Self {
    BackendQueryKey(.projectVersionStrings)
  }
}

extension SharedReaderKey where Self == BackendQueryKey<[UUID]> {
  /// Shared key for retrieving scheme IDs for a specific project
  public static func schemeIds(projectId: String) -> Self {
    BackendQueryKey(.schemeIds(projectId: projectId))
  }
  
  /// Shared key for retrieving build IDs for specific schemes
  public static func buildIds(schemeIds: [UUID], versionString: String? = nil) -> Self {
    BackendQueryKey(.buildIds(schemeIds: schemeIds, versionString: versionString))
  }
}

extension SharedReaderKey where Self == BackendQueryKey<SchemeValue?> {
  /// Shared key for retrieving a specific scheme from the backend
  public static func scheme(id: UUID) -> Self {
    BackendQueryKey(.scheme(id: id))
  }
}

extension SharedReaderKey where Self == BackendQueryKey<BuildModelValue?> {
  /// Shared key for retrieving a specific build from the backend
  public static func build(id: UUID) -> Self {
    BackendQueryKey(.build(id: id))
  }
}

extension SharedReaderKey where Self == BackendQueryKey<[BuildModelValue]> {
  /// Shared key for retrieving latest builds for a specific project
  public static func latestBuilds(projectId: String, limit: Int = 10) -> Self {
    BackendQueryKey(.latestBuilds(projectId: projectId, limit: limit))
  }
}

extension SharedReaderKey where Self == BackendQueryKey<ProjectDetailData?> {
  /// Shared key for retrieving detailed project information
  public static func projectDetail(id: String) -> Self {
    BackendQueryKey(.projectDetail(id: id))
  }
}

extension SharedReaderKey where Self == BackendQueryKey<[String]> {
  /// Shared key for retrieving build version strings for a specific project
  public static func buildVersionStrings(projectId: String) -> Self {
    BackendQueryKey(.buildVersionStrings(projectId: projectId))
  }
}
