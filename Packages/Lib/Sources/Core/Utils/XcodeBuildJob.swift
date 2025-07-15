import Foundation
import Dependencies

// MARK: - DateFormatter Extension
private extension DateFormatter {
    static let logFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }()
}

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
                log("""
                ❌ BUILD FAILED
                   • Error: \(error.localizedDescription)
                   • Error Type: \(type(of: error))
                """, at: .error)

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
        log("""
        🚀 BUILD STARTED
        📋 Build Configuration:
           • Project: \(payload.project.name)
           • Scheme: \(payload.scheme.name)
           • Version: \(payload.version.version) (build \(payload.version.buildNumber))
           • Platforms: \(payload.scheme.platforms.map(\.rawValue).joined(separator: ", "))
           • Export Options: \(payload.exportOptions.map(\.rawValue).joined(separator: ", "))
        """, at: .info)
        
        continuation.yield(.init(progress: 0.05, message: "🚀 Build started - Initializing..."))
        
        try await cloneRepository()
        continuation.yield(.init(progress: 0.20, message: "📦 Repository cloned successfully"))
        
        try await resolvePackageDependencies()
        continuation.yield(.init(progress: 0.35, message: "🔗 Package dependencies resolved"))
        
        continuation.yield(.init(progress: 0.40, message: "🔨 Starting archive process..."))
        try await archiveProject()
        continuation.yield(.init(progress: 0.90, message: "📁 Project archived successfully"))

        try await cleanup()
        continuation.yield(.init(progress: 0.95, message: "🧹 Cleanup completed"))
        
        log("✅ BUILD COMPLETED SUCCESSFULLY", at: .info)
        continuation.yield(.init(progress: 1.0, message: "✅ Build completed successfully!", isFinished: true))
        
        continuation.finish()
    }
}

// MARK: - Progress Helper
private struct ProgressTracker {
    let totalSteps: Int
    let baseProgress: Double
    let maxProgress: Double
    
    func progress(for step: Int) -> Double {
        let stepProgress = Double(step) / Double(totalSteps)
        return baseProgress + (stepProgress * (maxProgress - baseProgress))
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
        let timestamp = DateFormatter.logFormatter.string(from: Date())
        let formattedContent = "[\(timestamp)] \(content)"
        let logEntry = BuildLog(buildId: payload.buildId, content: formattedContent, level: level)
        log(logEntry)
    }
    
    func cloneRepository() async throws {
        log("""
        📂 CLONE STAGE: Starting repository clone
           • Repository URL: \(payload.project.gitRepoURL)
           • Target Tag: \(payload.version.tagName)
           • Clone Path: \(projectURL.path())
        """, at: .info)
        
        do {
            let gitCommand = GitCommand(pathURL: projectURL)
            
            log("🔧 DEBUG: Git clone command initialized", at: .debug)
            
            try await gitCommand.clone(
                remoteURL: payload.project.gitRepoURL,
                tag: payload.version.tagName,
            )
            
            log("✅ Repository cloned successfully", at: .info)
            
            log("🔄 Updating project versions...", at: .info)
            
            updateVersions(
                url: projectURL,
                version: payload.version.version,
                buildNumber: "\(payload.version.buildNumber)",
            )
            
            log("""
            ✅ Project versions updated to \(payload.version.version) (build \(payload.version.buildNumber))
            📂 CLONE STAGE: Completed successfully
            """, at: .info)
        } catch {
            log("""
            ❌ CLONE STAGE: Failed to clone repository
               • Error: \(error.localizedDescription)
            """, at: .error)
            
            throw error
        }
    }
    
