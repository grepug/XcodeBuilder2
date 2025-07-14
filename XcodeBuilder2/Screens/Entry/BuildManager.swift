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
    var task: Task<Void, Never>?
    var tasks: [UUID: Task<Void, Never>] = [:]
    
    func createJob(payload: XcodeBuildPayload, buildId: UUID) {
        @Dependency(\.defaultDatabase) var db
        @FetchOne(BuildModel.where { $0.id == buildId})
        var buildModel: BuildModel!
        
        // Cancel any existing task for this buildId
        if let existingTask = tasks[buildId] {
            // ⚠️ FIXME: make a error property for BuildModel
            if buildModel.end_date == nil {
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
                
                try await db.write { db in
                    try BuildModel
                        .where { $0.id == buildId }
                        .update { $0.start_date = .now }
                        .execute(db)
                }
                
                let stream = await job.startBuild()
                
                for try await item in stream {
                    print("progress: \(item.progress) - \(item.message)")
                }
                
                try await db.write { db in
                    try BuildModel
                        .where { $0.id == buildId }
                        .update { $0.end_date = .now }
                        .execute(db)
                }
            } catch {
                print("Error running job: \(error)")
            }
        }
        
        tasks[buildId] = task
    }
}
