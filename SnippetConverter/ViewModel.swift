import AppKit
import Combine
import SnippetConverterCore

final class ViewModel: ObservableObject {
    @Published var selectedPath: String?
    @Published var error: Error?

    var selectFileTitle: String {
        selectedPath == nil ? "Not Selected" : selectedPath!
    }

    private var snippetConverter: DefaultSnippetConverter?

    init(selectedPath: String? = nil, error: Error? = nil, snippetConverter: DefaultSnippetConverter? = nil) {
        self.selectedPath = selectedPath
        self.error = error
        self.snippetConverter = snippetConverter
    }

    func openFilePicker() {
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = false // Users can't choose files
        openPanel.canChooseDirectories = true // Users can choose directories
        openPanel.allowsMultipleSelection = false // Only one directory at a time

        if openPanel.runModal() == .OK {
            selectedPath = openPanel.url?.path // Get the selected directory path
        }
    }

    func convertFile(snippetExportPath: String, outputDestination: String, outputFileName: String) {
        snippetConverter = DefaultSnippetConverter(snippetExportPath: snippetExportPath, outputDestination: outputDestination, outputFileName: outputFileName)
        do {
            try snippetConverter?.run()
        } catch {
            self.error = error
        }
    }
}
