import Dependencies

// MARK: - ProjectStreamingService

private enum ProjectStreamingServiceKey: DependencyKey {
    static let liveValue = ProjectStreamingService()
    static let testValue = ProjectStreamingService()
}

extension DependencyValues {
    var projectStreamingService: ProjectStreamingService {
        get { self[ProjectStreamingServiceKey.self] }
        set { self[ProjectStreamingServiceKey.self] = newValue }
    }
}

// MARK: - SchemeStreamingService

private enum SchemeStreamingServiceKey: DependencyKey {
    static let liveValue = SchemeStreamingService()
    static let testValue = SchemeStreamingService()
}

extension DependencyValues {
    var schemeStreamingService: SchemeStreamingService {
        get { self[SchemeStreamingServiceKey.self] }
        set { self[SchemeStreamingServiceKey.self] = newValue }
    }
}

// MARK: - BuildStreamingService

private enum BuildStreamingServiceKey: DependencyKey {
    static let liveValue = BuildStreamingService()
    static let testValue = BuildStreamingService()
}

extension DependencyValues {
    var buildStreamingService: BuildStreamingService {
        get { self[BuildStreamingServiceKey.self] }
        set { self[BuildStreamingServiceKey.self] = newValue }
    }
}

// MARK: - LogStreamingService

private enum LogStreamingServiceKey: DependencyKey {
    static let liveValue = LogStreamingService()
    static let testValue = LogStreamingService()
}

extension DependencyValues {
    var logStreamingService: LogStreamingService {
        get { self[LogStreamingServiceKey.self] }
        set { self[LogStreamingServiceKey.self] = newValue }
    }
}
