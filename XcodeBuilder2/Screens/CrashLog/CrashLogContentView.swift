//
//  CrashLogContentView.swift
//  XcodeBuilder2
//
//  Created by Kai Shao on 2025/7/18.
//

import SwiftUI
import Core
import SharingGRDB

struct CrashLogContentViewContainer: View {
    let id: String
    
    @State @FetchOne var fetchedCrashLog: CrashLog?
    @State private var crashLog: CrashLog = .init()
    
    var body: some View {
        CrashLogContentView(crashLog: $crashLog)
            .task(id: id) {
                try! await $fetchedCrashLog.wrappedValue.load(
                    CrashLog.where { $0.incidentIdentifier == id }
                )
            }
            .task(id: crashLog) {
                let crashLog = crashLog
                
                guard crashLog != .init() else {
                    return
                }
                
                @Dependency(\.defaultDatabase) var db
                
                try! await db.write {
                    try CrashLog
                        .where { $0.incidentIdentifier == id }
                        .update {
                            $0.priority = crashLog.priority
                            $0.note = crashLog.note
                            $0.fixed = crashLog.fixed
                        }
                        .execute($0)
                }
            }
    }
}

struct CrashLogContentView: View {
    @Binding var crashLog: CrashLog
    
    var body: some View {
        ScrollView {
        }
    }
}
