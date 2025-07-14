//
//  ProjectList.swift
//  XcodeBuilder2
//
//  Created by Kai Shao on 2025/7/13.
//

import SwiftUI
import Core

struct ProjectList: View {
    var projects: [Project]
    
    var body: some View {
        List(projects) { project in
            projectView(for: project)
                .padding(.vertical, 4)
        }
    }
    
    func projectView(for project: Project) -> some View {
        NavigationLink(destination: EmptyView()) {
            VStack(alignment: .leading) {
                Text(project.displayName)
                    .font(.headline)
                Text(project.bundleIdentifier)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}
