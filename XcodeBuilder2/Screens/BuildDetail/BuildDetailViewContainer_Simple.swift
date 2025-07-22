//
//  BuildDetailViewContainer_Simple.swift
//  XcodeBuilder2
//
//  Created by Kai Shao on 2025/7/22.
//

import SwiftUI

/// Container View Pattern for Build Detail - demonstrates Step 7 UI Integration  
/// This simplified version shows the architecture without Core module dependencies
struct BuildDetailViewContainer_Simple: View {
    let buildId: String
    
    // Mock data to demonstrate the pattern
    // In the full implementation, this would be @SharedReader:
    // @SharedReader private var build: BuildModelValue?
    @State private var build: MockBuild?
    @State private var selectedTab: Int = 0
    
    struct MockBuild {
        let id: String
        let projectName: String
        let status: String
        let duration: String
        let timestamp: String
    }
    
    init(buildId: String) {
        self.buildId = buildId
        // Initialize mock data
        self.build = MockBuild(
            id: buildId,
            projectName: "Sample Project",
            status: "Success",
            duration: "2m 34s",
            timestamp: "2025-07-22 14:30:00"
        )
    }
    
    var body: some View {
        VStack {
            if let build = build {
                // Build Header
                VStack(alignment: .leading) {
                    HStack {
                        Text(build.projectName)
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        Text(build.status)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(build.status == "Success" ? .green : .red)
                            .foregroundColor(.white)
                            .cornerRadius(4)
                    }
                    
                    Text("Build ID: \(build.id)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Text("Duration: \(build.duration)")
                        Spacer()
                        Text("Time: \(build.timestamp)")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                .padding()
                .background(.gray.opacity(0.1))
                .cornerRadius(8)
                
                // Tab Interface
                Picker("Tab", selection: $selectedTab) {
                    Text("Overview").tag(0)
                    Text("Logs").tag(1)
                    Text("Crashes").tag(2)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                // Tab Content
                TabView(selection: $selectedTab) {
                    // Overview Tab
                    VStack {
                        Text("Build Overview")
                            .font(.headline)
                        Text("Status: \(build.status)")
                        Text("Duration: \(build.duration)")
                        Spacer()
                    }
                    .tag(0)
                    
                    // Logs Tab
                    VStack {
                        Text("Build Logs")
                            .font(.headline)
                        Text("Log entries would appear here...")
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .tag(1)
                    
                    // Crashes Tab
                    VStack {
                        Text("Crash Reports")
                            .font(.headline)
                        Text("Crash logs would appear here...")
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .tag(2)
                }
                .tabViewStyle(.automatic)
                
            } else {
                ProgressView("Loading build details...")
            }
        }
        .padding()
        .navigationTitle("Build Details")
        // TODO: Add loading task when Core module is available
        // .task {
        //     try? await $build.load(.build(id: buildId))
        // }
    }
}

#Preview {
    NavigationView {
        BuildDetailViewContainer_Simple(buildId: "build-123")
    }
}
