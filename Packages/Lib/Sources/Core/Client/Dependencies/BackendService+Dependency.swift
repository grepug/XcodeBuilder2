import Dependencies
import Foundation

// MARK: - Backend Service Dependency

public enum BackendServiceKey: DependencyKey {
  public static let liveValue: any BackendService = MockBackendService()
  public static let testValue: any BackendService = MockBackendService()
}

public extension DependencyValues {
  var backendService: any BackendService {
    get { self[BackendServiceKey.self] }
    set { self[BackendServiceKey.self] = newValue }
  }
}

// MARK: - Mock Backend Service

private struct MockBackendService: BackendService, Sendable {
  typealias ProjectIdsSequence = AsyncJustSequence<[String]>
  typealias ProjectSequence = AsyncJustSequence<ProjectValue?>
  typealias ProjectVersionStringsSequence = AsyncJustSequence<[String: [String]]>
  typealias SchemeIdsSequence = AsyncJustSequence<[UUID]>
  typealias SchemeSequence = AsyncJustSequence<SchemeValue?>
  typealias BuildIdsSequence = AsyncJustSequence<[UUID]>
  typealias BuildSequence = AsyncJustSequence<BuildModelValue?>
  typealias LatestBuildsSequence = AsyncJustSequence<[BuildModelValue]>
  typealias BuildLogIdsSequence = AsyncJustSequence<[UUID]>
  typealias BuildLogSequence = AsyncJustSequence<BuildLogValue?>
  typealias CrashLogIdsSequence = AsyncJustSequence<[String]>
  typealias CrashLogSequence = AsyncJustSequence<CrashLogValue?>
  typealias ProjectDetailSequence = AsyncJustSequence<ProjectDetailData?>
  typealias BuildVersionStringsSequence = AsyncJustSequence<[String]>
  typealias BuildProgressSequence = AsyncThrowingJustSequence<BuildProgressUpdate>

  func createProject(_ project: ProjectValue) async throws {}
  func updateProject(_ project: ProjectValue) async throws {}
  func deleteProject(id: String) async throws {}

  func createScheme(_ scheme: SchemeValue) async throws {}
  func updateScheme(_ scheme: SchemeValue) async throws {}
  func deleteScheme(id: UUID) async throws {}

  func createBuild(_ build: BuildModelValue) async throws {}
  func updateBuild(_ build: BuildModelValue) async throws {}
  func deleteBuild(id: UUID) async throws {}

  func createBuildLog(_ log: BuildLogValue) async throws {}
  func deleteBuildLogs(buildId: UUID) async throws {}

  func createCrashLog(_ crashLog: CrashLogValue) async throws {}
  func updateCrashLog(_ crashLog: CrashLogValue) async throws {}
  func deleteCrashLog(id: String) async throws {}

  func streamAllProjectIds() -> ProjectIdsSequence { AsyncJustSequence([]) }
  func streamProject(id: String) -> ProjectSequence { AsyncJustSequence(nil) }
  func streamProjectVersionStrings() -> ProjectVersionStringsSequence { AsyncJustSequence([:]) }
  func streamSchemeIds(projectId: String) -> SchemeIdsSequence { AsyncJustSequence([]) }
  func streamScheme(id: UUID) -> SchemeSequence { AsyncJustSequence(nil) }
  func streamBuildIds(schemeIds: [UUID], versionString: String?) -> BuildIdsSequence { AsyncJustSequence([]) }
  func streamBuild(id: UUID) -> BuildSequence { AsyncJustSequence(nil) }
  func streamLatestBuilds(projectId: String, limit: Int) -> LatestBuildsSequence { AsyncJustSequence([]) }
  func streamBuildLogIds(buildId: UUID, includeDebug: Bool, category: String?) -> BuildLogIdsSequence { AsyncJustSequence([]) }
  func streamBuildLog(id: UUID) -> BuildLogSequence { AsyncJustSequence(nil) }
  func streamCrashLogIds(buildId: UUID) -> CrashLogIdsSequence { AsyncJustSequence([]) }
  func streamCrashLog(id: String) -> CrashLogSequence { AsyncJustSequence(nil) }
  func streamProjectDetail(id: String) -> ProjectDetailSequence { AsyncJustSequence(nil) }
  func streamBuildVersionStrings(projectId: String) -> BuildVersionStringsSequence { AsyncJustSequence([]) }
  
  // MARK: - Build Job Methods (Step 6)
  func createBuildJob(payload: BuildJobPayload, buildModel: BuildModelValue) async throws {}
  func startBuildJob(buildId: UUID) -> BuildProgressSequence { 
    AsyncThrowingJustSequence(BuildProgressUpdate(buildId: buildId, progress: 0.0, message: "Mock build job"))
  }
  func cancelBuildJob(buildId: UUID) async {}
  func deleteBuildJob(buildId: UUID) async throws {}
  func getBuildJobStatus(buildId: UUID) -> BuildJobStatus? { .idle }
}

// MARK: - AsyncJustSequence Helper

private struct AsyncJustSequence<Element>: AsyncSequence {
  typealias AsyncIterator = AsyncJustIterator<Element>
  
  private let element: Element
  
  init(_ element: Element) {
    self.element = element
  }
  
  func makeAsyncIterator() -> AsyncJustIterator<Element> {
    AsyncJustIterator(element)
  }
}

private struct AsyncJustIterator<Element>: AsyncIteratorProtocol {
  private var element: Element?
  
  init(_ element: Element) {
    self.element = element
  }
  
  mutating func next() async -> Element? {
    defer { element = nil }
    return element
  }
}

// MARK: - AsyncThrowingJustSequence Helper

private struct AsyncThrowingJustSequence<Element>: AsyncSequence {
  typealias AsyncIterator = AsyncThrowingJustIterator<Element>
  
  private let element: Element
  
  init(_ element: Element) {
    self.element = element
  }
  
  func makeAsyncIterator() -> AsyncThrowingJustIterator<Element> {
    AsyncThrowingJustIterator(element)
  }
}

private struct AsyncThrowingJustIterator<Element>: AsyncIteratorProtocol {
  private var element: Element?
  
  init(_ element: Element) {
    self.element = element
  }
  
  mutating func next() async throws -> Element? {
    defer { element = nil }
    return element
  }
}
