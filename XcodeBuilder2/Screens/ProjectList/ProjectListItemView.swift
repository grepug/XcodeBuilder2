//
//  ProjectListItemView.swift
//  XcodeBuilder2
//
//  Created by Kai Shao on 2025/7/14.
//

import SwiftUI
import Core

/// Presentation View Pattern - accepts backend value types as parameters
struct ProjectListItemView: View {
    let project: ProjectValue?
    let schemeIds: [UUID]
    let recentBuilds: [BuildModelValue]
    
    var body: some View {
        HStack {
            Image(systemName: "app.dashed")
                .foregroundStyle(.secondary)
                .imageScale(.large)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(project?.displayName ?? "Loading...")
                    .font(.headline)
                
                HStack {
                    Text("\(schemeIds.count) schemes")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if !recentBuilds.isEmpty {
                        Text("•")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("\(recentBuilds.count) recent builds")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
        }
    }
}

#Preview {
    ProjectListItemView(
        project: ProjectValue(
            bundleIdentifier: "com.example.app",
            name: "ExampleApp", 
            displayName: "Example Application",
            gitRepoURL: URL(string: "https://github.com/example/app")!,
            xcodeprojName: "ExampleApp.xcodeproj",
            workingDirectoryURL: URL(fileURLWithPath: "/tmp/example")
        ),
        schemeIds: [UUID(), UUID()],
        recentBuilds: []
    )
}
