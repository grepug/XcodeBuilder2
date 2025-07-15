import Foundation
import Dependencies

public struct XcodeBuildPayload {
    let project: Project
    let scheme: Scheme
    let version: Version
    let exportOptions: [ExportOption]
    let buildId: UUID

    public init(project: Project, scheme: Scheme, version: Version, exportOptions: [ExportOption], buildId: UUID) {
        self.project = project
        self.scheme = scheme
        self.version = version
        self.exportOptions = exportOptions
        self.buildId = buildId
    }
}

public struct XcodeBuildProgress: Sendable {
    public let progress: Double
    public let message: String
    public var isFinished = false
}

public actor XcodeBuildJob: Sendable {
    let payload: XcodeBuildPayload
    let log: (BuildLog) -> Void
    
    public typealias Stream = AsyncThrowingStream<XcodeBuildProgress, Error>
    
    @Dependency(\.xcodeBuildPathManager) var pathManager
    @Dependency(\.ipaUploader) var ipaUploader

    public init(payload: XcodeBuildPayload, log: @escaping (BuildLog) -> Void) {
        self.payload = payload
        self.log = log
    }
    
    public func startBuild() -> Stream {
        // Implementation for starting the build process
        // This would typically involve invoking xcodebuild with the appropriate parameters
        
        let (stream, continuation) = Stream.makeStream()
        
        let task = Task {
            do {
                try await self.build(continuation: continuation)
            } catch {
                log("Build failed: \(error.localizedDescription)", at: .error)

                try await self.cleanup()

                continuation.finish(throwing: error)
            }
        }
        
        continuation.onTermination = { reason in
            switch reason {
            case .cancelled:
                task.cancel()
            default:
                break
            }
        }
        
        return stream
    }
    
    func build(continuation: Stream.Continuation) async throws {
        try await cloneRepository()
        
        continuation.yield(.init(progress: 0.1, message: "Cloned repository..."))
        
        try await resolvePackageDependencies()
        
        continuation.yield(.init(progress: 0.3, message: "Resolved package dependencies..."))
        
        try await archiveProject()
        
        continuation.yield(.init(progress: 0.9, message: "Archived project..."))

        try await cleanup()
        
        continuation.yield(.init(progress: 1, message: "Build completed successfully.", isFinished: true))
        
        continuation.finish()
    }
}

private extension XcodeBuildJob {
    var projectURL: URL {
        ensuredURL(pathManager.projectURL(for: payload.project, version: payload.version))
    }
    
    var xcodeprojURL: URL {
        ensuredURL(pathManager.xcodeprojURL(for: payload.project, version: payload.version))
    }
    
    var archiveURL: URL {
        ensuredURL(pathManager.archiveURL(for: payload.project, version: payload.version))
    }
    
    var derivedDataURL: URL {
        ensuredURL(pathManager.derivedDataURL(for: payload.project, version: payload.version))
    }
    
    var exportURL: URL? {
        pathManager.exportURL(for: payload.project, version: payload.version)
            .map { ensuredURL($0) }
    }
    
    var scheme: Scheme {
        payload.scheme
    }

    func log(_ content: String, at level: BuildLog.Level = .info) {
        let logEntry = BuildLog(buildId: payload.buildId, content: content, level: level)
        log(logEntry)
    }
    
    func cloneRepository() async throws {
        log("Cloning repository at \(payload.project.gitRepoURL)")
        
        do {
            try await GitCommand(pathURL: projectURL).clone(
                remoteURL: payload.project.gitRepoURL,
                tag: payload.version.tagName,
            )
            
            log("Repository cloned successfully.")
            
            updateVersions(
                url: projectURL,
                version: payload.version.version,
                buildNumber: "\(payload.version.buildNumber)",
            )
            
            log("Updated project versions to \(payload.version.version) (build \(payload.version.buildNumber))")
        } catch {
            log("Failed to clone repository: \(error.localizedDescription)", at: .error)
            
            throw error
        }
    }
    
