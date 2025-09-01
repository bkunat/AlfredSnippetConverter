import Foundation

public struct SnippetInputHandlerFactory {
    
    public static func createHandlers(from paths: [String]) throws -> [SnippetInputHandler] {
        try validateInputs(paths)
        
        return try paths.map { path in
            try createHandler(from: path)
        }
    }
    
    public static func validateInputs(_ paths: [String]) throws {
        guard !paths.isEmpty else {
            throw SnippetConverterError.noInputPathsProvided
        }
        
        // Check for duplicate paths
        let uniquePaths = Set(paths)
        guard uniquePaths.count == paths.count else {
            throw SnippetConverterError.duplicateInputPaths
        }
        
        // Validate each path exists and is supported
        for path in paths {
            let inputType = determineInputType(path)
            switch inputType {
            case .directory:
                try validateDirectory(path)
            case .zipFile:
                try validateZipFile(path)
            case .unsupported:
                throw SnippetConverterError.unsupportedInputFormat
            }
        }
    }
    
    private static func createHandler(from path: String) throws -> SnippetInputHandler {
        let inputType = determineInputType(path)
        switch inputType {
        case .directory:
            return DirectoryInputHandler(directoryPath: path)
        case .zipFile:
            return ZipInputHandler(zipFilePath: path)
        case .unsupported:
            throw SnippetConverterError.unsupportedInputFormat
        }
    }
    
    private static func validateDirectory(_ path: String) throws {
        let expandedPath = NSString(string: path).expandingTildeInPath
        
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: expandedPath, isDirectory: &isDirectory) else {
            throw SnippetConverterError.directoryNotFound(path: expandedPath)
        }
        
        guard isDirectory.boolValue else {
            throw SnippetConverterError.unsupportedInputFormat
        }
    }
    
    private static func validateZipFile(_ path: String) throws {
        let expandedPath = NSString(string: path).expandingTildeInPath
        
        guard FileManager.default.fileExists(atPath: expandedPath) else {
            throw SnippetConverterError.zipFileNotFound(path: expandedPath)
        }
        
        guard FileHandler.isZipFile(at: expandedPath) else {
            throw SnippetConverterError.invalidZipFile(filePath: expandedPath)
        }
    }
}