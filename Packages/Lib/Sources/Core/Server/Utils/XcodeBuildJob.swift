import Foundation
import Dependencies

// MARK: - Supporting Types

// MARK: DateFormatter Extension
private extension DateFormatter {
    static let logFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }()
}

// XcodeBuildPayload is now in Core/Shared/Models/BuildPayload.swift
// XcodeBuildProgress is now in Core/Shared/Models/BuildPayload.swift

// MARK: Log Categories
public enum XcodeBuildJobLogCategory: String, Sendable, CaseIterable {
    case clone = "Clone Repository"
    case resolveDependencies = "Resolve Dependencies"
    case archive = "Archive Project"
    case export = "Export"
    case cleanup = "Cleanup"
}

// MARK: Progress Tracking Helper
private struct ProgressTracker {
    let totalSteps: Int
    let baseProgress: Double
    let maxProgress: Double
    
    func progress(for step: Int) -> Double {
        let stepProgress = Double(step) / Double(totalSteps)
        return baseProgress + (stepProgress * (maxProgress - baseProgress))
    }
}

// MARK: - Main XcodeBuildJob Actor

public actor XcodeBuildJob: Sendable {
    let payload: XcodeBuildPayload
    let log: (BuildLogValue) -> Void
    
    public typealias Stream = AsyncThrowingStream<XcodeBuildProgress, Error>
    
    @Dependency(\.xcodeBuildPathManager) var pathManager
    @Dependency(\.ipaUploader) var ipaUploader

    public init(payload: XcodeBuildPayload, log: @escaping (BuildLogValue) -> Void) {
        self.payload = payload
        self.log = log
    }
    
    public func startBuild() -> Stream {
        // Implementation for starting the build process
        // This would typically involve invoking xcodebuild with the appropriate parameters
        
        let (stream, continuation) = Stream.makeStream()
        
        let task = Task {
            do {
                try await self.build {
                    continuation.yield($0)
                }
                
                try Task.checkCancellation()
                
                continuation.finish()
            } catch {
                if error is CancellationError {
                    log("🚫 BUILD CANCELLED", .cleanup, level: .warning)
                } else {
                    log("""
                ❌ BUILD FAILED
                   • Error: \(error.localizedDescription)
                   • Error Type: \(type(of: error))
                """, .cleanup, level: .error)
                }

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
    
    func build(yield: @escaping (XcodeBuildProgress) -> Void) async throws {
        log("""
        🚀 BUILD STARTED
        📋 Build Configuration:
           • Project: \(payload.project.name)
           • Scheme: \(payload.scheme.name)
           • Version: \(payload.version.displayString)
           • Platforms: \(payload.scheme.platforms.map(\.rawValue).joined(separator: ", "))
           • Export Options: \(payload.exportOptions.map(\.rawValue).joined(separator: ", "))
        """, .clone, level: .info)
        
        yield(.init(progress: 0.05, message: "🚀 Build started - Initializing..."))
        
        try await cloneRepository()
        try Task.checkCancellation()
        yield(.init(progress: 0.20, message: "📦 Repository cloned successfully"))
        
        try await resolvePackageDependencies()
        try Task.checkCancellation()
        yield(.init(progress: 0.35, message: "🔗 Package dependencies resolved"))
        
        yield(.init(progress: 0.40, message: "🔨 Starting archive process..."))
        try await archiveProject()
        try Task.checkCancellation()
        yield(.init(progress: 0.90, message: "📁 Project archived successfully"))

        try await cleanup()
        try Task.checkCancellation()
        yield(.init(progress: 0.95, message: "🧹 Cleanup completed"))
        
        log("✅ BUILD COMPLETED SUCCESSFULLY", .cleanup, level: .info)
        yield(.init(progress: 1.0, message: "✅ Build completed successfully!", isFinished: true))
    }
}

// MARK: - Private Build Step Methods

private extension XcodeBuildJob {
    
    // MARK: Path Properties
    var projectURL: URL {
        ensuredURL(pathManager.projectURL(for: payload.project, build: payload.build))
    }
    
    var xcodeprojURL: URL {
        ensuredURL(pathManager.xcodeprojURL(for: payload.project, build: payload.build))
    }
    
    var archiveURL: URL {
        ensuredURL(pathManager.archiveURL(for: payload.project, build: payload.build))
    }
    
    var derivedDataURL: URL {
        ensuredURL(pathManager.derivedDataURL(for: payload.project, build: payload.build))
    }
    
    var exportURL: URL? {
        pathManager.exportURL(for: payload.project, build: payload.build)
            .map { ensuredURL($0) }
    }
    
    var scheme: SchemeValue {
        payload.scheme
    }

    // MARK: Logging
    func log(_ content: String, _ category: XcodeBuildJobLogCategory, level: BuildLogLevel = .info) {
        let timestamp = DateFormatter.logFormatter.string(from: Date())
        let formattedContent = "[\(timestamp)] \(content)"
        let logEntry = BuildLogValue(buildId: payload.buildId, category: category.rawValue, level: level, content: formattedContent)
        log(logEntry)
    }
    
    // MARK: Build Steps
    func cloneRepository() async throws {
        log("""
        📂 CLONE STAGE: Starting repository clone
           • Repository URL: \(payload.project.gitRepoURL)
           • Target Tag: \(payload.version.displayString)
           • Clone Path: \(projectURL.path())
        """, .clone, level: .info)
        
        do {
            let gitCommand = GitCommand(pathURL: projectURL)

            switch payload.gitCloneKind {
            case .tag:
                log("🔧 DEBUG: Cloning tag \(payload.version.tagName)", .clone, level: .debug)
                
                try await gitCommand.clone(
                    remoteURL: payload.project.gitRepoURL,
                    tag: payload.version.tagName,
                )
            case .branch(let branchName):
                log("🔧 DEBUG: Cloning branch \(branchName)", .clone, level: .debug)

                try await gitCommand.cloneTagAndPush(
                    version: payload.version, 
                    on: branchName, 
                    from: payload.project.gitRepoURL
                )
            }

            log("✅ Repository cloned successfully", .clone, level: .info)
            
            log("🔄 Updating project versions...", .clone, level: .info)
            
            updateVersions(
                url: projectURL,
                version: payload.version.version,
                buildNumber: "\(payload.version.buildNumber)",
            )
            
            log("""
            ✅ Project versions updated to \(payload.version.displayString)
            📂 CLONE STAGE: Completed successfully
            """, .clone, level: .info)
        } catch {
            log("""
            ❌ CLONE STAGE: Failed to clone repository
               • Error: \(error.localizedDescription)
            """, .clone, level: .error)
            
            throw error
        }
    }
    
    func resolvePackageDependencies() async throws {
        log("""
        🔗 RESOLVE DEPENDENCIES STAGE: Starting package dependency resolution
           • Project: \(payload.project.name)
           • Project Path: \(xcodeprojURL.path())
           • Scheme: \(scheme.name)
        """, .resolveDependencies, level: .info)

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
            """, .resolveDependencies, level: .debug)
            
            try await runShellCommand2(command.string).get()

            log("""
            ✅ Package dependencies resolved successfully
            🔗 RESOLVE DEPENDENCIES STAGE: Completed successfully
            """, .resolveDependencies, level: .info)
        } catch {
            log("""
            ❌ RESOLVE DEPENDENCIES STAGE: Failed to resolve package dependencies
               • Error: \(error.localizedDescription)
            """, .resolveDependencies, level: .error)
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
        """, .archive, level: .info)
        
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
        
        log("🔧 DEBUG: Generated \(commands.count) archive commands for platforms", .archive, level: .debug)
        
        do {
            try await withThrowingTaskGroup { group in
                for (index, command) in commands.enumerated() {
                    group.addTask {
                        let delaySeconds = Double(index) * 60 * 0.3
                        
                        if delaySeconds > 0 {
                            await self.log("⏱️  Waiting \(Int(delaySeconds))s before starting \(command.platform.rawValue) build", .archive, level: .info)
                            try await Task.sleep(for: .seconds(delaySeconds))
                        }
                        
                        await self.log("""
                        🔨 Starting archive for platform: \(command.platform.rawValue)
                        🔧 DEBUG: Archive command:
                           • \(command.string)
                        """, .archive, level: .debug)
                        
                        for try await output in await runShellCommand2(command.string) {
                            await self.log("📊 Archive output: \(output)", .archive, level: .debug)
                        }
                        
                        try Task.checkCancellation()

                        await self.log("✅ Archive completed for platform: \(command.platform.rawValue)", .archive, level: .info)

                        try await self.exportArchive(platform: command.platform)
                    }
                }
                
                try await group.waitForAll()
            }
            
            log("""
            ✅ All platforms archived successfully
            📁 ARCHIVE STAGE: Completed successfully
            """, .archive, level: .info)
        } catch {
            if error is CancellationError {
                log("🚫 ARCHIVE STAGE: Archive process was cancelled", .archive, level: .warning)
            } else {
                log("""
            ❌ ARCHIVE STAGE: Failed to archive project
               • Error: \(error.localizedDescription)
            """, .archive, level: .error)
            }
            
            throw error
        }
    }
    
    func exportArchive(platform: Platform) async throws {
        var exportOptions = payload.exportOptions
        
        if platform != .iOS {
            log("🔧 DEBUG: Removing release testing option for non-iOS platform", .export, level: .debug)
            exportOptions.removeAll { $0 == .releaseTesting }
        }
        
        log("""
        📤 EXPORT STAGE: Starting archive export for platform \(platform.rawValue)
           • Export Options: \(exportOptions.map(\.rawValue).joined(separator: ", "))
        """, .export, level: .info)
        
        assert(Set(exportOptions).count == exportOptions.count, "Duplicate export options found: \(exportOptions)")
        assert(exportOptions.isEmpty == false, "No export options provided for platform \(platform.rawValue)")

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
                        """, .export, level: .debug)
                        
                        try await runShellCommand2(exportToAppStoreCommand.string).get()
                        
                        await self.log("✅ App Store export completed for \(platform.rawValue)", .export, level: .info)
                    case .releaseTesting:
                        await self.log("""
                        🧪 Exporting to Release Testing for platform \(platform.rawValue)
                        🔧 DEBUG: Export command:
                           • \(exportToReleaseTestingCommand.string)
                        """, .export, level: .debug)
                        
                        try await runShellCommand2(exportToReleaseTestingCommand.string).get()
                        
                        await self.log("✅ Release Testing export completed for \(platform.rawValue)", .export, level: .info)
                        
                        await self.log("📤 Starting IPA upload for \(platform.rawValue)", .export, level: .info)
                        
                        _ = try await uploader.upload(project: project, version: version, ipaURL: exportToReleaseTestingCommand.exportURL!)
                        await self.log("✅ IPA upload completed for \(platform.rawValue)", .export, level: .info)
                    }
                }
            }
            
            try await group.waitForAll()
        }
        
        log("""
        ✅ All exports completed for platform \(platform.rawValue)
        📤 EXPORT STAGE: Completed successfully for platform \(platform.rawValue)
        """, .export, level: .info)
    }

    func cleanup() async throws {
        log("""
        🧹 CLEANUP STAGE: Starting project cleanup
           • Derived Data Path: \(derivedDataURL.path())
           • Project Path: \(projectURL.path())
        """, .cleanup, level: .info)
        
        do {
            log("🗑️  Removing derived data directory...", .cleanup)
            
            try FileManager.default.removeItem(atPath: derivedDataURL.path())
            log("✅ Derived data directory removed successfully", .cleanup)
            
            log("🗑️  Removing project directory...", .cleanup)
            try FileManager.default.removeItem(atPath: projectURL.path())
            log("✅ Project directory removed successfully", .cleanup)

            log("🧹 CLEANUP STAGE: Completed successfully", .cleanup)
        } catch {
            log("""
            ⚠️  CLEANUP STAGE: Failed to clean up project
               • Error: \(error.localizedDescription)
               • This may not affect the build result
            """, .cleanup, level: .warning)
        }
    }
}

//private extension XcodeBuildCommand {
//    func run() async throws {
//        try await runShellCommand2(command)
//    }
//}
