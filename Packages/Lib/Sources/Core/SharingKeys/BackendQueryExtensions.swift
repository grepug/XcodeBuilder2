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
    public static func build(id: UUID) -> BackendQuery<BuildModel?> {
        .domainBuild(id: id)
    }

    public static func latestBuilds(projectId: String, limit: Int = 10) -> BackendQuery<[BuildModel]> {
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
