import SnippetConverterCore
import SwiftUI

struct ContentView: View {
    @State private var outputDestination = "~/Downloads"
    @State private var outputFileName = "snippet-converter-output.plist"

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
                        TextField("output.plist", text: $outputFileName)
                            .textFieldStyle(.roundedBorder)
                    }
                }
            }
            
            Button("Convert Snippets", systemImage: "arrow.right.circle.fill") {
                viewModel.convertFile(
                    snippetExportPath: viewModel.selectedPath!,
                    outputDestination: outputDestination,
                    outputFileName: outputFileName
                )
            }
            .buttonStyle(.borderedProminent)
            .tint(.accentColor)
            .disabled(viewModel.selectedPath == nil)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .errorAlert(error: $viewModel.error)
    }
}

#Preview {
    ContentView()
}
