# Step 3: SharingKey System

**Goal**: Implement the universal BackendQuery<T> SharingKey that serves as the single key type for all backend observations.

## Files to Create

### 3.1 Core BackendQuery Implementation

**File**: `Packages/Lib/Sources/Core/SharingKeys/BackendQuery.swift`

```swift
import Foundation
import Sharing

/// Universal SharingKey for all backend queries
public struct BackendQuery<Value: Sendable>: Sendable, Hashable, CustomStringConvertible {
    public let key: String

    public init(_ key: String) {
        self.key = key
    }

    public var description: String { "BackendQuery(\(key))" }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(key)
        hasher.combine(ObjectIdentifier(Value.self))
    }

    public static func == (lhs: BackendQuery<Value>, rhs: BackendQuery<Value>) -> Bool {
        return lhs.key == rhs.key
    }
}

// MARK: - Static Factory Methods

public extension BackendQuery {

    // MARK: - Project Queries
    static func allProjectIds() -> BackendQuery<[String]> {
        BackendQuery("projects.all.ids")
    }

    static func project(id: String) -> BackendQuery<ProjectValue?> {
        BackendQuery("project.\(id)")
    }

    static func projectVersionStrings() -> BackendQuery<[String: [String]]> {
        BackendQuery("projects.versionStrings")
    }

    static func projectDetail(id: String) -> BackendQuery<ProjectDetailData> {
        BackendQuery("project.\(id).detail")
    }

    static func buildVersionStrings(projectId: String) -> BackendQuery<[String]> {
        BackendQuery("project.\(projectId).buildVersionStrings")
    }

    // MARK: - Scheme Queries
    static func schemeIds(projectId: String) -> BackendQuery<[UUID]> {
        BackendQuery("project.\(projectId).schemes.ids")
    }

    static func scheme(id: UUID) -> BackendQuery<SchemeValue?> {
        BackendQuery("scheme.\(id.uuidString)")
    }

    // MARK: - Build Queries
    static func buildIds(schemeIds: [UUID], versionString: String?) -> BackendQuery<[UUID]> {
        let schemeIdString = schemeIds.map(\.uuidString).joined(separator: ",")
        let versionSuffix = versionString.map { ".\($0)" } ?? ""
        return BackendQuery("schemes.\(schemeIdString).builds.ids\(versionSuffix)")
    }

    static func build(id: UUID) -> BackendQuery<BuildModelValue?> {
        BackendQuery("build.\(id.uuidString)")
    }

    static func latestBuilds(projectId: String, limit: Int) -> BackendQuery<[BuildModelValue]> {
        BackendQuery("project.\(projectId).latestBuilds.limit\(limit)")
    }

    // MARK: - Build Log Queries
    static func buildLogIds(buildId: UUID, includeDebug: Bool, category: String?) -> BackendQuery<[UUID]> {
        let debugSuffix = includeDebug ? ".debug" : ""
        let categorySuffix = category.map { ".category\($0)" } ?? ""
        return BackendQuery("build.\(buildId.uuidString).logs.ids\(debugSuffix)\(categorySuffix)")
    }

    static func buildLog(id: UUID) -> BackendQuery<BuildLogValue?> {
        BackendQuery("buildLog.\(id.uuidString)")
    }

    // MARK: - Crash Log Queries
    static func crashLogIds(buildId: UUID) -> BackendQuery<[String]> {
        BackendQuery("build.\(buildId.uuidString).crashLogs.ids")
    }

    static func crashLog(id: String) -> BackendQuery<CrashLogValue?> {
        BackendQuery("crashLog.\(id)")
    }
}

// MARK: - Domain Model Convenience Extensions

public extension BackendQuery {

    /// Convert BackendQuery<ProjectValue?> to BackendQuery<Project?>
    static func domainProject(id: String) -> BackendQuery<Project?> {
        BackendQuery("project.\(id)")
    }

    /// Convert BackendQuery<SchemeValue?> to BackendQuery<Scheme?>
    static func domainScheme(id: UUID) -> BackendQuery<Scheme?> {
        BackendQuery("scheme.\(id.uuidString)")
    }

    /// Convert BackendQuery<BuildModelValue?> to BackendQuery<Build?>
    static func domainBuild(id: UUID) -> BackendQuery<Build?> {
        BackendQuery("build.\(id.uuidString)")
    }

    /// Convert BackendQuery<BuildLogValue?> to BackendQuery<BuildLog?>
    static func domainBuildLog(id: UUID) -> BackendQuery<BuildLog?> {
        BackendQuery("buildLog.\(id.uuidString)")
    }

    /// Convert BackendQuery<CrashLogValue?> to BackendQuery<CrashLog?>
    static func domainCrashLog(id: String) -> BackendQuery<CrashLog?> {
        BackendQuery("crashLog.\(id)")
    }

    /// Convert BackendQuery<[BuildModelValue]> to BackendQuery<[Build]>
    static func domainLatestBuilds(projectId: String, limit: Int) -> BackendQuery<[Build]> {
        BackendQuery("project.\(projectId).latestBuilds.limit\(limit)")
    }
}
```

