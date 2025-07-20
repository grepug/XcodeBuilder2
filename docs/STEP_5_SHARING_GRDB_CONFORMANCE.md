# Step 5: SharingGRDB Protocol Conformance

**Goal**: Implement SharingGRDB protocol conformance that bridges BackendQuery keys to GRDB ValueObservation streams.

## Files to Create

### 5.1 SharingGRDB Protocol Conformance

**File**: `Packages/Lib/Sources/LocalBackend/SharingKeys/BackendQuery+SharingGRDB.swift`

```swift
import Foundation
import GRDB
import SharingGRDB
import Core

// MARK: - SharingGRDB Protocol Conformance

extension BackendQuery: SharingGRDBKey {
    public typealias Value = Value

    /// Create a ValueObservation based on the query key
    public func valueObservation(_ db: Database) throws -> ValueObservation<DatabaseRegionConvertible, Value?> {

        // Parse the query key to determine what to observe
        let components = key.split(separator: ".").map(String.init)

        switch components.first {
        case "projects":
            return try projectsObservation(db, components: components)
        case "project":
            return try projectObservation(db, components: components)
        case "scheme":
            return try schemeObservation(db, components: components)
        case "schemes":
            return try schemesObservation(db, components: components)
        case "build":
            return try buildObservation(db, components: components)
        case "buildLog":
            return try buildLogObservation(db, components: components)
        case "crashLog":
            return try crashLogObservation(db, components: components)
        default:
            throw BackendQueryError.unsupportedQuery(key)
        }
    }
}

// MARK: - Query Parsing and Observation Creation

private extension BackendQuery {

    func projectsObservation(_ db: Database, components: [String]) throws -> ValueObservation<DatabaseRegionConvertible, Value?> {
        if components.count >= 2 && components[1] == "all" && components[2] == "ids" {
            // projects.all.ids -> [String]
            let observation = ValueObservation.tracking(
                ProjectValue.selectAll().fetchAll
            ).map { projects in
                projects.map(\.bundleIdentifier) as! Value
            }
            return observation.map { $0 as Value? }

        } else if components.count >= 2 && components[1] == "versionStrings" {
            // projects.versionStrings -> [String: [String]]
            let observation = ValueObservation.tracking { db in
                let rows = try Row.fetchAll(db, sql: """
                    SELECT p.bundleIdentifier, b.versionString
                    FROM projects p
                    JOIN schemes s ON p.bundleIdentifier = s.projectBundleIdentifier
                    JOIN builds b ON s.id = b.schemeId
                    GROUP BY p.bundleIdentifier, b.versionString
                    ORDER BY p.bundleIdentifier, b.versionString
                    """)

                var result: [String: [String]] = [:]
                for row in rows {
                    let projectId: String = row["bundleIdentifier"]
                    let version: String = row["versionString"]
                    result[projectId, default: []].append(version)
                }
                return result as! Value
            }
            return observation.map { $0 as Value? }
        }

        throw BackendQueryError.unsupportedQuery(key)
    }

    func projectObservation(_ db: Database, components: [String]) throws -> ValueObservation<DatabaseRegionConvertible, Value?> {
        guard components.count >= 2 else {
            throw BackendQueryError.malformedQuery(key)
        }

        let projectId = components[1]

        if components.count == 2 {
            // project.{id} -> ProjectValue?
            let observation = ValueObservation.tracking(
                ProjectValue.fetchOne(_:key: projectId)
            ).map { $0 as! Value? }
            return observation

        } else if components.count >= 3 {
            switch components[2] {
            case "detail":
                // project.{id}.detail -> ProjectDetailData
                let observation = ValueObservation.tracking { db -> ProjectDetailData? in
                    guard let project = try ProjectValue.fetchOne(db, key: projectId) else {
                        return nil
                    }

                    let schemeIds = try SchemeValue
                        .filter(Column("projectBundleIdentifier") == projectId)
                        .order(Column("order"))
                        .fetchAll(db)
                        .map(\.id)

                    let recentBuildIds = try BuildModelValue
                        .joining(required: BuildModelValue.scheme.joining(required: SchemeValue.project))
                        .filter(Column("bundleIdentifier") == projectId)
                        .order(Column("createdAt").desc)
                        .limit(10)
                        .fetchAll(db)
                        .map(\.id)

                    return ProjectDetailData(
                        project: project,
                        schemeIds: schemeIds,
                        recentBuildIds: recentBuildIds
                    )
                }.map { $0 as! Value? }
                return observation

            case "schemes":
                if components.count >= 4 && components[3] == "ids" {
                    // project.{id}.schemes.ids -> [UUID]
                    let observation = ValueObservation.tracking {
                        SchemeValue
                            .filter(Column("projectBundleIdentifier") == projectId)
                            .order(Column("order"))
                            .fetchAll($0)
                    }.map { schemes in
                        schemes.map(\.id) as! Value
                    }
                    return observation.map { $0 as Value? }
                }

            case "buildVersionStrings":
                // project.{id}.buildVersionStrings -> [String]
                let observation = ValueObservation.tracking { db in
                    let rows = try Row.fetchAll(db, sql: """
                        SELECT DISTINCT b.versionString
                        FROM builds b
                        JOIN schemes s ON b.schemeId = s.id
                        WHERE s.projectBundleIdentifier = ?
                        ORDER BY b.versionString DESC
                        """, arguments: [projectId])
                    return rows.map { $0["versionString"] as String } as! Value
                }
                return observation.map { $0 as Value? }

            case "latestBuilds":
                if components.count >= 4, let limitComponent = components[3].split(separator: "t").last,
                   let limit = Int(limitComponent) {
                    // project.{id}.latestBuilds.limit{N} -> [BuildModelValue]
                    let observation = ValueObservation.tracking { db in
                        try BuildModelValue
                            .joining(required: BuildModelValue.scheme.joining(required: SchemeValue.project))
                            .filter(Column("bundleIdentifier") == projectId)
                            .order(Column("createdAt").desc)
                            .limit(limit)
                            .fetchAll(db) as! Value
                    }
                    return observation.map { $0 as Value? }
                }
            }
        }

        throw BackendQueryError.unsupportedQuery(key)
    }

    func schemeObservation(_ db: Database, components: [String]) throws -> ValueObservation<DatabaseRegionConvertible, Value?> {
        guard components.count >= 2 else {
            throw BackendQueryError.malformedQuery(key)
        }

        let schemeIdString = components[1]

        // scheme.{id} -> SchemeValue?
        let observation = ValueObservation.tracking(
            SchemeValue.fetchOne(_:key: schemeIdString)
        ).map { $0 as! Value? }
        return observation
    }

    func schemesObservation(_ db: Database, components: [String]) throws -> ValueObservation<DatabaseRegionConvertible, Value?> {
        // Parse schemes.{id1,id2,id3}.builds.ids[.{version}]
        guard components.count >= 4,
              components[2] == "builds",
              components[3] == "ids" else {
            throw BackendQueryError.malformedQuery(key)
        }

        let schemeIdsString = components[1]
        let schemeIdStrings = schemeIdsString.split(separator: ",").map(String.init)

        var versionString: String? = nil
        if components.count >= 5 {
            versionString = components[4]
        }

        let observation = ValueObservation.tracking { db in
            var query = BuildModelValue
                .filter(schemeIdStrings.contains(Column("schemeId")))
                .order(Column("createdAt").desc)

            if let versionString = versionString {
                query = query.filter(Column("versionString") == versionString)
            }

            return try query.fetchAll(db).map(\.id) as! Value
        }
        return observation.map { $0 as Value? }
    }

    func buildObservation(_ db: Database, components: [String]) throws -> ValueObservation<DatabaseRegionConvertible, Value?> {
        guard components.count >= 2 else {
            throw BackendQueryError.malformedQuery(key)
        }

        let buildIdString = components[1]

        if components.count == 2 {
            // build.{id} -> BuildModelValue?
            let observation = ValueObservation.tracking(
                BuildModelValue.fetchOne(_:key: buildIdString)
            ).map { $0 as! Value? }
            return observation

        } else if components.count >= 4 && components[2] == "logs" && components[3] == "ids" {
            // build.{id}.logs.ids[.debug][.category{cat}] -> [UUID]
            guard let buildId = UUID(uuidString: buildIdString) else {
                throw BackendQueryError.malformedQuery(key)
            }

            var includeDebug = false
            var category: String? = nil

            // Parse additional components
            for i in 4..<components.count {
                let component = components[i]
                if component == "debug" {
                    includeDebug = true
                } else if component.hasPrefix("category") {
                    category = String(component.dropFirst("category".count))
                }
            }

            let observation = ValueObservation.tracking { db in
                var query = BuildLogValue
                    .filter(Column("buildId") == buildId.uuidString)
                    .order(Column("createdAt"))

                if !includeDebug {
                    query = query.filter(Column("level") != BuildLogLevel.debug.rawValue)
                }

                if let category = category {
                    query = query.filter(Column("category") == category)
                }

                return try query.fetchAll(db).map(\.id) as! Value
            }
            return observation.map { $0 as Value? }

        } else if components.count >= 4 && components[2] == "crashLogs" && components[3] == "ids" {
            // build.{id}.crashLogs.ids -> [String]
            guard let buildId = UUID(uuidString: buildIdString) else {
                throw BackendQueryError.malformedQuery(key)
            }

            let observation = ValueObservation.tracking {
                CrashLogValue
                    .filter(Column("buildId") == buildId.uuidString)
                    .order(Column("createdAt").desc)
                    .fetchAll($0)
            }.map { logs in
                logs.map(\.incidentIdentifier) as! Value
            }
            return observation.map { $0 as Value? }
        }

        throw BackendQueryError.unsupportedQuery(key)
    }

    func buildLogObservation(_ db: Database, components: [String]) throws -> ValueObservation<DatabaseRegionConvertible, Value?> {
        guard components.count >= 2 else {
            throw BackendQueryError.malformedQuery(key)
        }

        let buildLogIdString = components[1]

        // buildLog.{id} -> BuildLogValue?
        let observation = ValueObservation.tracking(
            BuildLogValue.fetchOne(_:key: buildLogIdString)
        ).map { $0 as! Value? }
        return observation
    }

    func crashLogObservation(_ db: Database, components: [String]) throws -> ValueObservation<DatabaseRegionConvertible, Value?> {
        guard components.count >= 2 else {
            throw BackendQueryError.malformedQuery(key)
        }

        let crashLogId = components[1]

        // crashLog.{id} -> CrashLogValue?
        let observation = ValueObservation.tracking(
            CrashLogValue.fetchOne(_:key: crashLogId)
        ).map { $0 as! Value? }
        return observation
    }
}

// MARK: - Error Types

public enum BackendQueryError: Error, LocalizedError {
    case unsupportedQuery(String)
    case malformedQuery(String)

    public var errorDescription: String? {
        switch self {
        case .unsupportedQuery(let key):
            return "Unsupported query: \(key)"
        case .malformedQuery(let key):
            return "Malformed query: \(key)"
        }
    }
}
```

