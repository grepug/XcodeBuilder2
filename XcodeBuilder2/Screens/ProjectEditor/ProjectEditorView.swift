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
    @Binding var schemes: [Scheme]
    
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
                ForEach($schemes) { $item in
                    let index = schemes.firstIndex(where: { $0.id == item.id }) ?? 0
                    
                    schemeView(for: $item, index: index) {
                        schemes.remove(at: index)
                    } moveUp: {
                        if index > 0 {
                            schemes.move(fromOffsets: IndexSet(integer: index), toOffset: index - 1)
                        }
                    }
                }
                .padding(.bottom)
                
                Button {
                    let number = schemes.count + 1
                    schemes.append(Scheme(name: "New Scheme \(number)", platforms: [.iOS]))
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
    
    func schemeView(
        for scheme: Binding<Scheme>,
        index: Int,
        onDelete: @escaping () -> Void,
        moveUp: @escaping () -> Void = {},
    ) -> some View {
        HStack(spacing: 16) {
            TextField("Scheme \(index + 1):", text: scheme.name)
            
            MultipleSelectionPicker(items: Platform.allCases, selection: scheme.platforms.toSet()) { item in
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
            
            Button {
                moveUp()
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.gray)
            }
            .buttonStyle(.plain)
            .opacity(index == 0 ? 0 : 1)
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

extension Binding {
    func toSet<T, K: Hashable>(transform: @escaping (T) -> K) -> Binding<Set<K>> where Value == [T] {
        Binding<Set<K>>(
            get: { Set(wrappedValue.map(transform)) },
            set: { newValue in
                wrappedValue = Array(newValue.map { item in
                    if let item = wrappedValue.first(where: { transform($0) == item }) {
                        return item
                    } else {
                        fatalError("Item not found in original array")
                    }
                })
            }
        )
    }
    
    func toSet<T>() -> Binding<Set<T>> where Value == [T] {
        Binding<Set<T>>(
            get: { Set(wrappedValue) },
            set: { newValue in
                wrappedValue = Array(newValue)
            }
        )
    }
}

#Preview {
    @Previewable @State var project = Project()
    @Previewable @State var schemes: [Scheme] = []
    
    ProjectEditorView(project: $project, schemes: $schemes)
}
