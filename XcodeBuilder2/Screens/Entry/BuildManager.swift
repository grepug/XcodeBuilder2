//
//  BuildManager.swift
//  XcodeBuilder2
//
//  Created by Kai Shao on 2025/7/14.
//

import Foundation
import Core
import SharingGRDB

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
    
    func createJob(payload: XcodeBuildPayload, buildModel: BuildModel) async {
        await createBuildIfNeeded(buildModel: buildModel)
        
        let buildId = buildModel.id
        
        // Cancel any existing task for this buildId
        if let existingTask = tasks[buildId] {
            @FetchOne(BuildModel.where { $0.id == buildId })
            var buildModel: BuildModel!
            
            // ⚠️ FIXME: make a error property for BuildModel
            if buildModel.endDate == nil {
                existingTask.cancel()
            }
        }
        
        let task = Task {
            do {
                let job = XcodeBuildJob(
                    payload: payload,
                    logger: .init(info: {
                        print("Info: \($0)")
                    }, warning: {
                        print("Warning: \($0)")
                    }, error: {
                        print("Error: \($0)")
                    })
                )
                
                await updateBuild(id: buildId) {
                    $0.startDate = .now
                    $0.status = .running
                }
                
                let stream = await job.startBuild()
                
                for try await item in stream {
                    print("progress: \(item.progress) - \(item.message)")
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
    
    func deleteBuild(_ build: BuildModel) async {
        try! await db.write { db in
            try BuildModel
                .delete(build)
                .execute(db)
        }
    }
}