### 5.2 GRDB Model Associations

**File**: `Packages/Lib/Sources/LocalBackend/Models/GRDBAssociations.swift`

```swift
import Foundation
import GRDB
import Core

// MARK: - GRDB Associations

extension ProjectValue {
    static let schemes = hasMany(SchemeValue.self, using: ForeignKey(["projectBundleIdentifier"]))
}

extension SchemeValue {
    static let project = belongsTo(ProjectValue.self, using: ForeignKey(["projectBundleIdentifier"]))
    static let builds = hasMany(BuildModelValue.self, using: ForeignKey(["schemeId"]))
}

extension BuildModelValue {
    static let scheme = belongsTo(SchemeValue.self, using: ForeignKey(["schemeId"]))
    static let buildLogs = hasMany(BuildLogValue.self, using: ForeignKey(["buildId"]))
    static let crashLogs = hasMany(CrashLogValue.self, using: ForeignKey(["buildId"]))
}

extension BuildLogValue {
    static let build = belongsTo(BuildModelValue.self, using: ForeignKey(["buildId"]))
}

extension CrashLogValue {
    static let build = belongsTo(BuildModelValue.self, using: ForeignKey(["buildId"]))
}
```

### 5.3 Domain Model Query Support

**File**: `Packages/Lib/Sources/LocalBackend/SharingKeys/DomainModelQuerySupport.swift`

