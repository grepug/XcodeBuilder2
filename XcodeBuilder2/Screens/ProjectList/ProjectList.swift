//
//  ProjectList.swift
//  XcodeBuilder2
//
//  Created by Kai Shao on 2025/7/13.
//

import SwiftUI
import Core

enum ProjectListItem: Identifiable, Hashable {
    case project(Project)
    case versionString(String, project: Project)
    
    var id: Self {
        self
    }
    
    var project: Project {
        switch self {
        case .project(let project): project
        case .versionString(_, let project): project
        }
    }
}

struct ProjectListOutlineItem: Identifiable, Hashable {
    let item: ProjectListItem
    var children: [ProjectListOutlineItem]?
    
    var id: ProjectListItem {
        item
    }
}

struct ProjectList: View {
    var items: [ProjectListOutlineItem]
    
    @Binding var selection: ProjectListItem?
    
    var onDelete: ((Project) -> Void)!
    
    var body: some View {
        List(items, children: \.children, selection: $selection) { item in
            switch item.item {
            case .project(let project):
                ProjectListItemView(project: project)
                    .padding(.vertical, 4)
            case .versionString(let version, _):
                Text("v\(version)")
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview {
    let project = Project(displayName: "Test Project")
    
    ProjectList(items: [
        .init(item: .project(project), children: [
            .init(item: .versionString("v1.0.0", project: project)),
            .init(item: .versionString("v1.1.0", project: project)),
            .init(item: .versionString("v2.0.0", project: project)),
        ]),
    ], selection: .constant(nil))
}
