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

public extension SharedReaderKey where Self == BackendQueryKey<[String]>.Default {
  static func buildVersionStrings(projectId: String) -> Self {
    Self[.init(.init(id: "buildVersionStrings-\(projectId)") {
      await $0.streamBuildVersionStrings(projectId: projectId).observe($1, stop: $2)
    }), default: []]
  }
}

public extension SharedReaderKey where Self == BackendQueryKey<[UUID]>.Default {
  static func schemeIds(projectId: String) -> Self {
    Self[.init(.init(id: "schemeIds-\(projectId)") {
      await $0.streamSchemeIds(projectId: projectId).observe($1, stop: $2)
    }), default: []]
  }
  
  static func buildIds(schemeIds: [UUID], versionString: String? = nil) -> Self {
    let id = "buildIds-\(schemeIds.map { $0.uuidString }.joined(separator:","))-\(versionString ?? "nil")"
    return Self[.init(.init(id: id) {
      await $0.streamBuildIds(schemeIds: schemeIds, versionString: versionString).observe($1, stop: $2)
    }), default: []]
  }
}

public extension SharedReaderKey where Self == BackendQueryKey<ProjectValue?>.Default {
  static func project(id: String) -> Self {
    Self[.init(.init(id: "project-\(id)") {
      await $0.streamProject(id: id).observe($1, stop: $2)
    }), default: nil]
  }
}

public extension SharedReaderKey where Self == BackendQueryKey<[String: [String]]>.Default {
  static var projectVersionStrings: Self {
    Self[.init(.init(id: "projectVersionStrings") {
      await $0.streamProjectVersionStrings().observe($1, stop: $2)
    }), default: [:]]
  }
}

public extension SharedReaderKey where Self == BackendQueryKey<SchemeValue?>.Default {
  static func scheme(id: UUID) -> Self {
    Self[.init(.init(id: "scheme-\(id)") {
      await $0.streamScheme(id: id).observe($1, stop: $2)
    }), default: nil]
  }
}

public extension SharedReaderKey where Self == BackendQueryKey<BuildModelValue?>.Default {
  static func build(id: UUID) -> Self {
    Self[.init(.init(id: "build-\(id)") {
      await $0.streamBuild(id: id).observe($1, stop: $2)
    }), default: nil]
  }
}

public extension SharedReaderKey where Self == BackendQueryKey<[BuildModelValue]>.Default {
  static func latestBuilds(projectId: String, limit: Int = 10) -> Self {
    Self[.init(.init(id: "latestBuilds-\(projectId)-\(limit)") {
      await $0.streamLatestBuilds(projectId: projectId, limit: limit).observe($1, stop: $2)
    }), default: []]
  }
}

public extension SharedReaderKey where Self == BackendQueryKey<ProjectDetailData?>.Default {
  static func projectDetail(id: String) -> Self {
    Self[.init(.init(id: "projectDetail-\(id)") {
      await $0.streamProjectDetail(id: id).observe($1, stop: $2)
    }), default: nil]
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
        // If no value received, return the initial value from context or throw an error
        if let initialValue = context.initialValue {
          continuation.resume(returning: initialValue)
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
