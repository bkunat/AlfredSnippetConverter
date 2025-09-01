import Foundation

public struct MultiSnippetConverter: SnippetConverter {
    private let inputPaths: [String]
    private let outputStrategy: OutputStrategy
    private let outputDestination: String
    private let outputFileName: String
    
    public enum OutputStrategy {
        case merge(fileName: String)
        case separate(baseFileName: String)
    }
    
    private var outputURL: URL {
        URL(fileURLWithPath: NSString(string: outputDestination).expandingTildeInPath)
            .appendingPathComponent(outputFileName)
    }
    
    public init(inputPaths: [String], outputStrategy: OutputStrategy, outputDestination: String, outputFileName: String) {
        self.inputPaths = inputPaths
        self.outputStrategy = outputStrategy
        self.outputDestination = outputDestination
        self.outputFileName = outputFileName
    }
    
    public func run() throws {
        guard !inputPaths.isEmpty else {
            throw SnippetConverterError.noInputPathsProvided
        }
        
        try validateInputPaths()
        
        let inputHandlers = try SnippetInputHandlerFactory.createHandlers(from: inputPaths)
        let collectionsMetadata = try zip(inputPaths, inputHandlers).map { (path, handler) in
            try CollectionMetadata.create(from: path, handler: handler)
        }
        
        defer {
            inputHandlers.forEach { handler in
                try? handler.cleanup()
            }
        }
        
        switch outputStrategy {
        case .merge(let fileName):
            try runMergeStrategy(handlers: inputHandlers, collectionsMetadata: collectionsMetadata, fileName: fileName)
        case .separate(let baseFileName):
            try runSeparateStrategy(handlers: inputHandlers, collectionsMetadata: collectionsMetadata, baseFileName: baseFileName)
        }
    }
    
    private func validateInputPaths() throws {
        for path in inputPaths {
            let inputType = determineInputType(path)
            switch inputType {
            case .directory, .zipFile:
                break
            case .unsupported:
                throw SnippetConverterError.unsupportedInputFormat
            }
        }
    }
    
    private func runMergeStrategy(handlers: [SnippetInputHandler], collectionsMetadata: [CollectionMetadata], fileName: String) throws {
        let mergeOutputURL = URL(fileURLWithPath: NSString(string: outputDestination).expandingTildeInPath)
            .appendingPathComponent(fileName)
        
        try validateOutputFileName(fileName)
        
        guard !FileManager.default.fileExists(atPath: mergeOutputURL.path) else {
            throw SnippetConverterError.fileAlreadyExists(filePath: mergeOutputURL.path)
        }
        
        FileHandler.createFile(at: mergeOutputURL)
        
        try write(PropertyListFile.header, to: mergeOutputURL)
        
        for (handler, metadata) in zip(handlers, collectionsMetadata) {
            let directoryURL = try handler.prepareInput()
            let fileURLs = try fetchJSONFileURLs(from: directoryURL.path)
            let snippets = try fileURLs.map(decodeSnippet)
            
            for snippet in snippets {
                let systemSnippet = createSystemSnippet(from: snippet, collectionName: metadata.collectionName)
                try write(systemSnippet, to: mergeOutputURL)
            }
        }
        
        try write(PropertyListFile.footer, to: mergeOutputURL)
    }
    
    private func runSeparateStrategy(handlers: [SnippetInputHandler], collectionsMetadata: [CollectionMetadata], baseFileName: String) throws {
        let baseNameWithoutExtension = NSString(string: baseFileName).deletingPathExtension
        let fileExtension = NSString(string: baseFileName).pathExtension.isEmpty ? "plist" : NSString(string: baseFileName).pathExtension
        
        for (handler, metadata) in zip(handlers, collectionsMetadata) {
            let separateFileName = "\(baseNameWithoutExtension)-\(metadata.collectionName).\(fileExtension)"
            let separateOutputURL = URL(fileURLWithPath: NSString(string: outputDestination).expandingTildeInPath)
                .appendingPathComponent(separateFileName)
            
            try validateOutputFileName(separateFileName)
            
            guard !FileManager.default.fileExists(atPath: separateOutputURL.path) else {
                throw SnippetConverterError.fileAlreadyExists(filePath: separateOutputURL.path)
            }
            
            FileHandler.createFile(at: separateOutputURL)
            
            let directoryURL = try handler.prepareInput()
            let fileURLs = try fetchJSONFileURLs(from: directoryURL.path)
            let snippets = try fileURLs.map(decodeSnippet)
            
            try write(PropertyListFile.header, to: separateOutputURL)
            
            for snippet in snippets {
                let systemSnippet = createSystemSnippet(from: snippet, collectionName: nil)
                try write(systemSnippet, to: separateOutputURL)
            }
            
            try write(PropertyListFile.footer, to: separateOutputURL)
        }
    }
    
    private func validateOutputFileName(_ fileName: String) throws {
        guard fileName.hasSuffix(".plist") else {
            throw SnippetConverterError.invalidOutputFileType
        }
    }
    
    private func fetchJSONFileURLs(from directoryPath: String) throws -> [URL] {
        let files = try FileManager.default.contentsOfDirectory(atPath: directoryPath)
        return files
            .filter { $0.hasSuffix(".json") }
            .map { URL(fileURLWithPath: directoryPath).appendingPathComponent($0) }
    }
    
    private func decodeSnippet(from fileURL: URL) throws -> Alfredsnippet {
        let jsonData = try Data(contentsOf: fileURL)
        return try JSONDecoder().decode(Snippet.self, from: jsonData).alfredsnippet
    }
    
    private func createSystemSnippet(from snippet: Alfredsnippet, collectionName: String?) -> String {
        let keyword = collectionName != nil ? "\(collectionName!)_\(snippet.keyword)" : snippet.keyword
        return """
        <dict>
            <key>phrase</key>
            <string>\(snippet.snippet)</string>
            <key>shortcut</key>
            <string>:\(keyword)</string>
        </dict>\n
        """
    }
    
    private func write(_ string: String, to url: URL) throws {
        guard let data = string.data(using: .utf8) else {
            throw SnippetConverterError.invalidData
        }
        let fileHandle = try FileHandle(forWritingTo: url)
        fileHandle.seekToEndOfFile()
        try fileHandle.write(contentsOf: data)
        fileHandle.closeFile()
    }
}