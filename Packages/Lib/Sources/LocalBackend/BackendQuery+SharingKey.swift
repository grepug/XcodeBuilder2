import Foundation
import Sharing
import Dependencies

// MARK: - Backend Query Types

public struct BackendQueryType<Value: Sendable>: Sendable {
  public let id: String
  public let observe: @Sendable (any BackendService, _ yield: @escaping @Sendable (Value) -> Void, _ stop: Bool) async -> Void
  
  public init(id: String, observe: @escaping @Sendable (any BackendService, _ yield: @escaping @Sendable (Value) -> Void, _ stop: Bool) async -> Void) {
    self.id = id
    self.observe = observe
  }
}

// MARK: - Backend Query Factory Methods

public extension SharedReaderKey where Self == BackendQueryKey<[String]>.Default {
   static var allProjectIds: Self {
      Self[.init(.init(id: "allProjectIds") {
        await $0.streamAllProjectIds().observe($1, stop: $2)
      }), default: []]
  }
} 

public extension BackendQueryType where Value == [String] {
  static var allProjectIds: Self {
    BackendQueryType(id: "allProjectIds") { backendService, yield, stop in
      await backendService.streamAllProjectIds().observe(yield, stop: stop)
    }
  }
  
  static func buildVersionStrings(projectId: String) -> Self {
    BackendQueryType(id: "buildVersionStrings-\(projectId)") { backendService, yield, stop in
      await backendService.streamBuildVersionStrings(projectId: projectId).observe(yield, stop: stop)
    }
  }
}

public extension BackendQueryType where Value == [UUID] {
  static func schemeIds(projectId: String) -> Self {
    BackendQueryType(id: "schemeIds-\(projectId)") { backendService, yield, stop in
      await backendService.streamSchemeIds(projectId: projectId).observe(yield, stop: stop)
    }
  }
  
  static func buildIds(schemeIds: [UUID], versionString: String? = nil) -> Self {
    let id = "buildIds-\(schemeIds.map { $0.uuidString }.joined(separator:","))-\(versionString ?? "nil")"
    return BackendQueryType(id: id) { backendService, yield, stop in
      await backendService.streamBuildIds(schemeIds: schemeIds, versionString: versionString).observe(yield, stop: stop)
    }
  }
}

public extension BackendQueryType where Value == ProjectValue? {
  static func project(id: String) -> Self {
    BackendQueryType(id: "project-\(id)") { backendService, yield, stop in
      await backendService.streamProject(id: id).observe(yield, stop: stop)
    }
  }
}

public extension BackendQueryType where Value == [String: [String]] {
  static var projectVersionStrings: Self {
    BackendQueryType(id: "projectVersionStrings") { backendService, yield, stop in
      await backendService.streamProjectVersionStrings().observe(yield, stop: stop)
    }
  }
}

public extension BackendQueryType where Value == SchemeValue? {
  static func scheme(id: UUID) -> Self {
    BackendQueryType(id: "scheme-\(id)") { backendService, yield, stop in
      await backendService.streamScheme(id: id).observe(yield, stop: stop)
    }
  }
}

public extension BackendQueryType where Value == BuildModelValue? {
  static func build(id: UUID) -> Self {
    BackendQueryType(id: "build-\(id)") { backendService, yield, stop in
      await backendService.streamBuild(id: id).observe(yield, stop: stop)
    }
  }
}

public extension BackendQueryType where Value == [BuildModelValue] {
  static func latestBuilds(projectId: String, limit: Int = 10) -> Self {
    BackendQueryType(id: "latestBuilds-\(projectId)-\(limit)") { backendService, yield, stop in
      await backendService.streamLatestBuilds(projectId: projectId, limit: limit).observe(yield, stop: stop)
    }
  }
}

public extension BackendQueryType where Value == ProjectDetailData? {
  static func projectDetail(id: String) -> Self {
    BackendQueryType(id: "projectDetail-\(id)") { backendService, yield, stop in
      await backendService.streamProjectDetail(id: id).observe(yield, stop: stop)
    }
  }
}

private extension AsyncSequence {
  func observe(_ yield: @escaping @Sendable (Element) -> Void, stop: Bool = false) async {
    do {
      for try await item in self {
        yield(item)
        if stop {
          break
        }
      }
    } catch {
      // Handle error if needed
    }
  }
}

// MARK: - Backend Query Key

public struct BackendQueryKey<Value: Sendable>: SharedReaderKey {
  public let query: BackendQueryType<Value>
  public let id: String
  
  public init(_ query: BackendQueryType<Value>) {
    self.query = query
    self.id = query.id
  }
  
  public func load(context: LoadContext<Value>, continuation: LoadContinuation<Value>) {
    Task {
      @Dependency(\.backendService) var backendService
      
      let resultHolder = ResultHolder<Value>()

      await query.observe(backendService, { value in
        Task {
          await resultHolder.setValue(value)
        }
      }, true) // stop after first emission for load
      
      // Wait a bit for the async sequence to emit a value
      for _ in 0..<500 { // Wait up to 500ms for complex operations
        try? await Task.sleep(nanoseconds: 1_000_000) // 1ms
        if await resultHolder.hasValue() {
          break
        }
      }
      
      if let result = await resultHolder.getValue() {
        continuation.resume(returning: result)
      } else {
        // If no value received, return a sensible default based on the type
        if Value.self == [String].self {
          continuation.resume(returning: [] as! Value)
        } else if Value.self == ProjectValue?.self {
          continuation.resume(returning: Optional<ProjectValue>.none as! Value)
        } else if Value.self == [String: [String]].self {
          continuation.resume(returning: [:] as! Value)
        } else if Value.self == ProjectDetailData?.self {
          continuation.resume(returning: Optional<ProjectDetailData>.none as! Value)
        } else if Value.self == [BuildModelValue].self {
          continuation.resume(returning: [] as! Value)
        } else {
          continuation.resume(throwing: BackendQueryError.notImplemented)
        }
      }
    }
  }
  public func subscribe(
    context: LoadContext<Value>, 
    subscriber: SharedSubscriber<Value>
  ) -> SharedSubscription {
    let task = Task {
      @Dependency(\.backendService) var backendService
      
      await query.observe(backendService, { value in
        subscriber.yield(value)
      }, false) // don't stop, continue streaming for subscription
    }
    
    return SharedSubscription {
      task.cancel()
    }
  }
}

private actor ResultHolder<Value> {
  private var value: Value?
  private var hasReceivedValue = false
  
  func setValue(_ newValue: Value) {
    self.value = newValue
    self.hasReceivedValue = true
  }
  
  func getValue() -> Value? {
    return value
  }
  
  func hasValue() -> Bool {
    return hasReceivedValue
  }
  
  func setHasValue(_ hasValue: Bool) {
    self.hasReceivedValue = hasValue
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
