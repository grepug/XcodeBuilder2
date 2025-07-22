//
//  EntryView.swift
//  XcodeBuilder2
//
//  Created by Kai Shao on 2025/7/13.
//

import SwiftUI
import Core
import LocalBackend
import Sharing
import SharingGRDB

@Observable
class EntryViewModel {
    var projectSelection: String?
    var buildSelection: UUID?
}

struct EntryView: View {
    struct EditingProjectItem: Identifiable {
        var project = Project()
        var schemes: [Scheme] = []
        
        var id: String {
            project.id
        }
    }
    
    @State var editingProjectItem: EditingProjectItem?
    @State private var showingNewBuildSheet = false
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
        .environment(vm)
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
//        Task {
//            do {
//                @Dependency(\.defaultDatabase) var db
//                
//                let log = try await MacSymbolicator.makeCrashLog(content: content) { log, projectId, version in
//                    return try! await db.read { db in
//                        let schemeIds = try Scheme
//                            .where { $0.projectBundleIdentifier == projectId }
//                            .select(\.id)
//                            .fetchAll(db)
//                        
//                        let id = try BuildModel
//                            .where { $0.schemeId.in(schemeIds) }
//                            .where { $0.versionString == version.version }
//                            .where { $0.buildNumber == version.buildNumber }
//                            .select(\.id)
//                            .fetchOne(db)!
//                        
//                        return id
//                    }
//                }
//                
//                try! await db.write {
//                    try CrashLog
//                        .insert { log }
//                        .execute($0)
//                }
//            } catch {
//                print("Failed to handle dropped crash log content: \(error)")
//                assertionFailure()
//            }
//        }
    }

    var content: some View {
        Group {
            if let id = vm.projectSelection {
                ProjectDetailViewContainer(id: id)
            } else {
                Text("Select a project to view details")
                    .foregroundStyle(.secondary)
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
            if let id = vm.projectSelection {
                BuildEditorContainer(projectId: id) {
                    showingNewBuildSheet = false
                }
            }
        }
    }
    
    var projectList: some View {
        ProjectListContainer()
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
                ProjectEditorViewContainer(id: nil)
                    .frame(width: 700)
                    .presentationSizing(.fitted)
            }
    }
}

#Preview {
    let _ = setupLocalBackend()
    
    EntryView()
}
