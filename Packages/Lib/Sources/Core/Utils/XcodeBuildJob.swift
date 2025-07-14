import Foundation
import Dependencies

public struct XcodeBuildPayload {
    let project: Project
    let schemeName: String
    let version: Version
    let exportOptions: [ExportOption]
    
    public init(project: Project, schemeName: String, version: Version, exportOptions: [ExportOption]) {
        self.project = project
        self.schemeName = schemeName
        self.version = version
        self.exportOptions = exportOptions
    }
}

public struct XcodeBuildProgress {
    public let progress: Double
    public let message: String
    public var isFinished = false
}

public struct XcodeBuildLogger: Sendable {
    var info: @Sendable (String) -> Void
    var warning: @Sendable (String) -> Void
    var error: @Sendable (String) -> Void
    
    public init(info: @escaping @Sendable (String) -> Void, warning: @escaping @Sendable (String) -> Void, error: @escaping @Sendable (String) -> Void) {
        self.info = info
        self.warning = warning
        self.error = error
    }
}

public actor XcodeBuildJob: Sendable {
    let payload: XcodeBuildPayload
    let logger: XcodeBuildLogger
    
    public typealias Stream = AsyncThrowingStream<XcodeBuildProgress, Error>
    
    @Dependency(\.xcodeBuildPathManager) var pathManager
    @Dependency(\.ipaUploader) var ipaUploader
    
    public init(payload: XcodeBuildPayload, logger: XcodeBuildLogger) {
        self.payload = payload
        self.logger = logger
    }
    
    public func startBuild() -> Stream {
        // Implementation for starting the build process
        // This would typically involve invoking xcodebuild with the appropriate parameters
        
        let (stream, continuation) = Stream.makeStream()
        
        let task = Task {
            do {
                try await self.build(continuation: continuation)
            } catch {
                self.logger.error("Build failed: \(error.localizedDescription)")

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
    }
}

private extension XcodeBuildJob {
    var projectPath: String {
        ensuredPath(pathManager.projectPath(for: payload.project, version: payload.version))
    }
    
    var xcodeprojPath: String {
        ensuredPath(pathManager.xcodeprojPath(for: payload.project, version: payload.version))
    }
    
    var archivePath: String {
        ensuredPath(pathManager.archivePath(for: payload.project, version: payload.version))
    }
    
    var derivedDataPath: String {
        ensuredPath(pathManager.derivedDataPath(for: payload.project, version: payload.version))
    }
    
    var exportPath: String? {
        pathManager.exportPath(for: payload.project, version: payload.version)
            .map { ensuredPath($0) }
    }
    
    var scheme: Scheme {
        guard let scheme = payload.project.schemes.first(where: { $0.name == payload.schemeName }) else {
            fatalError("Scheme \(payload.schemeName) not found in project \(payload.project.name)")
        }
        return scheme
    }
    
    func cloneRepository() async throws {
        logger.info("Cloning repository at \(payload.project.gitRepoURL)")
        
        do {
            try await GitCommand(path: projectPath).clone(
                remoteURL: payload.project.gitRepoURL,
                tag: payload.version.tagName,
            )
            
            logger.info("Repository cloned successfully.")
            
            updateVersions(
                url: URL(filePath: projectPath),
                version: payload.version.version,
                buildNumber: "\(payload.version.buildNumber)",
            )
            
            logger.info("Updated project versions to \(payload.version.version) (build \(payload.version.buildNumber))")
        } catch {
            logger.error("Failed to clone repository: \(error.localizedDescription)")
            
            throw error
        }
    }
    
    func resolvePackageDependencies() async throws {
        logger.info("Resolving package dependencies for \(payload.project.name)")
        
        do {
            let firstPlatform = payload.project.schemes.first?.platforms.first ?? .iOS
            
            let command = XcodeBuildCommand(
                kind: .resolvePackageDependencies,
                scheme: scheme,
                version: payload.version,
                platform: firstPlatform,
                projectPath: xcodeprojPath,
                archivePath: archivePath,
                derivedDataPath: derivedDataPath,
                exportPath: exportPath,
            )
            
            print("command2: \(command.string)")
            
            try await runShellCommand2(command.string).get()
            
            logger.info("Package dependencies resolved successfully.")
        } catch {
            logger.error("Failed to resolve package dependencies: \(error.localizedDescription)")
            throw error
        }
    }
    
    func archiveProject() async throws {
        let logger = self.logger
        
        logger.info("Archiving project \(payload.project.name)")
        
        let platforms = payload.project.schemes.flatMap { $0.platforms }
        let archivePath = archivePath
        
        assert(!platforms.isEmpty, "No platforms found in project \(payload.project.name)")
        
        let commands = platforms.map { platform in
            XcodeBuildCommand(
                kind: .archive,
                scheme: scheme,
                version: payload.version,
                platform: platform,
                projectPath: xcodeprojPath,
                archivePath: archivePath,
                derivedDataPath: derivedDataPath,
                exportPath: exportPath
            )
        }
        
        do {
            try await withThrowingTaskGroup { group in
                for (index, command) in commands.enumerated() {
                    group.addTask {
                        let delaySeconds = Double(index) * 60 * 0.3
                        
                        try await Task.sleep(for: .seconds(delaySeconds))
                        
//                        try await runShellCommandComplete(command.string)
                        
                        logger.info("Running archive command: \(command.string)")
                        
                        for try await output in await runShellCommand2(command.string) {
                            print("output: \(output)")
                        }
                        
                        logger.info("Project archived successfully at \(archivePath)")
                        
                        try await self.exportArchive(platform: command.platform)
                    }
                }
                
                try await group.waitForAll()
            }
            
            logger.info("Project archived successfully at \(archivePath)")
        } catch {
            logger.error("Failed to archive project: \(error.localizedDescription)")
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
            projectPath: xcodeprojPath,
            archivePath: archivePath,
            derivedDataPath: derivedDataPath,
            exportPath: nil,
        )

        let exportToReleaseTestingCommand = XcodeBuildCommand(
            kind: .exportArchive,
            scheme: scheme,
            version: payload.version,
            platform: platform,
            exportOption: .releaseTesting,
            projectPath: xcodeprojPath,
            archivePath: archivePath,
            derivedDataPath: derivedDataPath,
            exportPath: exportPath,
        )

        let project = payload.project
        let version = payload.version
        let uploader = ipaUploader
        
        try await withThrowingTaskGroup { group in
            for option in exportOptions {
                group.addTask {
                    switch option {
                    case .appStore:
                        self.logger.info("Exporting archive for platform \(platform) to App Store")
                        try await runShellCommandComplete(exportToAppStoreCommand.string)
                    case .releaseTesting:
                        self.logger.info("Exporting archive for platform \(platform) to Release Testing at \(exportToReleaseTestingCommand.exportOption!)")
                        try await runShellCommandComplete(exportToReleaseTestingCommand.string)
                        _ = try await uploader.upload(project: project, version: version, ipaPath: exportToReleaseTestingCommand.exportPath!)
                    }
                }
            }
            
            try await group.waitForAll()
        }
    }

    func cleanup() async throws {
        logger.info("Cleaning up project at \(xcodeprojPath)")
        do {
            try FileManager.default.removeItem(atPath: derivedDataPath)
            try FileManager.default.removeItem(atPath: xcodeprojPath)

            logger.info("Project cleaned up successfully.")
        } catch {
            logger.warning("Failed to clean up project: \(error.localizedDescription)")
        }
    }
}

//private extension XcodeBuildCommand {
//    func run() async throws {
//        try await runShellCommandComplete(command)
//    }
//}
