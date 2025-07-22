import Dependencies

/// Dependency injection keys for data services
extension DependencyValues {
    var projectDataService: ProjectDataService {
        get { self[ProjectDataServiceKey.self] }
        set { self[ProjectDataServiceKey.self] = newValue }
    }
    
    var schemeDataService: SchemeDataService {
        get { self[SchemeDataServiceKey.self] }
        set { self[SchemeDataServiceKey.self] = newValue }
    }
    
    var buildDataService: BuildDataService {
        get { self[BuildDataServiceKey.self] }
        set { self[BuildDataServiceKey.self] = newValue }
    }
    
    var logDataService: LogDataService {
        get { self[LogDataServiceKey.self] }
        set { self[LogDataServiceKey.self] = newValue }
    }
}

// MARK: - Dependency Keys

private enum ProjectDataServiceKey: DependencyKey {
    static let liveValue = ProjectDataService()
    static let testValue = ProjectDataService()
}

private enum SchemeDataServiceKey: DependencyKey {
    static let liveValue = SchemeDataService()
    static let testValue = SchemeDataService()
}

private enum BuildDataServiceKey: DependencyKey {
    static let liveValue = BuildDataService()
    static let testValue = BuildDataService()
}

private enum LogDataServiceKey: DependencyKey {
    static let liveValue = LogDataService()
    static let testValue = LogDataService()
}
