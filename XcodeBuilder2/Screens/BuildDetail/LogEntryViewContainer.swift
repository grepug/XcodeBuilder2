//
//  LogEntryViewContainer.swift
//  XcodeBuilder2
//
//  Created by Kai Shao on 2025/7/15.
//

import SwiftUI
import Core
import SharingGRDB

struct LogEntryViewContainer: View {
    var id: UUID
    
    @State @FetchOne var fetchedLog: BuildLog?
    
    var body: some View {
        LazyVStack {
            LogEntryView(log: fetchedLog ?? .init(buildId: id, content: ""))
                .task(id: id) {
                    try! await $fetchedLog.wrappedValue.load(BuildLog.where { $0.id == id })
                }
        }
    }
}
