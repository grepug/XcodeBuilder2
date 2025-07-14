//
//  XcodeBuilder2App.swift
//  XcodeBuilder2
//
//  Created by Kai Shao on 2025/7/13.
//

import SwiftUI

@main
struct XcodeBuilder2App: App {
    init() {
        let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("XcodeBuilder2")
            .appendingPathComponent("db.sqlite")
            .path()
        
        setupCacheDatabase(path: .stored(path: path))
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
