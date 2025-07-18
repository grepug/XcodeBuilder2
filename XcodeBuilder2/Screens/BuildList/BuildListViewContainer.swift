//
//  ProjectDetailView.swift
//  XcodeBuilder2
//
//  Created by Kai Shao on 2025/7/14.
//

import SwiftUI
import Core
import SharingGRDB

struct BuildListViewContainer: View {
    @Environment(BuildManager.self) private var buildManager
    @Environment(EntryViewModel.self) private var entryVM
    @Environment(ProjectDetailViewModel.self) private var vm
    
    var body: some View {
        @Bindable var entryVM = entryVM
        
        BuildListView(
            project: vm.project ?? .init(),
            buildIds: vm.buildIds,
            buildSelection: $entryVM.buildSelection,
        )
        .task(id: [vm.buildIds, entryVM.buildSelection] as [AnyHashable]) {
            if entryVM.buildSelection == nil {
                entryVM.buildSelection = vm.buildIds.first
            }
        }
    }
}

struct BuildListView: View {
    var project: Project
    var buildIds: [UUID]
    @Binding var buildSelection: UUID?
    
    var body: some View {
        List(buildIds, id: \.self, selection: $buildSelection) { id in
            BuildItemViewContainer(id: id)
                .tag(id)
        }
        .animation(.default, value: buildIds.count)
    }
}


