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
    var projectSelection: ProjectListItem?
    var buildSelection: UUID?
}

struct EntryView: View {
    @Fetch(AllProjectRequest()) var data = .init()
    
    var projects: [Project] {
        data.projects
    }
    
    var projectListOutlineItems: [ProjectListOutlineItem] {
        projects.map { project in
            ProjectListOutlineItem(
                item: .project(project),
                children: data.versionStrings[project.bundleIdentifier]?.map {
                    ProjectListOutlineItem(item: .versionString($0, project: project))
                }
            )
        }
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
    @State private var columnVisibility: NavigationSplitViewVisibility = .automatic
    
    var body: some View {
        NavigationSplitView(
            columnVisibility: $columnVisibility,
        ) {
            projectList
        } content: {
            content
                .navigationSplitViewColumnWidth(min: 400, ideal: 500)
        } detail: {
            if let id = vm.buildSelection {
                BuildDetailViewContainer(buildId: id)
                    .navigationSplitViewColumnWidth(min: 400, ideal: 500)
            } else {
                Spacer()
                    .navigationSplitViewColumnWidth(0)
            }
        }
        .navigationSplitViewStyle(.balanced)
        .environment(buildManager)
        .environment(vm)
        .onChange(of: projects.map(\.id)) { oldValue, newValue in
            if let selection = vm.projectSelection, !newValue.contains(selection.project.id) {
                vm.projectSelection = nil
            }
        }
        .onChange(of: projects, initial: true) { oldValue, newValue in
            if vm.projectSelection == nil, let first = newValue.first {
                vm.projectSelection = .project(first)
            }
        }
        .onChange(of: vm.projectSelection) { oldValue, newValue in
            if let newValue {
                if case .project = newValue {
                    vm.buildSelection = nil
                }
            }
        }
        .onDrop(of: [.fileURL], isTargeted: nil) { providers in
            guard let provider = providers.first else {
                return false
            }
            
            _ = provider.loadObject(ofClass: URL.self) { url, error in
                guard let url = url, error == nil else { return }
                
                if url.pathExtension.lowercased() == "ips" {
                    // Process the .ips file
                    print("IPS file dropped: \(url.path)")
                    // Here you can add your code to handle the .ips file
                    // For example, reading the file contents
                    do {
                        let data = try Data(contentsOf: url)
                        let string = String(data: data, encoding: .utf8) ?? "Failed to read data"
                        handleDroppedCrashLogContent(content: string)
                    } catch {
                        print("Error reading IPS file: \(error)")
                    }
                } else {
                    print("Unsupported file type: \(url.pathExtension)")
                }
            }
            
            return true
        }
    }
    
    func handleDroppedCrashLogContent(content: String) {
        Task {
            do {
                @Dependency(\.defaultDatabase) var db
                
                let log = try await MacSymbolicator.makeCrashLog(content: content) { log, projectId, version in
                    return try! await db.read { db in
                        let schemeIds = try Scheme
                            .where { $0.projectBundleIdentifier == projectId }
                            .select(\.id)
                            .fetchAll(db)
                        
                        let id = try BuildModel
                            .where { $0.schemeId.in(schemeIds) }
                            .where { $0.versionString == version.version }
                            .where { $0.buildNumber == version.buildNumber }
                            .select(\.id)
                            .fetchOne(db)!
                        
                        return id
                    }
                }
                
                do {
                    try await db.write {
                        try CrashLog
                            .insert { log }
                            .execute($0)
                    }
                } catch {
                    if error.localizedDescription.contains("UNIQUE constraint failed") {
                        // Ignore if the crash log already exists
                        print("Crash log already exists, ignoring.")
                    } else {
                        assertionFailure("Failed to save crash log: \(error)")
                    }
                }
            } catch {
                print("Failed to handle dropped crash log content: \(error)")
                assertionFailure()
            }
        }
    }

    var content: some View {
        Group {
            switch vm.projectSelection {
            case .project(let project):
                ProjectDetailViewContainer()
                    .modifier(ProjectDetailViewModifier(projectId: project.id))
            case .versionString(let version, let project):
                EmptyView()
            case nil:
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
                    .keyboardShortcut("b", modifiers: .command)
                }
            }
        }
        .sheet(isPresented: $showingNewBuildSheet) {
            if let id = vm.projectSelection?.project.id {
                BuildEditorContainer(projectId: id) {
                    showingNewBuildSheet = false
                }
            }
        }
    }
    
    var projectList: some View {
        ProjectList(
            items: projectListOutlineItems,
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
