//
//  ProjectListItemView.swift
//  XcodeBuilder2
//
//  Created by Kai Shao on 2025/7/14.
//

import SwiftUI
import Core

struct ProjectListItemView: View {
    var project: Project
    
    var body: some View {
        HStack {
            Image(systemName: "app.dashed")
                .foregroundStyle(.secondary)
                .imageScale(.large)
            
            Text(project.displayName)
                .font(.headline)
        }
    }
}

#Preview {
    ProjectListItemView(project: .init(
        displayName: "Life Sticker",
    ))
}
