import AppKit
import Combine
import SnippetConverterCore
import UniformTypeIdentifiers

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
        openPanel.canChooseFiles = true // Users can choose files
        openPanel.canChooseDirectories = true // Users can choose directories
        openPanel.allowsMultipleSelection = false // Only one at a time
        openPanel.allowedContentTypes = [.zip, .folder]

        if openPanel.runModal() == .OK {
            selectedPath = openPanel.url?.path // Get the selected path
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
        let inputType = SnippetConverterCore.determineInputType(path)
        
        switch inputType {
        case .directory:
            return validateDirectory(path)
        case .zipFile:
            return validateZipFile(path)
        case .unsupported:
            error = ValidationError.unsupportedFormat
            return false
        }
    }
    
    private func validateDirectory(_ path: String) -> Bool {
        let fileManager = FileManager.default
        
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
    
    private func validateZipFile(_ path: String) -> Bool {
        // Basic validation - file exists and has correct extension
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: path) else {
            error = ValidationError.fileNotFound
            return false
        }
        
        // Additional validation will be done during processing
        return true
    }
}

enum ValidationError: LocalizedError {
    case notADirectory
    case noJsonFiles
    case unableToReadDirectory
    case unsupportedFormat
    case fileNotFound
    
    var errorDescription: String? {
        switch self {
        case .notADirectory:
            return "Please select a folder containing Alfred snippet files."
        case .noJsonFiles:
            return "The selected folder doesn't contain any Alfred snippet files (.json)."
        case .unableToReadDirectory:
            return "Unable to read the contents of the selected folder."
        case .unsupportedFormat:
            return "Please select a folder containing Alfred snippet files or an .alfredsnippets file."
        case .fileNotFound:
            return "The selected file could not be found."
        }
    }
}
