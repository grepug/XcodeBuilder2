import Dependencies

// MARK: - Backend Service Dependency

private enum BackendServiceKey: DependencyKey {
  static let liveValue: any BackendService = LocalBackendService()
  static let testValue: any BackendService = LocalBackendService()
}

public extension DependencyValues {
  var backendService: any BackendService {
    get { self[BackendServiceKey.self] }
    set { self[BackendServiceKey.self] = newValue }
  }
}
