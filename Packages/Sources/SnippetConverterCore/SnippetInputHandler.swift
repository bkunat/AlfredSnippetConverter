import Foundation

public protocol SnippetInputHandler {
    func prepareInput() throws -> URL
    func cleanup() throws
}

public final class DirectoryInputHandler: SnippetInputHandler {
    private let directoryPath: String
    
    public init(directoryPath: String) {
        self.directoryPath = directoryPath
    }
    
    public func prepareInput() throws -> URL {
        let expandedPath = NSString(string: directoryPath).expandingTildeInPath
        let url = URL(fileURLWithPath: expandedPath)
        
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: expandedPath, isDirectory: &isDirectory) else {
            throw SnippetConverterError.directoryNotFound(path: expandedPath)
        }
        
        guard isDirectory.boolValue else {
            throw SnippetConverterError.unsupportedInputFormat
        }
        
        return url
    }
    
    public func cleanup() throws {
        // No cleanup needed for directory handler
    }
}

public final class ZipInputHandler: SnippetInputHandler {
    private let zipFilePath: String
    private var temporaryDirectory: URL?
    
    public init(zipFilePath: String) {
        self.zipFilePath = zipFilePath
    }
    
    public func prepareInput() throws -> URL {
        let expandedPath = NSString(string: zipFilePath).expandingTildeInPath
        let _ = URL(fileURLWithPath: expandedPath)
        
        guard FileManager.default.fileExists(atPath: expandedPath) else {
            throw SnippetConverterError.zipFileNotFound(path: expandedPath)
        }
        
        guard FileHandler.isZipFile(at: expandedPath) else {
            throw SnippetConverterError.invalidZipFile(filePath: expandedPath)
        }
        
        let tempDirectory = try FileHandler.createTemporaryDirectory()
        temporaryDirectory = tempDirectory
        
        do {
            try FileHandler.extractZip(from: expandedPath, to: tempDirectory.path)
            try validateExtractedContent(at: tempDirectory)
            return tempDirectory
        } catch {
            try? cleanup()
            throw SnippetConverterError.zipExtractionFailed(error: error)
        }
    }
    
    public func cleanup() throws {
        guard let tempDir = temporaryDirectory else { return }
        
        do {
            try FileHandler.removeDirectory(at: tempDir)
            temporaryDirectory = nil
        } catch {
            throw SnippetConverterError.cleanupFailed(error: error)
        }
    }
    
    private func validateExtractedContent(at url: URL) throws {
        let contents = try FileManager.default.contentsOfDirectory(atPath: url.path)
        
        let hasJSONFiles = contents.contains { $0.hasSuffix(".json") }
        let hasInfoPlist = contents.contains { $0 == "info.plist" }
        
        guard hasJSONFiles else {
            throw SnippetConverterError.invalidArchiveContent(reason: "No JSON snippet files found")
        }
        
        guard hasInfoPlist else {
            throw SnippetConverterError.invalidArchiveContent(reason: "No info.plist found")
        }
    }
}

public enum InputType {
    case directory
    case zipFile
    case unsupported
}

public func determineInputType(_ path: String) -> InputType {
    let expandedPath = NSString(string: path).expandingTildeInPath
    let url = URL(fileURLWithPath: expandedPath)
    
    if url.pathExtension.lowercased() == "alfredsnippets" {
        return .zipFile
    } else {
        var isDirectory: ObjCBool = false
        if FileManager.default.fileExists(atPath: expandedPath, isDirectory: &isDirectory) && isDirectory.boolValue {
            return .directory
        } else {
            return .unsupported
        }
    }
}
