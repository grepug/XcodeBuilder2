//
//  ProjectDetailView.swift
//  XcodeBuilder2
//
//  Created by Kai Shao on 2025/7/18.
//

import SwiftUI
import Core
import SharingGRDB

struct ProjectDetailViewContainer: View {
    @Environment(ProjectDetailViewModel.self) private var vm
    
    var body: some View {
        ProjectDetailView(
            project: vm.project ?? .init(),
            schemes: vm.schemes,
            buildIds: vm.buildIds
        )
    }
}

struct ProjectDetailView: View {
    var project: Project
    var schemes: [Scheme] = []
    var buildIds: [UUID] = []
    
    var body: some View {
        
    }
}
