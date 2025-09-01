import Foundation

public struct CollectionMetadata {
    public let sourcePath: String
    public let collectionName: String
    public let snippetCount: Int
    
    public init(sourcePath: String, collectionName: String, snippetCount: Int) {
        self.sourcePath = sourcePath
        self.collectionName = collectionName
        self.snippetCount = snippetCount
    }
    
    public static func create(from originalPath: String, handler: SnippetInputHandler) throws -> CollectionMetadata {
        let directoryURL = try handler.prepareInput()
        let files = try FileManager.default.contentsOfDirectory(atPath: directoryURL.path)
        let jsonFiles = files.filter { $0.hasSuffix(".json") }
        
        let collectionName: String
        let inputType = determineInputType(originalPath)
        
        switch inputType {
        case .directory:
            // For directory handlers, use the directory name
            let expandedPath = NSString(string: originalPath).expandingTildeInPath
            collectionName = URL(fileURLWithPath: expandedPath).lastPathComponent
        case .zipFile:
            // For zip handlers, use the filename without extension
            let expandedPath = NSString(string: originalPath).expandingTildeInPath
            let url = URL(fileURLWithPath: expandedPath)
            collectionName = url.deletingPathExtension().lastPathComponent
        case .unsupported:
            // Fallback to generic name
            collectionName = "Collection"
        }
        
        return CollectionMetadata(
            sourcePath: originalPath,
            collectionName: sanitizeCollectionName(collectionName),
            snippetCount: jsonFiles.count
        )
    }
    
    private static func sanitizeCollectionName(_ name: String) -> String {
        // Remove invalid characters and replace with underscores
        let invalidCharacters = CharacterSet(charactersIn: "\\/:*?\"<>|")
        return name.components(separatedBy: invalidCharacters).joined(separator: "_")
    }
}