//
//  ProjectEditorView.swift
//  XcodeBuilder2
//
//  Created by Kai Shao on 2025/7/14.
//

import SwiftUI
import Core

struct ProjectEditorView: View {
    @Binding var project: Project
    var dismiss: (() -> Void)!
    var save: (() -> Void)!
    
    var body: some View {
        Form {
            Section {
                TextField("Project Name:", text: $project.name)
                
                TextField("Project Display Name:", text: $project.displayName)
                    
                TextField("Bundle Identifier:", text: $project.bundleIdentifier)
                    .autocorrectionDisabled(true)
                
                TextField("Xcode Project Name:", text: $project.xcodeprojName)
                    .autocorrectionDisabled(true)
                
                TextField("Git Remote URL:", text: $project.gitRepoURL.string)
                    .autocorrectionDisabled(true)
            } header: {
                Text("Project Details")
                    .font(.headline)
            }
            
            Divider()
                .padding(.vertical)
            
            Section {
                ForEach($project.schemes) { $item in
                    let index = project.schemes.firstIndex(where: { $0.id == item.id }) ?? 0
                    schemeView(for: $item, index: index) {
                        project.schemes.remove(at: index)
                    }
                }
                .padding(.bottom)
                
                Button {
                    let number = project.schemes.count + 1
                    project.schemes.append(Scheme(name: "New Scheme \(number)", platforms: [.iOS]))
                } label: {
                    Image(systemName: "plus")
                }
            } header: {
                Text("Schemes")
                    .font(.headline)
            }
            
            Section {
                HStack {
                    Button("Save") {
                        save!()
                    }
                    .buttonStyle(.borderedProminent)
                        
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .padding(.top)
        }
        .padding()
    }
    
    func schemeView(for scheme: Binding<Scheme>, index: Int, onDelete: @escaping () -> Void) -> some View {
        HStack(spacing: 16) {
            TextField("Scheme \(index + 1):", text: scheme.name)
            
            let selectionBinding = Binding<Set<Platform>> {
                Set(scheme.wrappedValue.platforms)
            } set: { items in
                scheme.wrappedValue.platforms = Array(items)
            }
            
            MultipleSelectionPicker(items: Platform.allCases, selection: selectionBinding) { item in
                Text(item.rawValue)
            }
            
            Button {
                onDelete()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.gray)
            }
            .buttonStyle(.plain)
        }
    }
}

struct MultipleSelectionPicker<Item: Hashable>: View {
    var items: [Item]
    @Binding var selection: Set<Item>
    var label: (Item) -> Text
    
    var body: some View {
        HStack {
            ForEach(items, id: \.self) { item in
                Toggle(isOn: .init(get: {
                    selection.contains(item)
                }, set: { newValue in
                    if newValue {
                        selection.insert(item)
                    } else {
                        selection.remove(item)
                    }
                })) {
                    label(item)
                }
            }
        }
    }
}

extension Binding where Value == URL {
    var string: Binding<String> {
        Binding<String>(
            get: { wrappedValue.absoluteString },
            set: { newValue in
                if let url = URL(string: newValue) {
                    self.wrappedValue = url
                } else {
                    // Handle invalid URL case if needed
                }
            }
        )
    }
}

#Preview {
    @Previewable @State var project = Project(
        schemes: [
            .init(name: "Beta", platforms: [
                .iOS
            ])
        ]
    )
    
    ProjectEditorView(project: $project)
}