### 3.2 SharingKey Protocol Conformance

**File**: `Packages/Lib/Sources/Core/SharingKeys/BackendQuery+SharingKey.swift`

```swift
import Foundation
import Sharing

// MARK: - SharingKey Protocol Conformance

extension BackendQuery: SharingKey {
    public typealias Value = Value

    // Default implementation - backend queries don't have default values
    // Each backend service implementation will provide the actual values
    public var defaultValue: Value {
        fatalError("BackendQuery does not have a default value. Use @Shared with a backend service.")
    }

    // Optional: implement custom subscription behavior if needed
    // For now, we rely on the backend service to handle subscriptions
}
```

### 3.3 Backend Query Extensions for Type Safety

**File**: `Packages/Lib/Sources/Core/SharingKeys/BackendQueryExtensions.swift`

```swift
import Foundation

// MARK: - Type-Safe Query Builders

public struct ProjectQueries {
    public static let allIds = BackendQuery<[String]>.allProjectIds()
    public static let versionStrings = BackendQuery<[String: [String]]>.projectVersionStrings()

    public static func project(id: String) -> BackendQuery<ProjectValue?> {
        .project(id: id)
    }

    public static func detail(id: String) -> BackendQuery<ProjectDetailData> {
        .projectDetail(id: id)
    }

    public static func buildVersionStrings(id: String) -> BackendQuery<[String]> {
        .buildVersionStrings(projectId: id)
    }

    public static func schemeIds(id: String) -> BackendQuery<[UUID]> {
        .schemeIds(projectId: id)
    }
}

public struct SchemeQueries {
    public static func scheme(id: UUID) -> BackendQuery<SchemeValue?> {
        .scheme(id: id)
    }
}

public struct BuildQueries {
    public static func buildIds(schemeIds: [UUID], versionString: String? = nil) -> BackendQuery<[UUID]> {
        .buildIds(schemeIds: schemeIds, versionString: versionString)
    }

    public static func build(id: UUID) -> BackendQuery<BuildModelValue?> {
        .build(id: id)
    }

    public static func latestBuilds(projectId: String, limit: Int = 10) -> BackendQuery<[BuildModelValue]> {
        .latestBuilds(projectId: projectId, limit: limit)
    }

    public static func logIds(buildId: UUID, includeDebug: Bool = false, category: String? = nil) -> BackendQuery<[UUID]> {
        .buildLogIds(buildId: buildId, includeDebug: includeDebug, category: category)
    }
}

public struct BuildLogQueries {
    public static func buildLog(id: UUID) -> BackendQuery<BuildLogValue?> {
        .buildLog(id: id)
    }
}

public struct CrashLogQueries {
    public static func crashLogIds(buildId: UUID) -> BackendQuery<[String]> {
        .crashLogIds(buildId: buildId)
    }

    public static func crashLog(id: String) -> BackendQuery<CrashLogValue?> {
        .crashLog(id: id)
    }
}

// MARK: - Domain Model Query Builders

public struct DomainProjectQueries {
    public static func project(id: String) -> BackendQuery<Project?> {
        .domainProject(id: id)
    }
}

public struct DomainSchemeQueries {
    public static func scheme(id: UUID) -> BackendQuery<Scheme?> {
        .domainScheme(id: id)
    }
}

public struct DomainBuildQueries {
    public static func build(id: UUID) -> BackendQuery<Build?> {
        .domainBuild(id: id)
    }

    public static func latestBuilds(projectId: String, limit: Int = 10) -> BackendQuery<[Build]> {
        .domainLatestBuilds(projectId: projectId, limit: limit)
    }
}

public struct DomainBuildLogQueries {
    public static func buildLog(id: UUID) -> BackendQuery<BuildLog?> {
        .domainBuildLog(id: id)
    }
}

public struct DomainCrashLogQueries {
    public static func crashLog(id: String) -> BackendQuery<CrashLog?> {
        .domainCrashLog(id: id)
    }
}
```

### 3.4 Query Documentation and Usage Examples

