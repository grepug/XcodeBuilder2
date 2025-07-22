import Dependencies
import Foundation

// MARK: - Backend Service Dependency

public enum BackendServiceKey: DependencyKey {
  public static var liveValue: any BackendService {
    fatalError("BackendService not configured. Call prepareDependencies() during app initialization.")
  }
  
  public static var testValue: any BackendService {
    fatalError("BackendService not configured for tests. Use withDependencies to provide a test implementation.")
  }
}

public extension DependencyValues {
  var backendService: any BackendService {
    get { self[BackendServiceKey.self] }
    set { self[BackendServiceKey.self] = newValue }
  }
}
