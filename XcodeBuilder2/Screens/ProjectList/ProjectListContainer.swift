//
//  ProjectList.swift
//  XcodeBuilder2
//
//  Created by Kai Shao on 2025/7/13.
//

import SwiftUI
import Core
import Sharing

// MARK: - Presentation View Pattern (Pure SwiftUI)
struct ProjectListContainer: View {
    @SharedReader(.allProjectIds) var projectIds: [String]
    
    @Environment(EntryViewModel.self) var vm
    
    var body: some View {
        @Bindable var vm = vm
        
        List(projectIds, id: \.self, selection: $vm.projectSelection) { projectId in
            ProjectListItemViewContainer(projectId: projectId)
                .padding(.vertical, 4)
        }
        .onChange(of: projectIds) { oldValue, newValue in
            if let selection = vm.projectSelection, !newValue.contains(selection) {
                vm.projectSelection = nil
            }
        }
        .onChange(of: projectIds, initial: true) { oldValue, newValue in
            if vm.projectSelection == nil, let first = newValue.first {
                vm.projectSelection = first
            }
        }
        .onChange(of: vm.projectSelection) { oldValue, newValue in
            if newValue != nil {
                vm.buildSelection = nil
            }
        }
    }
}
