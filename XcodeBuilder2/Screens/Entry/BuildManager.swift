//
//  BuildManager.swift
//  XcodeBuilder2
//
//  Created by Kai Shao on 2025/7/14.
//

import Foundation
import Core
import SharingGRDB

enum BuildManagerError: LocalizedError {
    case buildIsRunning
    
    var errorDescription: String? {
        switch self {
        case .buildIsRunning:
            return "Build is currently running."
        }
    }
}

@Observable
class BuildManager {
    @ObservationIgnored
    var tasks: [UUID: Task<Void, Never>] = [:]
    
    @ObservationIgnored
    @Dependency(\.defaultDatabase) var db
    
    func createBuildIfNeeded(buildModel: BuildModel) async {
        @FetchOne(BuildModel.where { $0.id == buildModel.id })
        var fetchedBuildModel: BuildModel?
        
        guard fetchedBuildModel == nil else {
            // Build already exists
            return
        }
        
        // Create a new build
        try! await db.write { db in
            try BuildModel
                .insert { buildModel }
                .execute(db)
        }
    }
    
    func createJob(payload: XcodeBuildPayload, buildModel: BuildModel) async throws(BuildManagerError) {
        let buildId = buildModel.id
        
        guard tasks[buildId] == nil else {
            throw BuildManagerError.buildIsRunning
        }
        
        await createBuildIfNeeded(buildModel: buildModel)
        
        let task = Task {
            do {
                let job = XcodeBuildJob(
                    payload: payload,
                ) { [unowned self] log in
                    writeLog(log)
                    print("\(log.level): \(log.content)")
                }
                
                await updateBuild(id: buildId) {
                    $0.startDate = .now
                    $0.status = .running
                }
                
                let stream = await job.startBuild()
                
                for try await item in stream {
                    print("progress: \(item.progress) - \(item.message)")
                    
                    await updateBuild(id: buildId) {
                        $0.progress = item.progress
                    }
                }
                
                await updateBuild(id: buildId) {
                    $0.endDate = .now
                    $0.status = .completed
                }
            } catch {
                print("Error running job: \(error)")
                
                await updateBuild(id: buildId) {
                    $0.endDate = .now
                    $0.status = .failed
                }
            }
        }
        
        tasks[buildId] = task
    }
    
    func updateBuild(id: UUID, update: @escaping (inout Updates<BuildModel>) -> Void) async {
        try! await db.write { db in
            try BuildModel
                .where { $0.id == id }
                .update { update(&$0) }
                .execute(db)
        }
    }
    
    func writeLog(_ log: BuildLog)  {
        Task {
            try! await db.write { db in
                try BuildLog
                    .insert { log }
                    .execute(db)
            }
        }
    }
    
    func deleteBuild(_ build: BuildModel) async {
        try! await db.write { db in
            try BuildModel
                .delete(build)
                .execute(db)
        }
    }
    
    func cancelBuild(_ build: BuildModel) async {
        guard let task = tasks[build.id] else { return }
        
        task.cancel()
        
        await updateBuild(id: build.id) {
            $0.status = .cancelled
            $0.endDate = .now
        }
    }
}
