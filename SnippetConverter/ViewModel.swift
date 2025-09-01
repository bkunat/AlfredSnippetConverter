import AppKit
import Combine
import SnippetConverterCore
import UniformTypeIdentifiers

public struct SelectedCollection: Identifiable, Equatable {
    public let id = UUID()
    public let path: String
    public let displayName: String
    public let type: InputType
    public let snippetCount: Int?
    
    public init(path: String, displayName: String, type: InputType, snippetCount: Int? = nil) {
        self.path = path
        self.displayName = displayName
        self.type = type
        self.snippetCount = snippetCount
    }
    
    public static func == (lhs: SelectedCollection, rhs: SelectedCollection) -> Bool {
        return lhs.path == rhs.path
    }
}

final class ViewModel: ObservableObject {
    @Published var selectedPaths: [SelectedCollection] = []
    @Published var error: Error?

    var selectFileTitle: String {
        if selectedPaths.isEmpty {
            return "Not Selected"
        } else if selectedPaths.count == 1 {
            return selectedPaths[0].displayName
        } else {
            return "\(selectedPaths.count) Collections Selected"
        }
    }
    
    // Keep backward compatibility with existing code
    var selectedPath: String? {
        return selectedPaths.first?.path
    }

    private var snippetConverter: DefaultSnippetConverter?

    init(selectedPaths: [SelectedCollection] = [], error: Error? = nil, snippetConverter: DefaultSnippetConverter? = nil) {
        self.selectedPaths = selectedPaths
        self.error = error
        self.snippetConverter = snippetConverter
    }

    @MainActor func openFilePicker() {
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = true // Users can choose files
        openPanel.canChooseDirectories = true // Users can choose directories
        openPanel.allowsMultipleSelection = true // Allow multiple selections
        openPanel.allowedContentTypes = [.zip, .folder]

        if openPanel.runModal() == .OK {
            let newCollections = openPanel.urls.compactMap { url in
                createSelectedCollection(from: url.path)
            }
            
            // Add new collections, avoiding duplicates
            for collection in newCollections {
                if !selectedPaths.contains(collection) {
                    selectedPaths.append(collection)
                }
            }
        }
    }
    
    func clearSelection() {
        selectedPaths.removeAll()
        error = nil
    }
    
    func removeCollection(_ collection: SelectedCollection) {
        selectedPaths.removeAll { $0.id == collection.id }
    }
    
    private func createSelectedCollection(from path: String) -> SelectedCollection? {
        guard validateDroppedPath(path) else { return nil }
        
        let inputType = SnippetConverterCore.determineInputType(path)
        let displayName: String
        let snippetCount: Int?
        
        switch inputType {
        case .directory:
            displayName = URL(fileURLWithPath: path).lastPathComponent
            snippetCount = getSnippetCount(from: path)
        case .zipFile:
            displayName = URL(fileURLWithPath: path).lastPathComponent
            snippetCount = nil // We'd need to extract to count, skip for now
        case .unsupported:
            return nil
        }
        
        return SelectedCollection(
            path: path,
            displayName: displayName,
            type: inputType,
            snippetCount: snippetCount
        )
    }
    
    private func getSnippetCount(from path: String) -> Int? {
        do {
            let contents = try FileManager.default.contentsOfDirectory(atPath: path)
            return contents.filter { $0.hasSuffix(".json") }.count
        } catch {
            return nil
        }
    }
    
    func generateUniqueFileName(baseName: String, destination: String) -> String {
        let fileManager = FileManager.default
        let expandedDestination = NSString(string: destination).expandingTildeInPath
        
        var counter = 2
        var uniqueName = baseName
        
        while fileManager.fileExists(atPath: "\(expandedDestination)/\(uniqueName)") {
            let nameWithoutExtension = NSString(string: baseName).deletingPathExtension
            let fileExtension = NSString(string: baseName).pathExtension
            uniqueName = "\(nameWithoutExtension) \(counter).\(fileExtension)"
            counter += 1
        }
        
        return uniqueName
    }
    
    @MainActor func convertFileWithForceOverwrite(snippetExportPath: String, outputDestination: String, outputFileName: String, forceOverwrite: Bool = false) {
        let finalFileName = forceOverwrite ? generateUniqueFileName(baseName: outputFileName, destination: outputDestination) : outputFileName
        
        snippetConverter = DefaultSnippetConverter(snippetExportPath: snippetExportPath, outputDestination: outputDestination, outputFileName: finalFileName)
        do {
            try snippetConverter?.run()
            openInFinder(destination: outputDestination, fileName: finalFileName)
        } catch {
            self.error = error
        }
    }

    @MainActor func convertFile(snippetExportPath: String, outputDestination: String, outputFileName: String) {
        snippetConverter = DefaultSnippetConverter(snippetExportPath: snippetExportPath, outputDestination: outputDestination, outputFileName: outputFileName)
        do {
            try snippetConverter?.run()
            openInFinder(destination: outputDestination, fileName: outputFileName)
        } catch {
            self.error = error
        }
    }
    
    @MainActor func convertMultipleCollections(outputDestination: String, outputFileName: String, outputStrategy: MultiSnippetConverter.OutputStrategy, forceOverwrite: Bool = false) {
        guard !selectedPaths.isEmpty else {
            self.error = ValidationError.noSelection
            return
        }
        
        let finalFileName = forceOverwrite ? generateUniqueFileName(baseName: outputFileName, destination: outputDestination) : outputFileName
        let inputPaths = selectedPaths.map { $0.path }
        
        let multiConverter = MultiSnippetConverter(
            inputPaths: inputPaths,
            outputStrategy: outputStrategy,
            outputDestination: outputDestination,
            outputFileName: finalFileName
        )
        
        do {
            try multiConverter.run()
            openInFinder(destination: outputDestination, fileName: finalFileName)
        } catch {
            self.error = error
        }
    }
    
    @MainActor private func openInFinder(destination: String, fileName: String) {
        let expandedDestination = NSString(string: destination).expandingTildeInPath
        let filePath = "\(expandedDestination)/\(fileName)"
        _ = URL(fileURLWithPath: filePath)
        
        NSWorkspace.shared.selectFile(filePath, inFileViewerRootedAtPath: expandedDestination)
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
    
    func addDroppedPath(_ path: String) {
        if let collection = createSelectedCollection(from: path) {
            if !selectedPaths.contains(collection) {
                selectedPaths.append(collection)
            }
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
    case noSelection
    
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
        case .noSelection:
            return "Please select one or more collections to convert."
        }
    }
}
