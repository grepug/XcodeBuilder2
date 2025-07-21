import Foundation

// MARK: - Usage Examples and Documentation

/*
 BackendQuery Usage Examples:

 1. Basic usage with backend values:
 ```swift
 @Shared(.project(id: "com.example.app"))
 var project: ProjectValue?

 @Shared(.allProjectIds())
 var projectIds: [String]
 ```

 2. Using type-safe query builders:
 ```swift
 @Shared(ProjectQueries.project(id: "com.example.app"))
 var project: ProjectValue?

 @Shared(BuildQueries.latestBuilds(projectId: "com.example.app", limit: 5))
 var recentBuilds: [BuildModelValue]
 ```

 3. Domain model queries (with automatic conversion):
 ```swift
 @Shared(DomainProjectQueries.project(id: "com.example.app"))
 var project: Project?

 @Shared(DomainBuildQueries.latestBuilds(projectId: "com.example.app"))
 var recentBuilds: [BuildModel]
 ```

 4. Complex queries:
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
 */

// MARK: - Helper Functions for Common Patterns

public extension BackendQuery {

    /// Create a query that depends on multiple other queries
    static func dependent<T1, T2>(
        on query1: BackendQuery<T1>,
        and query2: BackendQuery<T2>,
        key: String
    ) -> BackendQuery<Value> {
        BackendQuery<Value>("dependent.\(query1.key).\(query2.key).\(key)")
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
        return BackendQuery<Value>("\(base).\(paramString)")
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
