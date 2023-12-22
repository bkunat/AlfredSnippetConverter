import SnippetConverterCore
import SwiftUI

struct ContentView: View {
    @State private var outputDestination = "~/Downloads"
    @State private var outputFileName = "snippet-converter-output.plist"

    @StateObject private var viewModel = ViewModel()

    var body: some View {
        VStack {
            Form {
                Section(header: Text("Alfred Snippets Exportr")) {
                    HStack {
                        Button("Browse Files", systemImage: "folder") {
                            viewModel.openFilePicker()
                        }
                        Spacer()
                        Text(viewModel.selectFileTitle)
                    }
                }

                Section(header: Text("Output Settings")) {
                    TextField("Output Destination", text: $outputDestination)
                    TextField("Output File Name", text: $outputFileName)
                }
            }
            .formStyle(.grouped)
            Button(action: {
                viewModel.convertFile(
                    snippetExportPath: viewModel.selectedPath!,
                    outputDestination: outputDestination,
                    outputFileName: outputFileName
                )
            }) {
                Text("Convert")
            }
            .disabled(viewModel.selectedPath == nil)
            .padding()
        }
        .navigationTitle("Snippet Converter")
        .errorAlert(error: $viewModel.error)
    }
}

#Preview {
    ContentView()
}
