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
    @State private var selectedProjectId: String?
    @State private var showingNewBuildSheet = false
    
    var body: some View {
        NavigationSplitView {
            projectList
        } content: {
            content
        } detail: {
            
        }
        .onChange(of: items.map(\.id)) { oldValue, newValue in
            if let id = selectedProjectId, !newValue.contains(id) {
                selectedProjectId = nil
            }
        }
    }

    var content: some View {
        Group {
            if let selectedProjectId {
                ProjectDetailViewContainer(id: selectedProjectId)
            } else {
                Text("Select a project to view details")
                    .foregroundColor(.secondary)
                    .padding()
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigation) {
                if selectedProjectId != nil {
                    Button {
                        showingNewBuildSheet = true
                    } label: {
                        Text("New Build")
                    }
                }
            }
        }
        .sheet(isPresented: $showingNewBuildSheet) {
            if let id = selectedProjectId {
                BuildEditorContainer(projectId: id)
            }
        }
    }
    
    var projectList: some View {
        ProjectList(
            projects: items.map { $0.toProject() },
            selection: $selectedProjectId,
        ) { item in
            Task {
                try! await delete(id: item.bundleIdentifier)
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
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
        let schemeModels = project.schemes.enumerated().map { index, item in
            var item = item
            item.order = index
            return SchemeModel.fromScheme(item, projectBundleIdentifier: project.bundleIdentifier)
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
