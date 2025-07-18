//
//  XcodeBuilder2App.swift
//  XcodeBuilder2
//
//  Created by Kai Shao on 2025/7/13.
//

import SwiftUI
import Dependencies
import Core

struct CrashLogWindowGroup: Codable, Hashable {
    let id: String
}

@main
struct XcodeBuilder2App: App {
    init() {
        let path = ensuredURL(
            FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("XcodeBuilder2")
                .appendingPathComponent("db.sqlite")
        ).path()
        
        setupCacheDatabase(path: .stored(path: path))
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        
        WindowGroup(id: "crashLog", for: CrashLogWindowGroup.self) { $item in
            if let item {
                CrashLogContentViewContainer(id: item.id)
            }
        }
    }
}