```swift
import Foundation
import GRDB
import SharingGRDB
import Core

// MARK: - Domain Model Query Support

extension BackendQuery where Value == Project? {

    public func valueObservation(_ db: Database) throws -> ValueObservation<DatabaseRegionConvertible, Value?> {
        // Extract project ID from key like "project.{id}"
        let components = key.split(separator: ".").map(String.init)
        guard components.count >= 2, components[0] == "project" else {
            throw BackendQueryError.malformedQuery(key)
        }

        let projectId = components[1]

        let observation = ValueObservation.tracking(
            ProjectValue.fetchOne(_:key: projectId)
        ).map { backendValue -> Value? in
            guard let backendValue = backendValue else { return nil }
            return fromBackend(backendValue, to: Project.self) as? Value
        }

        return observation
    }
}

extension BackendQuery where Value == Scheme? {

    public func valueObservation(_ db: Database) throws -> ValueObservation<DatabaseRegionConvertible, Value?> {
        let components = key.split(separator: ".").map(String.init)
        guard components.count >= 2, components[0] == "scheme" else {
            throw BackendQueryError.malformedQuery(key)
        }

        let schemeIdString = components[1]

        let observation = ValueObservation.tracking(
            SchemeValue.fetchOne(_:key: schemeIdString)
        ).map { backendValue -> Value? in
            guard let backendValue = backendValue else { return nil }
            return fromBackend(backendValue, to: Scheme.self) as? Value
        }

        return observation
    }
}

extension BackendQuery where Value == Build? {

    public func valueObservation(_ db: Database) throws -> ValueObservation<DatabaseRegionConvertible, Value?> {
        let components = key.split(separator: ".").map(String.init)
        guard components.count >= 2, components[0] == "build" else {
            throw BackendQueryError.malformedQuery(key)
        }

        let buildIdString = components[1]

        let observation = ValueObservation.tracking(
            BuildModelValue.fetchOne(_:key: buildIdString)
        ).map { backendValue -> Value? in
            guard let backendValue = backendValue else { return nil }
            return fromBackend(backendValue, to: Build.self) as? Value
        }

        return observation
    }
}

extension BackendQuery where Value == BuildLog? {

    public func valueObservation(_ db: Database) throws -> ValueObservation<DatabaseRegionConvertible, Value?> {
        let components = key.split(separator: ".").map(String.init)
        guard components.count >= 2, components[0] == "buildLog" else {
            throw BackendQueryError.malformedQuery(key)
        }

        let buildLogIdString = components[1]

        let observation = ValueObservation.tracking(
            BuildLogValue.fetchOne(_:key: buildLogIdString)
        ).map { backendValue -> Value? in
            guard let backendValue = backendValue else { return nil }
            return fromBackend(backendValue, to: BuildLog.self) as? Value
        }

        return observation
    }
}

extension BackendQuery where Value == CrashLog? {

    public func valueObservation(_ db: Database) throws -> ValueObservation<DatabaseRegionConvertible, Value?> {
        let components = key.split(separator: ".").map(String.init)
        guard components.count >= 2, components[0] == "crashLog" else {
            throw BackendQueryError.malformedQuery(key)
        }

        let crashLogId = components[1]

        let observation = ValueObservation.tracking(
            CrashLogValue.fetchOne(_:key: crashLogId)
        ).map { backendValue -> Value? in
            guard let backendValue = backendValue else { return nil }
            return fromBackend(backendValue, to: CrashLog.self) as? Value
        }

        return observation
    }
}

extension BackendQuery where Value == [Build] {

    public func valueObservation(_ db: Database) throws -> ValueObservation<DatabaseRegionConvertible, Value?> {
        // Handle queries like "project.{id}.latestBuilds.limit{N}"
        let components = key.split(separator: ".").map(String.init)
        guard components.count >= 4,
              components[0] == "project",
              components[2] == "latestBuilds",
              components[3].hasPrefix("limit") else {
            throw BackendQueryError.malformedQuery(key)
        }

        let projectId = components[1]
        guard let limitString = components[3].split(separator: "t").last,
              let limit = Int(limitString) else {
            throw BackendQueryError.malformedQuery(key)
        }

        let observation = ValueObservation.tracking { db in
            try BuildModelValue
                .joining(required: BuildModelValue.scheme.joining(required: SchemeValue.project))
                .filter(Column("bundleIdentifier") == projectId)
                .order(Column("createdAt").desc)
                .limit(limit)
                .fetchAll(db)
        }.map { backendValues -> Value? in
            return fromBackendArray(backendValues, to: Build.self) as? Value
        }

        return observation
    }
}
```

