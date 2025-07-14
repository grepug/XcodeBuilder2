import Foundation
import Dependencies

struct XcodeBuildPayload {
    let project: Project
    let schemeName: String
    let version: Version
    let exportOptions: Set<ExportOption>
}

struct XcodeBuildProgress {
    let progress: Double
    let message: String
    var isFinished = false
}

struct XcodeBuildLogger: Sendable {
    var info: @Sendable (String) -> Void
    var warning: @Sendable (String) -> Void
    var error: @Sendable (String) -> Void
}

actor XcodeBuildManager: Sendable {
    let payload: XcodeBuildPayload
    let logger: XcodeBuildLogger
    
    typealias Stream = AsyncThrowingStream<XcodeBuildProgress, Error>
    
    @Dependency(\.xcodeBuildPathManager) var pathManager
    @Dependency(\.ipaUploader) var ipaUploader
    
    init(payload: XcodeBuildPayload, logger: XcodeBuildLogger) {
        self.payload = payload
        self.logger = logger
    }
    
    func startBuild() -> Stream {
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
        
        continuation.yield(.init(progress: 0.1, message: "Cloning repository..."))
        
        try await resolvePackageDependencies()
        
        continuation.yield(.init(progress: 0.3, message: "Resolving package dependencies..."))
        
        try await archiveProject()
        
        continuation.yield(.init(progress: 0.9, message: "Archiving project..."))

        try await cleanup()
        
        continuation.yield(.init(progress: 1, message: "Build completed successfully.", isFinished: true))
    }
}

private extension XcodeBuildManager {
    var projectPath: String {
        pathManager.projectPath(for: payload.project, version: payload.version)
    }
    
    var archivePath: String {
        pathManager.archivePath(for: payload.project, version: payload.version)
    }
    
    var derivedDataPath: String {
        pathManager.derivedDataPath(for: payload.project, version: payload.version)
    }
    
    var exportPath: String? {
        pathManager.exportPath(for: payload.project, version: payload.version)
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
            try await GitCommand(path: projectPath).clone(remoteURL: payload.project.gitRepoURL)

            logger.info("Repository cloned successfully.")
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
                project: payload.project,
                scheme: scheme,
                version: payload.version,
                platform: firstPlatform,
                archivePath: archivePath,
                derivedDataPath: derivedDataPath,
                exportPath: exportPath,
            )
            
            try await command.run()
            
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
        
        let commands = platforms.map { platform in
            XcodeBuildCommand(
                kind: .archive,
                project: payload.project,
                scheme: scheme,
                version: payload.version,
                platform: platform,
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
                        
                        try await command.run()
                        
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
            exportOptions.remove(.releaseTesting)
        }

        let exportToAppStoreCommand = XcodeBuildCommand(
            kind: .exportArchive,
            project: payload.project,
            scheme: scheme,
            version: payload.version,
            platform: platform,
            exportOption: .appStore, 
            archivePath: archivePath,
            derivedDataPath: derivedDataPath,
            exportPath: nil,
        )

        let exportToReleaseTestingCommand = XcodeBuildCommand(
            kind: .exportArchive,
            project: payload.project,
            scheme: scheme,
            version: payload.version,
            platform: platform,
            exportOption: .releaseTesting,
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
                        try await exportToAppStoreCommand.run()
                    case .releaseTesting:
                        self.logger.info("Exporting archive for platform \(platform) to Release Testing at \(exportToReleaseTestingCommand.exportOption!)")
                        try await exportToReleaseTestingCommand.run()
                        _ = try await uploader.upload(project: project, version: version, ipaPath: exportToReleaseTestingCommand.exportPath!)
                    }
                }
            }
            
            try await group.waitForAll()
        }
    }

    func cleanup() async throws {
        logger.info("Cleaning up project at \(projectPath)")
        do {
            try FileManager.default.removeItem(atPath: derivedDataPath)
            try FileManager.default.removeItem(atPath: projectPath)

            logger.info("Project cleaned up successfully.")
        } catch {
            logger.warning("Failed to clean up project: \(error.localizedDescription)")
        }
    }
}

private extension XcodeBuildCommand {
    func run() async throws {
        try await runShellCommandComplete(command)
    }
}
