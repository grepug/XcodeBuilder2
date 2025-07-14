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
    var onDelete: ((Project) -> Void)!
    
    var body: some View {
        List(projects) { project in
            projectView(for: project)
                .contextMenu {
                    Button(role: .destructive, action: {
                        onDelete(project)
                    }) {
                        Text("Delete")
                    }
                }
                .padding(.vertical, 4)
        }
    }
    
    func projectView(for project: Project) -> some View {
        NavigationLink(destination: EmptyView()) {
            ProjectListItemView(project: project)
        }
    }
}

#Preview {
    ProjectList(projects: [
        .init(displayName: "Context", gitRepoURL: URL(string: "https://github.com/grepug/ContextBackendModelsTest.git")!),
        .init(displayName: "Life Sticker"),
        .init(displayName: "Vis"),
    ])
}
