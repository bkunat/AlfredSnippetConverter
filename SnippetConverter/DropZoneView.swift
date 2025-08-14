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
            if viewModel.selectedPath == nil {
                VStack(spacing: 12) {
                    Image(systemName: "folder.badge.plus")
                        .font(.system(size: 40))
                        .foregroundStyle(isTargeted ? Color.accentColor : Color.secondary)
                    
                    VStack(spacing: 4) {
                        Text("Drop Alfred Snippet Folder Here")
                            .font(.headline)
                            .foregroundStyle(isTargeted ? Color.accentColor : Color.primary)
                        Text("Or click to browse")
                            .font(.subheadline)
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
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.title3)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Selected Folder:")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(viewModel.selectedPath!)
                            .font(.body)
                            .lineLimit(2)
                    }
                    
                    Spacer()
                    
                    Button("Change", systemImage: "folder") {
                        viewModel.openFilePicker()
                    }
                    .buttonStyle(.borderless)
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
        .animation(.easeInOut(duration: 0.2), value: viewModel.selectedPath)
    }
    
    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        
        provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, error in
            guard let data = item as? Data,
                  let url = URL(dataRepresentation: data, relativeTo: nil) else {
                return
            }
            
            DispatchQueue.main.async {
                if viewModel.validateDroppedPath(url.path) {
                    viewModel.selectedPath = url.path
                }
            }
        }
        
        return true
    }
}