    func resolvePackageDependencies() async throws {
        log("""
        🔗 RESOLVE DEPENDENCIES STAGE: Starting package dependency resolution
           • Project: \(payload.project.name)
           • Project Path: \(xcodeprojURL.path())
           • Scheme: \(scheme.name)
        """, at: .info)

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
            
            log("""
            🔧 DEBUG: Executing command:
               • Command: \(command.string)
            """, at: .debug)
            
            try await runShellCommand2(command.string).get()

            log("""
            ✅ Package dependencies resolved successfully
            🔗 RESOLVE DEPENDENCIES STAGE: Completed successfully
            """, at: .info)
        } catch {
            log("""
            ❌ RESOLVE DEPENDENCIES STAGE: Failed to resolve package dependencies
               • Error: \(error.localizedDescription)
            """, at: .error)
            throw error
        }
    }
    
    func archiveProject() async throws {
        let platforms = scheme.platforms
        
        log("""
        📁 ARCHIVE STAGE: Starting project archiving
           • Project: \(payload.project.name)
           • Archive Path: \(archiveURL.path())
           • Target Platforms: \(platforms.map(\.rawValue).joined(separator: ", "))
        """, at: .info)
        
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
        
        log("🔧 DEBUG: Generated \(commands.count) archive commands for platforms", at: .debug)
        
        do {
            try await withThrowingTaskGroup { group in
                for (index, command) in commands.enumerated() {
                    group.addTask {
                        let delaySeconds = Double(index) * 60 * 0.3
                        
                        if delaySeconds > 0 {
                            await self.log("⏱️  Waiting \(Int(delaySeconds))s before starting \(command.platform.rawValue) build", at: .info)
                            try await Task.sleep(for: .seconds(delaySeconds))
                        }
                        
                        await self.log("""
                        🔨 Starting archive for platform: \(command.platform.rawValue)
                        🔧 DEBUG: Archive command:
                           • \(command.string)
                        """, at: .debug)
                        
                        for try await output in await runShellCommand2(command.string) {
                            await self.log("📊 Archive output: \(output)", at: .debug)
                        }

                        await self.log("✅ Archive completed for platform: \(command.platform.rawValue)", at: .info)

                        try await self.exportArchive(platform: command.platform)
                    }
                }
                
                try await group.waitForAll()
            }

            log("""
            ✅ All platforms archived successfully
            📁 ARCHIVE STAGE: Completed successfully
            """, at: .info)
        } catch {
            log("""
            ❌ ARCHIVE STAGE: Failed to archive project
               • Error: \(error.localizedDescription)
            """, at: .error)
            throw error
        }
    }
    
    func exportArchive(platform: Platform) async throws {
        var exportOptions = payload.exportOptions
        
        if platform != .iOS {
            log("🔧 DEBUG: Removing release testing option for non-iOS platform", at: .debug)
            exportOptions.removeAll { $0 == .releaseTesting }
        }
        
        log("""
        📤 EXPORT STAGE: Starting archive export for platform \(platform.rawValue)
           • Export Options: \(exportOptions.map(\.rawValue).joined(separator: ", "))
        """, at: .info)
        
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
                        await self.log("""
                        📦 Exporting to App Store for platform \(platform.rawValue)
                        🔧 DEBUG: Export command:
                           • \(exportToAppStoreCommand.string)
                        """, at: .debug)
                        
                        try await runShellCommand2(exportToAppStoreCommand.string).get()
                        
                        await self.log("✅ App Store export completed for \(platform.rawValue)", at: .info)
                    case .releaseTesting:
                        await self.log("""
                        🧪 Exporting to Release Testing for platform \(platform.rawValue)
                        🔧 DEBUG: Export command:
                           • \(exportToReleaseTestingCommand.string)
                        """, at: .debug)
                        
                        try await runShellCommand2(exportToReleaseTestingCommand.string).get()
                        
                        await self.log("✅ Release Testing export completed for \(platform.rawValue)", at: .info)
                        
                        await self.log("📤 Starting IPA upload for \(platform.rawValue)", at: .info)
                        
                        _ = try await uploader.upload(project: project, version: version, ipaURL: exportToReleaseTestingCommand.exportURL!)
                        await self.log("✅ IPA upload completed for \(platform.rawValue)", at: .info)
                    }
                }
            }
            
            try await group.waitForAll()
        }
        
        log("""
        ✅ All exports completed for platform \(platform.rawValue)
        📤 EXPORT STAGE: Completed successfully for platform \(platform.rawValue)
        """, at: .info)
    }

    func cleanup() async throws {
        log("""
        🧹 CLEANUP STAGE: Starting project cleanup
           • Derived Data Path: \(derivedDataURL.path())
           • Project Path: \(projectURL.path())
        """, at: .info)
        
        do {
            log("🗑️  Removing derived data directory...", at: .info)
            
            try FileManager.default.removeItem(atPath: derivedDataURL.path())
            log("✅ Derived data directory removed successfully", at: .info)
            
            // Uncomment to also remove project directory
            // log("🗑️  Removing project directory...", at: .info)
            // try FileManager.default.removeItem(atPath: projectURL.path())
            // log("✅ Project directory removed successfully", at: .info)

            log("🧹 CLEANUP STAGE: Completed successfully", at: .info)
        } catch {
            log("""
            ⚠️  CLEANUP STAGE: Failed to clean up project
               • Error: \(error.localizedDescription)
               • This may not affect the build result
            """, at: .warning)
        }
    }
}

//private extension XcodeBuildCommand {
//    func run() async throws {
//        try await runShellCommand2(command)
//    }
//}
