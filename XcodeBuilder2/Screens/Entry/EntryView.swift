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

@Observable
class EntryViewModel {
    var projectSelection: String?
    var buildSelection: UUID?
}

struct EntryView: View {
    @Fetch(AllProjectRequest()) var data = .init()
    
    var items: [Project] {
        data.projects
    }
    
    @Dependency(\.defaultDatabase) var db
    
    struct EditingProjectItem: Identifiable {
        var project = Project()
        var schemes: [Scheme] = []
        
        var id: String {
            project.id
        }
    }
    
    @State var editingProjectItem: EditingProjectItem?
    @State private var showingNewBuildSheet = false
    @State var buildManager = BuildManager()
    @State var vm = EntryViewModel()
    
    var body: some View {
        NavigationSplitView {
            projectList
        } content: {
            content
        } detail: {
            
        }
        .environment(buildManager)
        .environment(vm)
        .onChange(of: items.map(\.id)) { oldValue, newValue in
            if let id = vm.projectSelection, !newValue.contains(id) {
                vm.projectSelection = nil
            }
        }
    }

    var content: some View {
        Group {
            if let id = vm.projectSelection {
                ProjectDetailViewContainer(id: id)
            } else {
                Text("Select a project to view details")
                    .foregroundColor(.secondary)
                    .padding()
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigation) {
                if vm.projectSelection != nil {
                    Button {
                        showingNewBuildSheet = true
                    } label: {
                        Text("New Build")
                    }
                }
            }
        }
        .sheet(isPresented: $showingNewBuildSheet) {
            if let id = vm.projectSelection {
                BuildEditorContainer(projectId: id) {
                    showingNewBuildSheet = false
                }
            }
        }
    }
    
    var projectList: some View {
        ProjectList(
            projects: items,
            selection: $vm.projectSelection,
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
        .sheet(item: $editingProjectItem) { item in
            ProjectEditorView(project: .init {
                item.project
            } set: { project in
                editingProjectItem!.project = project
            }, schemes: .init(get: {
                item.schemes
            }, set: { schemes in
                editingProjectItem!.schemes = schemes
            }), dismiss: { editingProjectItem = nil }) {
                if let item = editingProjectItem {
                    editingProjectItem = nil
                    
                    Task {
                        try! await saveProject(item.project, schemes: item.schemes)
                    }
                }
            }
            .frame(width: 700)
            .presentationSizing(.fitted)
        }
    }
    
    func delete(id: String) async throws {
        try await db.write { db in
            try Project
                .where { $0.bundleIdentifier == id }
                .delete()
                .execute(db)
        }
    }
    
    func saveProject(_ project: Project, schemes: [Scheme]) async throws {
        try await db.write { db in
            let schemes = schemes.map {
                var scheme = $0
                scheme.projectBundleIdentifier = project.bundleIdentifier
                return scheme
            }
            
            try Project.insert { project }.execute(db)
            try Scheme.insert { schemes }.execute(db)
        }
    }
}

#Preview {
    let _ = setupCacheDatabase()
    
    EntryView()
}