    func resolvePackageDependencies() async throws {
        log("Resolving package dependencies for \(payload.project.name)")

        
        do {
            let command = XcodeBuildCommand(
                kind: .resolvePackageDependencies,
                scheme: scheme,
                version: payload.version,
                platform: .iOS,
                projectURL: xcodeprojURL,
                archiveURL: archiveURL,
                derivedDataURL: derivedDataURL,
                exportURL: exportURL,
            )
            
            print("command2: \(command.string)")
            
            try await runShellCommand2(command.string).get()

            log("Package dependencies resolved successfully.")
        } catch {
            log("Failed to resolve package dependencies: \(error.localizedDescription)", at: .error)
            throw error
        }
    }
    
    func archiveProject() async throws {
        log("Archiving project \(payload.project.name)")
        let archiveURL = archiveURL
        let platforms = scheme.platforms
        let archivePath = archiveURL.path()
        
        assert(!platforms.isEmpty, "No platforms found in project \(payload.project.name)")
        assert(Set(platforms).count == platforms.count, "Duplicate platforms found: \(platforms)")
        
        let commands = platforms.map { platform in
            XcodeBuildCommand(
                kind: .archive,
                scheme: scheme,
                version: payload.version,
                platform: platform,
                projectURL: xcodeprojURL,
                archiveURL: archiveURL,
                derivedDataURL: derivedDataURL,
                exportURL: exportURL
            )
        }
        
        do {
            try await withThrowingTaskGroup { group in
                for (index, command) in commands.enumerated() {
                    group.addTask {
                        let delaySeconds = Double(index) * 60 * 0.3
                        
                        try await Task.sleep(for: .seconds(delaySeconds))
                        
                        await self.log("Running archive command: \(command.string)")
                        
                        for try await output in await runShellCommand2(command.string) {
                            print("output: \(output)")
                        }

                        await self.log("Project archived successfully at \(archivePath)")

                        try await self.exportArchive(platform: command.platform)
                    }
                }
                
                try await group.waitForAll()
            }

            log("Project archived successfully at \(archivePath)")
        } catch {
            log("Failed to archive project: \(error.localizedDescription)", at: .error)
            throw error
        }
    }
    
    func exportArchive(platform: Platform) async throws {
        var exportOptions = payload.exportOptions
        
        if platform != .iOS {
            // Remove release testing option for non-iOS platforms
            exportOptions.removeAll { $0 == .releaseTesting }
        }
        
        assert(Set(exportOptions).count == exportOptions.count, "Duplicate export options found: \(exportOptions)")

        let exportToAppStoreCommand = XcodeBuildCommand(
            kind: .exportArchive,
            scheme: scheme,
            version: payload.version,
            platform: platform,
            exportOption: .appStore,
            projectURL: xcodeprojURL,
            archiveURL: archiveURL,
            derivedDataURL: derivedDataURL,
            exportURL: nil,
        )

        let exportToReleaseTestingCommand = XcodeBuildCommand(
            kind: .exportArchive,
            scheme: scheme,
            version: payload.version,
            platform: platform,
            exportOption: .releaseTesting,
            projectURL: xcodeprojURL,
            archiveURL: archiveURL,
            derivedDataURL: derivedDataURL,
            exportURL: exportURL,
        )

        let project = payload.project
        let version = payload.version
        let uploader = ipaUploader
        
        try await withThrowingTaskGroup { group in
            for option in exportOptions {
                group.addTask {
                    switch option {
                    case .appStore:
                        await self.log("Exporting archive for platform \(platform) to App Store")
                        try await runShellCommandComplete(exportToAppStoreCommand.string)
                    case .releaseTesting:
                        await self.log("Exporting archive for platform \(platform) to Release Testing at \(exportToReleaseTestingCommand.exportOption!)")
                        try await runShellCommandComplete(exportToReleaseTestingCommand.string)
                        _ = try await uploader.upload(project: project, version: version, ipaURL: exportToReleaseTestingCommand.exportURL!)
                    }
                }
            }
            
            try await group.waitForAll()
        }
    }

    func cleanup() async throws {
        log("Cleaning up project at \(xcodeprojURL.path())")
        do {
            try FileManager.default.removeItem(atPath: derivedDataURL.path())
//            try FileManager.default.removeItem(atPath: projectURL.path())

            log("Project cleaned up successfully.")
        } catch {
            log("Failed to clean up project: \(error.localizedDescription)", at: .warning)
        }
    }
}

//private extension XcodeBuildCommand {
//    func run() async throws {
//        try await runShellCommandComplete(command)
//    }
//}
