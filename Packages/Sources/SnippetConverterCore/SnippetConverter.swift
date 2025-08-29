import Foundation

public protocol SnippetConverter {
    func run() throws
}

public struct DefaultSnippetConverter: SnippetConverter {
    private let snippetExportPath: String?
    private let inputHandler: SnippetInputHandler?
    private let outputDestination: String
    private let outputFileName: String

    private var outputURL: URL {
        URL(fileURLWithPath: NSString(string: outputDestination).expandingTildeInPath)
            .appendingPathComponent(outputFileName)
    }

    public init(snippetExportPath: String, outputDestination: String, outputFileName: String) {
        self.snippetExportPath = snippetExportPath
        self.inputHandler = nil
        self.outputDestination = outputDestination
        self.outputFileName = outputFileName
    }
    
    public init(inputHandler: SnippetInputHandler, outputDestination: String, outputFileName: String) {
        self.snippetExportPath = nil
        self.inputHandler = inputHandler
        self.outputDestination = outputDestination
        self.outputFileName = outputFileName
    }

    public func run() throws {
        try validateOutputFileName()
        try checkIfFileExists()

        FileHandler.createFile(at: outputURL)

        let handler = try createInputHandler()
        let directoryURL = try handler.prepareInput()
        
        defer {
            try? handler.cleanup()
        }

        let fileURLs = try fetchJSONFileURLs(from: directoryURL.path)
        let snippets = try fileURLs.map(decodeSnippet)
        try writeSnippets(snippets)
    }
    
    private func createInputHandler() throws -> SnippetInputHandler {
        if let handler = inputHandler {
            return handler
        } else if let path = snippetExportPath {
            let inputType = determineInputType(path)
            switch inputType {
            case .directory:
                return DirectoryInputHandler(directoryPath: path)
            case .zipFile:
                return ZipInputHandler(zipFilePath: path)
            case .unsupported:
                throw SnippetConverterError.unsupportedInputFormat
            }
        } else {
            throw SnippetConverterError.unsupportedInputFormat
        }
    }

    private func validateOutputFileName() throws {
        guard outputFileName.hasSuffix(".plist") else {
            throw SnippetConverterError.invalidOutputFileType
        }
    }

    private func checkIfFileExists() throws {
        guard !FileManager.default.fileExists(atPath: outputURL.path) else {
            throw SnippetConverterError.fileAlreadyExists(filePath: outputURL.path)
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

    private func writeSnippets(_ snippets: [Alfredsnippet]) throws {
        try write(PropertyListFile.header, to: outputURL)
        try snippets.forEach { snippet in
            let systemSnippet = createSystemSnippet(from: snippet)
            try write(systemSnippet, to: outputURL)
        }
        try write(PropertyListFile.footer, to: outputURL)
    }

    private func createSystemSnippet(from snippet: Alfredsnippet) -> String {
        """
        <dict>
            <key>phrase</key>
            <string>\(snippet.snippet)</string>
            <key>shortcut</key>
            <string>:\(snippet.keyword)</string>
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

enum PropertyListFile {
    static let header = """
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <array>
    """
    static let footer = """
    </array>
    </plist>
    """
}
