import Foundation
import Dependencies

public enum LocalBuildJobManagerKey: DependencyKey {
    public static let liveValue = LocalBuildJobManager()
}

public extension DependencyValues {
    var localBuildJobManager: LocalBuildJobManager {
        get { self[LocalBuildJobManagerKey.self] }
        set { self[LocalBuildJobManagerKey.self] = newValue }
    }
}
