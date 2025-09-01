//
//  DropZoneView.swift
//  SnippetConverter
//
//  Created by Bartosz Kunat on 14/08/2025.
//

import SwiftUI
import UniformTypeIdentifiers

struct DropZoneView: View {
    @ObservedObject var viewModel: ViewModel
    @State private var isTargeted = false
    
    var body: some View {
        VStack(spacing: 16) {
            if viewModel.selectedPaths.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "folder.badge.plus")
                        .font(.system(size: 40))
                        .foregroundStyle(isTargeted ? Color.accentColor : Color.secondary)
                    
                    VStack(spacing: 4) {
                        Text("Drop One or More Snippet Collections")
                            .font(.headline)
                            .foregroundStyle(isTargeted ? Color.accentColor : Color.primary)
                        Text("Folders or .alfredsnippets files")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text("Or click to browse")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 120)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isTargeted ? Color.accentColor.opacity(0.1) : Color(NSColor.controlColor))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(
                                    isTargeted ? Color.accentColor : Color.secondary.opacity(0.3),
                                    style: StrokeStyle(lineWidth: 2, dash: [8, 4])
                                )
                        )
                )
                .contentShape(Rectangle())
                .onTapGesture {
                    viewModel.openFilePicker()
                }
                .onDrop(of: [UTType.fileURL], isTargeted: $isTargeted) { providers in
                    handleDrop(providers: providers)
                }
            } else {
                VStack(spacing: 8) {
                    // Header with collection count and controls
                    HStack {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                                .font(.title3)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Selected Collections:")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text("\(viewModel.selectedPaths.count) collection\(viewModel.selectedPaths.count == 1 ? "" : "s")")
                                    .font(.body)
                                    .fontWeight(.medium)
                            }
                        }
                        
                        Spacer()
                        
                        Button("Add More", systemImage: "plus") {
                            viewModel.openFilePicker()
                        }
                        .buttonStyle(.borderless)
                        
                        Button("Clear All", systemImage: "xmark.circle") {
                            viewModel.clearSelection()
                        }
                        .buttonStyle(.borderless)
                        .foregroundStyle(.secondary)
                    }
                    
                    // List of selected collections
                    let collectionCount = viewModel.selectedPaths.count
                    let shouldScroll = collectionCount > 3
                    let maxHeight: CGFloat = shouldScroll ? 200 : CGFloat.infinity
                    
                    Group {
                        if shouldScroll {
                            VStack(spacing: 4) {
                                if collectionCount > 3 {
                                    HStack {
                                        Text("Showing \(collectionCount) collections")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                        Spacer()
                                        Text("Scroll for more ↓")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                
                                ScrollView(.vertical, showsIndicators: true) {
                                    LazyVStack(spacing: 4) {
                                        ForEach(viewModel.selectedPaths) { collection in
                                            CollectionRowView(collection: collection) {
                                                viewModel.removeCollection(collection)
                                            }
                                        }
                                    }
                                    .padding(4)
                                }
                                .frame(maxHeight: maxHeight)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.secondary.opacity(0.05))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                                        )
                                )
                            }
                        } else {
                            LazyVStack(spacing: 4) {
                                ForEach(viewModel.selectedPaths) { collection in
                                    CollectionRowView(collection: collection) {
                                        viewModel.removeCollection(collection)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.green.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.green.opacity(0.3), lineWidth: 1)
                        )
                )
            }
        }
        .padding()
        .animation(.easeInOut(duration: 0.2), value: isTargeted)
        .animation(.easeInOut(duration: 0.2), value: viewModel.selectedPaths)
    }
    
    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        let group = DispatchGroup()
        
        for provider in providers {
            group.enter()
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, error in
                defer { group.leave() }
                
                guard let data = item as? Data,
                      let url = URL(dataRepresentation: data, relativeTo: nil) else {
                    return
                }
                
                DispatchQueue.main.async {
                    viewModel.addDroppedPath(url.path)
                }
            }
        }
        
        return true
    }
}

struct CollectionRowView: View {
    let collection: SelectedCollection
    let onRemove: () -> Void
    
    var body: some View {
        HStack {
            // Collection type icon
            Image(systemName: collection.type == .directory ? "folder" : "doc.zipper")
                .foregroundStyle(.blue)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(collection.displayName)
                    .font(.body)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    Text(collection.type == .directory ? "Directory" : "Archive")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    if let count = collection.snippetCount {
                        Text("•")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("\(count) snippet\(count == 1 ? "" : "s")")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Spacer()
            
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.borderless)
        }
        .frame(height: 40)
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.secondary.opacity(0.1))
        )
    }
}