**File**: `Packages/Lib/Sources/Core/SharingKeys/BackendQueryUsage.swift`

````swift
import Foundation
import Sharing

// MARK: - Usage Examples and Documentation

/*
 BackendQuery Usage Examples:

 1. Basic usage with backend values:
 ```swift
 @Shared(.project(id: "com.example.app"))
 var project: ProjectValue?

 @Shared(.allProjectIds())
 var projectIds: [String]
````

2.  Using type-safe query builders:

```swift
@Shared(ProjectQueries.project(id: "com.example.app"))
var project: ProjectValue?

@Shared(BuildQueries.latestBuilds(projectId: "com.example.app", limit: 5))
var recentBuilds: [BuildModelValue]
```

3.  Domain model queries (with automatic conversion):

```swift
@Shared(DomainProjectQueries.project(id: "com.example.app"))
var project: Project?

@Shared(DomainBuildQueries.latestBuilds(projectId: "com.example.app"))
var recentBuilds: [Build]
```

4.  Complex queries:

```swift
let schemeIds: [UUID] = // ... obtained from somewhere
@Shared(BuildQueries.buildIds(schemeIds: schemeIds, versionString: "1.0.0"))
var buildIds: [UUID]

@Shared(BuildQueries.logIds(buildId: buildId, includeDebug: true, category: "Build"))
var logIds: [UUID]
```

Key Benefits:

- Single BackendQuery<T> type for all queries
- Type-safe query construction
- Automatic backend/domain model conversion
- Consistent naming convention
- Easy to extend with new queries
- Hashable for efficient sharing/caching
  \*/

// MARK: - Helper Functions for Common Patterns

public extension BackendQuery {

    /// Create a query that depends on multiple other queries
    static func dependent<T1, T2>(
        on query1: BackendQuery<T1>,
        and query2: BackendQuery<T2>,
        key: String
    ) -> BackendQuery<Value> {
        BackendQuery("dependent.\(query1.key).\(query2.key).\(key)")
    }

    /// Create a parameterized query with multiple parameters
    static func parameterized(
        base: String,
        parameters: [String: String]
    ) -> BackendQuery<Value> {
        let paramString = parameters
            .sorted { $0.key < $1.key }
            .map { "\($0.key):\($0.value)" }
            .joined(separator: ",")
        return BackendQuery("\(base).\(paramString)")
    }

}

// MARK: - Query Validation

public extension BackendQuery {

    /// Validate that a query key follows expected patterns
    func isValid() -> Bool {
        // Basic validation: key should not be empty and should contain valid characters
        return !key.isEmpty && key.allSatisfy { char in
            char.isLetter || char.isNumber || char == "." || char == "_" || char == "-"
        }
    }

    /// Get the query category (first component of the key)
    var category: String? {
        return key.split(separator: ".").first.map(String.init)
    }

    /// Get the query identifier (last component of the key)
    var identifier: String? {
        return key.split(separator: ".").last.map(String.init)
    }

}

````

## Implementation Checklist

- [ ] Create `BackendQuery.swift` with core BackendQuery implementation
- [ ] Create `BackendQuery+SharingKey.swift` with SharingKey conformance
- [ ] Create `BackendQueryExtensions.swift` with type-safe query builders
- [ ] Create `BackendQueryUsage.swift` with documentation and examples
- [ ] Test BackendQuery functionality:
  - [ ] Hashability works correctly
  - [ ] Equality comparison works
  - [ ] Query key generation is consistent
  - [ ] Type safety is maintained
- [ ] Verify SharingKey protocol conformance compiles
- [ ] Test query builders generate expected keys

## Usage Examples

```swift
// In your views/view models:

struct ProjectListView: View {
    @Shared(ProjectQueries.allIds)
    var projectIds: [String]

    var body: some View {
        List(projectIds, id: \.self) { projectId in
            ProjectRowView(projectId: projectId)
        }
    }
}

struct ProjectRowView: View {
    let projectId: String

    @Shared(ProjectQueries.project(id: projectId))
    var project: ProjectValue?

    var body: some View {
        if let project = project {
            Text(project.displayName)
        }
    }
}

// Domain model usage:
struct DomainProjectView: View {
    let projectId: String

    @Shared(DomainProjectQueries.project(id: projectId))
    var project: Project?

    var body: some View {
        if let project = project {
            Text(project.displayName)
        }
    }
}
````

## Next Step

After completing this step, proceed to [Step 4: Local Backend Implementation](./STEP_4_LOCAL_BACKEND.md) to implement the GRDB-based backend service.
