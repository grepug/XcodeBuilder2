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
    
    @State @FetchOne var project: Project?
    @State @FetchAll var buildIds: [UUID] = []
    @State @FetchAll var schemes: [Scheme] = []
    
    @Environment(BuildManager.self) private var buildManager
    @Environment(EntryViewModel.self) private var entryVM
    
    init(id: String) {
        self.id = id
    }
    
    var body: some View {
        @Bindable var entryVM = entryVM
        
        ProjectDetailView(
            project: project ?? .init(),
            buildIds: buildIds,
            buildSelection: $entryVM.buildSelection,
            schemes: schemes,
        )
        .task(id: id) {
            try! await $project.wrappedValue.load(Project.where { $0.bundleIdentifier == id }, animation: .default)
            try! await $schemes.wrappedValue.load(Scheme.where { $0.projectBundleIdentifier == id }, animation: .default)
        }
        .task(id: schemes) {
            try! await $buildIds.wrappedValue.load(
                BuildModel
                    .where { $0.schemeId.in(schemes.map(\.id)) }
                    .select(\.id),
                animation: .default,
            )
        }
    }
}

struct ProjectDetailView: View {
    var project: Project
    var buildIds: [UUID]
    @Binding var buildSelection: UUID?
    var schemes: [Scheme] = []
    
    @Dependency(\.defaultDatabase) var db
    
    var body: some View {
        List(buildIds, id: \.self, selection: $buildSelection) { id in
            BuildItemViewContainer(id: id)
                .tag(id)
        }
        .animation(.default, value: buildIds.count)
    }
}


