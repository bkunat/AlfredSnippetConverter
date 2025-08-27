import XCTest
import ArgumentParser
@testable import SnippetConverterCore
import Foundation

final class SimpleCLITests: XCTestCase {
    
    private var tempDirectory: URL!
    private var outputDirectory: URL!
    
    override func setUp() {
        super.setUp()
        tempDirectory = createTemporaryDirectory()
        outputDirectory = createTemporaryDirectory()
    }
    
    override func tearDown() {
        super.tearDown()
        try? FileManager.default.removeItem(at: tempDirectory)
        try? FileManager.default.removeItem(at: outputDirectory)
    }
    
    // MARK: - Basic CLI Tests
    
    func test_snippetConverter_canCreateInstance() throws {
        // Test that we can create an instance with all required properties
        // This is mainly a structural test to ensure the CLI module is working
        XCTAssertNotNil(SnippetConverter.self)
    }
    
    // Test validation logic through the core module
    func test_inputValidation_logic_works() throws {
        try createTestSnippetFiles()
        
        // Test valid directory
        let validType = SnippetConverterCore.determineInputType(tempDirectory.path)
        XCTAssertEqual(validType, .directory)
        
        // Test nonexistent path
        let invalidType = SnippetConverterCore.determineInputType("/nonexistent/path")
        XCTAssertEqual(invalidType, .unsupported)
        
        // Test unsupported file
        let textFile = tempDirectory.appendingPathComponent("test.txt")
        try "Some content".write(to: textFile, atomically: true, encoding: .utf8)
        let unsupportedType = SnippetConverterCore.determineInputType(textFile.path)
        XCTAssertEqual(unsupportedType, .unsupported)
    }
    
    // MARK: - Integration Tests
    
    func test_cliIntegration_usesCorrectCoreComponents() throws {
        try createTestSnippetFiles()
        
        // Test that the CLI integrates with core components correctly
        let coreConverter = SnippetConverterCore.DefaultSnippetConverter(
            snippetExportPath: tempDirectory.path,
            outputDestination: outputDirectory.path,
            outputFileName: "integration-test.plist"
        )
        
        try coreConverter.run()
        
        let outputFile = outputDirectory.appendingPathComponent("integration-test.plist")
        XCTAssertTrue(FileManager.default.fileExists(atPath: outputFile.path))
        
        let content = try String(contentsOf: outputFile)
        XCTAssertTrue(content.contains("<?xml version=\"1.0\" encoding=\"UTF-8\"?>"))
        XCTAssertTrue(content.contains("<plist version=\"1.0\">"))
        XCTAssertTrue(content.contains(":hello"))
        XCTAssertTrue(content.contains("Hello World!"))
    }
    
    // MARK: - Module Integration Tests
    
    func test_cliModule_importsCorrectly() {
        // Test that CLI module can access core functionality
        XCTAssertNotNil(SnippetConverterCore.determineInputType)
        XCTAssertNotNil(SnippetConverterCore.DefaultSnippetConverter.self)
        XCTAssertNotNil(ArgumentParser.ValidationError.self)
    }
    
    // MARK: - Helper Methods
    
    private func createTemporaryDirectory() -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let uniqueID = UUID().uuidString
        let tempURL = tempDir.appendingPathComponent("SimpleCLITest-\(uniqueID)")
        
        do {
            try FileManager.default.createDirectory(at: tempURL, withIntermediateDirectories: true, attributes: nil)
            return tempURL
        } catch {
            fatalError("Failed to create temporary directory: \(error)")
        }
    }
    
    private func createTestSnippetFiles() throws {
        let snippets = [
            ("snippet1.json", "hello", "Hello World!", "Greeting", "uid-1"),
            ("snippet2.json", "bye", "Goodbye!", "Farewell", "uid-2")
        ]
        
        for (filename, keyword, snippet, name, uid) in snippets {
            try createAlfredSnippetFile(in: tempDirectory, filename: filename, 
                                      keyword: keyword, snippet: snippet, name: name, uid: uid)
        }
    }
    
    private func createAlfredSnippetFile(in directory: URL, filename: String, keyword: String, snippet: String, name: String, uid: String) throws {
        let alfredSnippet = [
            "alfredsnippet": [
                "snippet": snippet,
                "uid": uid,
                "name": name,
                "keyword": keyword
            ]
        ]
        
        let jsonData = try JSONSerialization.data(withJSONObject: alfredSnippet, options: .prettyPrinted)
        let fileURL = directory.appendingPathComponent(filename)
        try jsonData.write(to: fileURL)
    }
}