### 5.4 Backend Configuration for SharingGRDB

**File**: `Packages/Lib/Sources/LocalBackend/SharingKeys/BackendSharingConfiguration.swift`

```swift
import Foundation
import GRDB
import SharingGRDB
import Core

/// Configuration for using BackendQuery with SharingGRDB
public struct BackendSharingConfiguration {
    public let databasePool: DatabasePool

    public init(databasePool: DatabasePool) {
        self.databasePool = databasePool
    }

    /// Set up SharingGRDB to use the backend database
    public func configureSharingGRDB() {
        // This would typically be done in your app's main setup
        // The SharingGRDB library will automatically use the database pool
        // when BackendQuery keys are accessed via @Shared properties
    }
}

// MARK: - Helper for App Integration

public extension LocalBackendService {

    /// Get the database pool for SharingGRDB integration
    var databasePoolForSharing: DatabasePool {
        return dbPool
    }
}
```

## Implementation Checklist

- [ ] Create `BackendQuery+SharingGRDB.swift` with SharingGRDBKey conformance
- [ ] Create `GRDBAssociations.swift` with model relationships
- [ ] Create `DomainModelQuerySupport.swift` for automatic conversions
- [ ] Create `BackendSharingConfiguration.swift` for setup
- [ ] Implement query parsing logic for all supported queries:
  - [ ] Project queries (all IDs, individual project, version strings, etc.)
  - [ ] Scheme queries (individual scheme, scheme IDs)
  - [ ] Build queries (individual build, build IDs, latest builds)
  - [ ] Build log queries (individual log, log IDs with filters)
  - [ ] Crash log queries (individual log, crash log IDs)
- [ ] Test SharingGRDBKey protocol conformance works
- [ ] Test automatic domain model conversion in observations
- [ ] Verify query key parsing handles edge cases correctly

## Usage Examples

```swift
// Using with SharingGRDB (this will be automatic once configured)
@Shared(ProjectQueries.allIds)
var projectIds: [String]

@Shared(DomainProjectQueries.project(id: "com.example.app"))
var project: Project?

// The SharingGRDB integration will automatically:
// 1. Parse the BackendQuery key
// 2. Create appropriate GRDB ValueObservation
// 3. Convert backend values to domain models (when using Domain queries)
// 4. Provide reactive updates when database changes
```

## Integration Notes

- This step creates the bridge between BackendQuery keys and GRDB observations
- The SharingGRDBKey protocol conformance enables automatic reactive updates
- Domain model queries automatically convert backend values using the conversion protocols from Step 2
- Query parsing logic supports the full range of queries defined in the BackendQuery factory methods

## Next Step

After completing this step, proceed to [Step 6: Backend Service Integration](./STEP_6_BACKEND_SERVICE_CONTAINER.md) to set up Dependencies-based dependency injection.
