import SnippetConverterCore
import SwiftUI

struct ContentView: View {
    @State private var outputDestination = "~/Downloads"
    @State private var outputFileName = "snippet-converter-output"
    @State private var pendingConversion: (snippetPath: String, destination: String, fileName: String)?

    @StateObject private var viewModel = ViewModel()

    var body: some View {
        VStack(spacing: 16) {
            // Drop Zone
            DropZoneView(viewModel: viewModel)
            
            // Settings
            VStack(alignment: .leading, spacing: 16) {
                Text("Output Settings")
                    .font(.headline)
                
                VStack(spacing: 12) {
                    LabeledContent("Destination:") {
                        TextField("~/Downloads", text: $outputDestination)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    LabeledContent("Filename:") {
                        HStack(spacing: 4) {
                            TextField("snippet-converter-output", text: $outputFileName)
                                .textFieldStyle(.roundedBorder)
                            Text(".plist")
                                .font(.body)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            
            Button("Convert Snippets", systemImage: "arrow.right.circle.fill") {
                let finalFileName = outputFileName + ".plist"
                
                if viewModel.selectedPaths.count > 1 {
                    // Use multi-collection converter
                    let strategy = MultiSnippetConverter.OutputStrategy.merge(fileName: finalFileName)
                    viewModel.convertMultipleCollections(
                        outputDestination: outputDestination,
                        outputFileName: finalFileName,
                        outputStrategy: strategy,
                        forceOverwrite: false
                    )
                } else if let singlePath = viewModel.selectedPath {
                    // Use single-collection converter for backward compatibility
                    pendingConversion = (singlePath, outputDestination, finalFileName)
                    viewModel.convertFile(
                        snippetExportPath: singlePath,
                        outputDestination: outputDestination,
                        outputFileName: finalFileName
                    )
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(.accentColor)
            .disabled(viewModel.selectedPaths.isEmpty)
        }
        .frame(minWidth: 500, maxWidth: .infinity, minHeight: 400, maxHeight: .infinity)
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .animation(.easeInOut(duration: 0.3), value: viewModel.selectedPaths.count)
        .fileExistsAlert(error: $viewModel.error) {
            if let conversion = pendingConversion {
                viewModel.convertFileWithForceOverwrite(
                    snippetExportPath: conversion.snippetPath,
                    outputDestination: conversion.destination,
                    outputFileName: conversion.fileName,
                    forceOverwrite: true
                )
            }
        }
    }
}

#Preview {
    ContentView()
}
