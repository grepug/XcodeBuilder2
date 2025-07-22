//
//  ProjectList.swift
//  XcodeBuilder2
//
//  Created by Kai Shao on 2025/7/13.
//

import SwiftUI
import Core

// MARK: - Presentation View Pattern (Pure SwiftUI)
struct ProjectList: View {
    let projectIds: [String]
    
    @Binding var selection: String?
    var onDelete: ((String) -> Void)?
    
    var body: some View {
        List(projectIds, id: \.self, selection: $selection) { projectId in
            ProjectListItemViewContainer(projectId: projectId)
                .padding(.vertical, 4)
        }
    }
}

#Preview {
    ProjectList(
        projectIds: ["com.example.app1", "com.example.app2"],
        selection: .constant(nil),
        onDelete: nil
    )
}
