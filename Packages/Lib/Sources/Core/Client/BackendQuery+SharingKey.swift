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

public extension SharedReaderKey where Self == BackendQueryKey<[SchemeValue]>.Default {
    static func schemes(projectId: String) -> Self {
        Self[.init(.init(id: "schemes-\(projectId)") {
            await $0.streamSchemes(projectId: projectId).observe($1, stop: $2)
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
    
    static func buildLogIds(buildId: UUID, includeDebug: Bool, category: String?) -> Self {
        let id = "buildLogIds-\(buildId)"
        return Self[.init(.init(id: id) {
          await $0.streamBuildLogIds(buildId: buildId, includeDebug: includeDebug, category: category).observe($1, stop: $2)
        }), default: []]
    }
}

public extension SharedReaderKey where Self == BackendQueryKey<BuildLogValue?>.Default {
    static func buildLog(id: UUID) -> Self {
        Self[.init(.init(id: "buildLog-\(id)") {
            await $0.streamBuildLog(id: id).observe($1, stop: $2)
        }), default: nil]
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
    
    static func scheme(buildId: UUID) -> Self {
      Self[.init(.init(id: "scheme-build-\(buildId)") {
        await $0.streamScheme(buildId: buildId).observe($1, stop: $2)
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

public extension SharedReaderKey where Self == BackendQueryKey<[String]>.Default {
    static func crashLogIds(buildId: UUID) -> Self {
        Self[.init(.init(id: "crashLogs-\(buildId)") {
            await $0.streamCrashLogIds(buildId: buildId).observe($1, stop: $2)
        }), default: []]
    }
}

public extension SharedReaderKey where Self == BackendQueryKey<CrashLogValue?>.Default {
    static func crashLog(id: String) -> Self {
        Self[.init(.init(id: "crashLog-\(id)") {
            await $0.streamCrashLog(id: id).observe($1, stop: $2)
        }), default: nil]
    }
}

private extension AsyncSequence {
  func observe(_ yield: @escaping @Sendable (Element) -> Void, stop: Bool = false) async {
    do {
      var iterator = makeAsyncIterator()
      while let item = try await iterator.next() {
        yield(item)
        if stop {
          break
        }
      }
    } catch {
      // Handle error if needed - errors from async sequences should be logged or handled
      print("AsyncSequence observe error: \(error)")
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
      
      // Start observe task with detached task to avoid capture issues
      let observeTask = Task {
        await query.observe(backendService, { value in
          Task.detached {
            await resultHolder.setValue(value)
          }
        }, true) // stop after first emission for load
      }
      
      // Wait with reasonable timeout for complex operations
      var attempts = 0
      let maxAttempts = 300 // 300ms max wait for complex operations
      
      while attempts < maxAttempts {
        if await resultHolder.hasValue() {
          break
        }
        try! await Task.sleep(for: .milliseconds(1)) // 1ms
        attempts += 1
      }
      
      // Cancel the observe task to prevent hanging
      observeTask.cancel()
      
      // Return result or fallback
      if let result = await resultHolder.getValue() {
        continuation.resume(returning: result)
      } else if let initialValue = context.initialValue {
        // Use provided default value
        continuation.resume(returning: initialValue)
      } else {
        // For cases without defaults, try to provide reasonable fallbacks
        // Check if this is an optional type that we can return nil for
        if String(describing: Value.self).contains("Optional") {
          // This is an optional type, we can provide nil
          let nilValue = Optional<Any>.none
          continuation.resume(returning: nilValue as! Value)
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
