import Foundation

// MARK: - Protocol Extensions with toValue() Methods
public extension ProjectProtocol {
    func toValue() -> ProjectValue {
        ProjectValue(
            bundleIdentifier: bundleIdentifier,
            name: name,
            displayName: displayName,
            gitRepoURL: gitRepoURL,
            xcodeprojName: xcodeprojName,
            workingDirectoryURL: workingDirectoryURL,
            createdAt: createdAt
        )
    }
}

public extension SchemeProtocol {
    func toValue() -> SchemeValue {
        SchemeValue(
            id: id,
            projectBundleIdentifier: projectBundleIdentifier,
            name: name,
            platforms: platforms,
            order: order
        )
    }
}

public extension BuildModelProtocol {
    func toValue() -> BuildModelValue {
        BuildModelValue(
            id: id,
            schemeId: schemeId,
            version: Version(version: versionString, buildNumber: buildNumber, commitHash: commitHash),
            createdAt: createdAt,
            startDate: startDate,
            endDate: endDate,
            exportOptions: exportOptions,
            status: status,
            progress: progress,
            deviceMetadata: deviceMetadata,
            osVersion: osVersion,
            memory: memory,
            processor: processor
        )
    }
}

public extension BuildLogProtocol {
    func toValue() -> BuildLogValue {
        BuildLogValue(
            id: id,
            buildId: buildId,
            category: category,
            level: level,
            content: content,
            createdAt: createdAt
        )
    }
}

public extension CrashLogProtocol {
    func toValue() -> CrashLogValue {
        CrashLogValue(
            incidentIdentifier: incidentIdentifier,
            isMainThread: isMainThread,
            createdAt: createdAt,
            buildId: buildId,
            content: content,
            hardwareModel: hardwareModel,
            process: process,
            role: role,
            dateTime: dateTime,
            launchTime: launchTime,
            osVersion: osVersion,
            note: note,
            fixed: fixed,
            priority: priority
        )
    }
}
