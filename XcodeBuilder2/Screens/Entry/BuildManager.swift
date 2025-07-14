//
//  BuildManager.swift
//  XcodeBuilder2
//
//  Created by Kai Shao on 2025/7/14.
//

import Foundation
import Core

@Observable
class BuildManager {
    @ObservationIgnored
    var task: Task<Void, Never>?
    
    func createJob(payload: XcodeBuildPayload) {
        task?.cancel()
        task = Task {
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
                
                let stream = try await job.startBuild()
                
                for try await item in stream {
                    print("progress: \(item.progress) - \(item.message)")
                }
            } catch {
                print("Error running job: \(error)")
            }
        }
    }
}
