//
//  EntryView.swift
//  XcodeBuilder2
//
//  Created by Kai Shao on 2025/7/13.
//

import SwiftUI
import Core
import Sharing
import SharingGRDB

struct EntryView: View {
    @FetchAll var items: [ProjectModel]
    
    @Dependency(\.defaultDatabase) var db
    
    @State var editingProjectItem: Project?
    
    var body: some View {
        NavigationSplitView {
            ProjectList(projects: items.map { $0.toProject() }) { item in
                Task {
                    try! await delete(id: item.bundleIdentifier)
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigation) {
                    Button(action: {
                        editingProjectItem = .init()
                    }) {
                        Label("Add Project", systemImage: "plus")
                    }
                }
            }
            .sheet(item: $editingProjectItem) { project in
                ProjectEditorView(project: .init {
                    project
                } set: { project in
                    editingProjectItem = project
                }, dismiss: { editingProjectItem = nil }) {
                    if let project = editingProjectItem {
                        editingProjectItem = nil
                        
                        Task {
                            try! await saveProject(project)
                        }
                    }
                }
                .frame(width: 700)
                .presentationSizing(.fitted)
            }
        } detail: {
            
        }
    }
    
    func delete(id: String) async throws {
        try await db.write { db in
            try ProjectModel
                .where { $0.bundle_identifier == id }
                .delete()
                .execute(db)
        }
    }
    
    func saveProject(_ project: Project) async throws {
        let projectModel = ProjectModel.fromProject(project)
        let schemeModels = project.schemes.map {
            SchemeModel.fromScheme($0, projectBundleIdentifier: project.bundleIdentifier)
        }
        
        try await db.write { db in
            try ProjectModel.insert { projectModel }.execute(db)
            try SchemeModel.insert { schemeModels }.execute(db)
        }
    }
}

#Preview {
    let _ = setupCacheDatabase()
    
    EntryView()
}
