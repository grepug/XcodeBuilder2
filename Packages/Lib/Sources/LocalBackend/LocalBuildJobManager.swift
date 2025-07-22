import Foundation
import Core
import Dependencies
import SharingGRDB

public enum LocalBuildJobManagerError: LocalizedError {
    case buildJobIsRunning
    case buildJobNotFound
    
    public var errorDescription: String? {
        switch self {
        case .buildJobIsRunning:
            return "Build job is currently running."
        case .buildJobNotFound:
            return "Build job not found."
        }
    }
}

/// Local build job manager actor - integrates XcodeBuildJob with LocalBackendService
/// This is the LOCAL-SPECIFIC implementation that uses CLI tools
/// Follows the pattern of BuildManager but as an actor for thread safety
public actor LocalBuildJobManager {
    private var runningTasks: [UUID: Task<Void, Never>] = [:]
    private var jobPayloads: [UUID: XcodeBuildPayload] = [:]
    private var jobStatuses: [UUID: BuildJobStatus] = [:]
    
    @Dependency(\.defaultDatabase) private var db
    
    public init() {}
    
    /// Create a build job using XcodeBuildJob - LOCAL ONLY  
    public func createBuildJob(payload: XcodeBuildPayload) async throws {
        let buildId = payload.buildId
        
        guard runningTasks[buildId] == nil else {
            throw LocalBuildJobManagerError.buildJobIsRunning
        }
        
        // Store the payload and job status
        jobPayloads[buildId] = payload
        jobStatuses[buildId] = .idle
        
        // Create the build record in database (similar to createBuildIfNeeded in BuildManager)
        await createBuildIfNeeded(buildModel: payload.build)
    }
    
    /// Start a build job and return progress stream - LOCAL CLI EXECUTION
    public func startBuildJob(buildId: UUID) -> AsyncThrowingStream<BuildProgressUpdate, Error> {
        return AsyncThrowingStream<BuildProgressUpdate, Error> { continuation in
            let task = Task { [weak self] in
                do {
                    // Update status to running
                    await self?.updateJobStatus(buildId, status: .running(progress: 0.0))
                    
                    // Get the stored payload
                    guard let payload = await self?.getJobPayload(buildId) else {
                        throw LocalBuildJobManagerError.buildJobNotFound
                    }
                    
                    // Create XcodeBuildJob directly with the stored payload
                    let job = XcodeBuildJob(payload: payload) { log in
                        print("\(log.level): \(log.content)")
                        // TODO: Store logs in database using a different approach
                    }
                    
                    // Update build start time and status
                    await self?.updateBuildInDatabase(id: buildId) {
                        $0.startDate = .now
                        $0.status = .running
                    }
                    
                    continuation.yield(BuildProgressUpdate(
                        buildId: buildId,
                        progress: 0.0,
                        message: "Starting build job..."
                    ))
                    
                    // Start the build and stream progress
                    let stream = await job.startBuild()
                    
                    for try await item in stream {
                        print("progress: \(item.progress) - \(item.message)")
                        
                        await self?.updateBuildInDatabase(id: buildId) {
                            $0.progress = item.progress
                        }
                        
                        continuation.yield(BuildProgressUpdate(
                            buildId: buildId,
                            progress: item.progress,
                            message: item.message
                        ))
                    }
                    
                    try Task.checkCancellation()
                    
                    // Update status to completed
                    await self?.updateJobStatus(buildId, status: .completed)
                    await self?.updateBuildInDatabase(id: buildId) {
                        $0.endDate = .now
                        $0.status = .completed
                    }
                    
                    continuation.finish()
                } catch is CancellationError {
                    // Task was cancelled
                    await self?.updateJobStatus(buildId, status: .cancelled)
                    await self?.updateBuildInDatabase(id: buildId) {
                        $0.endDate = .now
                        $0.status = .cancelled
                    }
                    continuation.finish()
                } catch {
                    print("Error running job: \(error)")
                    
                    await self?.updateJobStatus(buildId, status: .failed(error))
                    await self?.updateBuildInDatabase(id: buildId) {
                        $0.endDate = .now
                        $0.status = .failed
                    }
                    continuation.finish(throwing: error)
                }
            }
            
            setRunningTask(buildId, task: task)
        }
    }
    
    /// Cancel a running build job - LOCAL CLI CANCELLATION
    public func cancelBuildJob(buildId: UUID) async {
        guard let task = runningTasks[buildId] else {
            return
        }
        
        task.cancel()
        runningTasks.removeValue(forKey: buildId)
        jobStatuses[buildId] = .cancelled
    }
    
    /// Delete a build job - LOCAL CLEANUP
    public func deleteBuildJob(buildId: UUID) async throws {
        // Cancel if running
        await cancelBuildJob(buildId: buildId)
        
        // Remove from internal state
        jobStatuses.removeValue(forKey: buildId)
        
        // TODO: Clean up any local build artifacts, similar to BuildManager.deleteBuild
    }
    
    /// Get build job status
    public func getBuildJobStatus(buildId: UUID) -> BuildJobStatus? {
        return jobStatuses[buildId]
    }
    
        // MARK: - Build Job Management
    
    /// Get stored payload for a build job
    private func getJobPayload(_ buildId: UUID) -> XcodeBuildPayload? {
        return jobPayloads[buildId]
    }
    
    private func createBuildIfNeeded(buildModel: BuildModelValue) async {
        // Check if build already exists
        do {
            let existingBuild = try await db.read { db in
                try BuildModel.where { $0.id == buildModel.id }.fetchOne(db)
            }
            
            guard existingBuild == nil else {
                // Build already exists
                return
            }
            
            // Create a new build
            try await db.write { db in
                let version = Version(
                    version: buildModel.versionString,
                    buildNumber: buildModel.buildNumber,
                    commitHash: buildModel.commitHash
                )
                
                let dbBuild = BuildModel(
                    id: buildModel.id,
                    schemeId: buildModel.schemeId,
                    version: version,
                    createdAt: buildModel.createdAt,
                    startDate: buildModel.startDate,
                    endDate: buildModel.endDate,
                    exportOptions: buildModel.exportOptions,
                    commitHash: buildModel.commitHash,
                    status: BuildStatus(rawValue: buildModel.status.rawValue) ?? .queued,
                    progress: buildModel.progress,
                    deviceMetadata: buildModel.deviceMetadata,
                )
                try BuildModel.insert { dbBuild }.execute(db)
            }
        } catch {
            print("Failed to create build:", error)
        }
    }
    
    private func updateJobStatus(_ buildId: UUID, status: BuildJobStatus) {
        jobStatuses[buildId] = status
    }
    
    private func setRunningTask(_ buildId: UUID, task: Task<Void, Never>) {
        runningTasks[buildId] = task
    }
    
    private func isTaskRunning(_ buildId: UUID) -> Bool {
        return runningTasks[buildId] != nil
    }
    
    private func updateBuildInDatabase(id: UUID, update: @Sendable @escaping (inout Updates<BuildModel>) -> Void) async {
        do {
            try await db.write { db in
                try BuildModel
                    .where { $0.id == id }
                    .update { update(&$0) }
                    .execute(db)
            }
        } catch {
            print("Failed to update build:", error)
        }
    }
    
    private func writeLog(buildId: UUID, coreLog: any Core.BuildLogProtocol) async {
        do {
            try await db.write { db in
                // Convert Core.BuildLog to LocalBackend.BuildLog
                let level = BuildLog.Level(rawValue: coreLog.level.rawValue) ?? .info
                let dbLog = BuildLog(
                    id: coreLog.id,
                    buildId: buildId,
                    category: coreLog.category,
                    content: coreLog.content,
                    level: level
                )
                try BuildLog
                    .insert { dbLog }
                    .execute(db)
            }
        } catch {
            print("Failed to write log:", error)
        }
    }
}
