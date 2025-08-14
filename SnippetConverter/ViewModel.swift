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
    
    func validateDroppedPath(_ path: String) -> Bool {
        let fileManager = FileManager.default
        var isDirectory: ObjCBool = false
        
        // Check if path exists and is a directory
        guard fileManager.fileExists(atPath: path, isDirectory: &isDirectory),
              isDirectory.boolValue else {
            error = ValidationError.notADirectory
            return false
        }
        
        // Check if directory contains at least one .json file
        do {
            let contents = try fileManager.contentsOfDirectory(atPath: path)
            let hasJsonFiles = contents.contains { $0.hasSuffix(".json") }
            
            if !hasJsonFiles {
                error = ValidationError.noJsonFiles
                return false
            }
            
            return true
        } catch {
            self.error = ValidationError.unableToReadDirectory
            return false
        }
    }
}

enum ValidationError: LocalizedError {
    case notADirectory
    case noJsonFiles
    case unableToReadDirectory
    
    var errorDescription: String? {
        switch self {
        case .notADirectory:
            return "Please select a folder containing Alfred snippet files."
        case .noJsonFiles:
            return "The selected folder doesn't contain any Alfred snippet files (.json)."
        case .unableToReadDirectory:
            return "Unable to read the contents of the selected folder."
        }
    }
}
