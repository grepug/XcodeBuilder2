//
//  LogEntryViewContainer.swift
//  XcodeBuilder2
//
//  Created by Kai Shao on 2025/7/15.
//

import SwiftUI
import Core
import Sharing

struct LogEntryViewContainer: View {
    var id: UUID
    
    @SharedReader var log: BuildLogValue?
    
    init(id: UUID) {
        self.id = id
        _log = .init(wrappedValue: nil, .buildLog(id: id))
    }
    
    var body: some View {
        LazyVStack {
            LogEntryView(log: log ?? .init(buildId: id, content: ""))
                .task(id: id) {
                    try? await $log.load(.buildLog(id: id))
                }
        }
    }
}
