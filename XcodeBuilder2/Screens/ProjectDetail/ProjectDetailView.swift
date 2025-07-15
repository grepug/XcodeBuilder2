//
//  ProjectDetailView.swift
//  XcodeBuilder2
//
//  Created by Kai Shao on 2025/7/14.
//

import SwiftUI
import Core
import SharingGRDB

struct ProjectDetailViewContainer: View {
    var id: String
    
    @State @Fetch var fetchedValue: ProjectDetailRequest.Result?
    
    @Environment(BuildManager.self) private var buildManager
    @Environment(EntryViewModel.self) private var entryVM
    
    var item: Project {
        fetchedValue?.project ?? Project(displayName: "Loading...")
    }
    
    var builds: [BuildModel] {
        fetchedValue?.builds ?? []
    }
    
    init(id: String) {
        self.id = id
    }
    
    var body: some View {
        @Bindable var entryVM = entryVM
        
        ProjectDetailView(
            project: item,
            builds: builds,
            buildSelection: $entryVM.buildSelection,
            schemes: fetchedValue?.schemes ?? []
        ) { build in
            Task {
                await buildManager.cancelBuild(build)
            }
        } onDelete: { build in
            Task {
                await buildManager.deleteBuild(build)
            }
        }
        .task(id: id) {
            try! await $fetchedValue.wrappedValue.load(ProjectDetailRequest(id: id))
        }
    }
}

struct ProjectDetailView: View {
    var project: Project
    var builds: [BuildModel]
    @Binding var buildSelection: UUID?
    var schemes: [Scheme] = []
    
    var onCancel: ((BuildModel) -> Void)?
    var onDelete: ((BuildModel) -> Void)?
    
    @Dependency(\.defaultDatabase) var db
    
    var body: some View {
        List(builds, selection: $buildSelection) { build in
            BuildItemView(build: build, schemes: schemes)
                .contextMenu {
                    if build.status == .running {
                        Button("Cancel", action: {
                            onCancel?(build)
                        })
                    }
                    
                    Button("Delete", role: .destructive) {
                        onDelete?(build)
                    }
                }
                .tag(build.id)
        }
    }
}


