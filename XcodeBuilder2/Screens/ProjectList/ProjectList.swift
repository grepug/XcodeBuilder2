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
    @Binding var selection: String?
    var onDelete: ((Project) -> Void)!
    
    var body: some View {
        List(projects, selection: $selection) { project in
            ProjectListItemView(project: project)
                .tag(project.id)
                .contextMenu {
                    Button(role: .destructive, action: {
                        onDelete(project)
                    }) {
                        Text("Delete")
                    }
                }
                .padding(.vertical, 4)
        }
        .onChange(of: selection) { oldValue, newValue in
            print("Selection changed from \(oldValue ?? "nil") to \(newValue ?? "nil")")
        }
    }
}

#Preview {
    ProjectList(projects: [
        .init(displayName: "Context", gitRepoURL: URL(string: "https://github.com/grepug/ContextBackendModelsTest.git")!),
        .init(displayName: "Life Sticker"),
        .init(displayName: "Vis"),
    ], selection: .constant(nil))
}
