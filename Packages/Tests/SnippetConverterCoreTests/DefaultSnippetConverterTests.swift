import XCTest
@testable import SnippetConverterCore
import Foundation

final class DefaultSnippetConverterTests: XCTestCase {
    
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
    
    // MARK: - Constructor Tests
    
    func test_initWithSnippetPath_setsPropertiesCorrectly() {
        let converter = DefaultSnippetConverter(
            snippetExportPath: "/test/path",
            outputDestination: "/output",
            outputFileName: "test.plist"
        )
        
        XCTAssertNotNil(converter)
    }
    
    func test_initWithInputHandler_setsPropertiesCorrectly() {
        let handler = DirectoryInputHandler(directoryPath: tempDirectory.path)
        let converter = DefaultSnippetConverter(
            inputHandler: handler,
            outputDestination: outputDirectory.path,
            outputFileName: "test.plist"
        )
        
        XCTAssertNotNil(converter)
    }
    
    // MARK: - Validation Tests
    
    func test_run_throwsErrorForInvalidOutputFileName() {
        let converter = DefaultSnippetConverter(
            snippetExportPath: tempDirectory.path,
            outputDestination: outputDirectory.path,
            outputFileName: "invalid.txt"
        )
        
        XCTAssertThrowsError(try converter.run()) { error in
            XCTAssertEqual(error as? SnippetConverterError, .invalidOutputFileType)
        }
    }
    
    func test_run_throwsErrorWhenFileAlreadyExists() throws {
        let fileName = "existing.plist"
        let existingFile = outputDirectory.appendingPathComponent(fileName)
        
        // Create existing file
        FileManager.default.createFile(atPath: existingFile.path, contents: Data())
        
        let converter = DefaultSnippetConverter(
            snippetExportPath: tempDirectory.path,
            outputDestination: outputDirectory.path,
            outputFileName: fileName
        )
        
        XCTAssertThrowsError(try converter.run()) { error in
            if case SnippetConverterError.fileAlreadyExists(let path) = error {
                XCTAssertEqual(path, existingFile.path)
            } else {
                XCTFail("Expected fileAlreadyExists error, got \(error)")
            }
        }
    }
    
    func test_run_throwsErrorForUnsupportedInputFormat() {
        let converter = DefaultSnippetConverter(
            snippetExportPath: "/nonexistent/path",
            outputDestination: outputDirectory.path,
            outputFileName: "test.plist"
        )
        
        XCTAssertThrowsError(try converter.run()) { error in
            XCTAssertEqual(error as? SnippetConverterError, .unsupportedInputFormat)
        }
    }
    
    // MARK: - Successful Conversion Tests
    
    func test_run_successfullyConvertsValidSnippets() throws {
        // Create test JSON files
        try createTestSnippetFiles()
        
        let converter = DefaultSnippetConverter(
            snippetExportPath: tempDirectory.path,
            outputDestination: outputDirectory.path,
            outputFileName: "output.plist"
        )
        
        try converter.run()
        
        // Verify output file was created
        let outputFile = outputDirectory.appendingPathComponent("output.plist")
        XCTAssertTrue(FileManager.default.fileExists(atPath: outputFile.path))
        
        // Verify content structure
        let content = try String(contentsOf: outputFile)
        XCTAssertTrue(content.contains("<?xml version=\"1.0\" encoding=\"UTF-8\"?>"))
        XCTAssertTrue(content.contains("<plist version=\"1.0\">"))
        XCTAssertTrue(content.contains("<array>"))
        XCTAssertTrue(content.contains("</array>"))
        XCTAssertTrue(content.contains("</plist>"))
    }
    
    func test_run_convertsSnippetContentCorrectly() throws {
        // Create a specific test snippet
        let testSnippet = createTestSnippet(
            keyword: "hello",
            snippet: "Hello World!",
            name: "Test Greeting",
            uid: "test-uid-123"
        )
        
        let jsonData = try JSONEncoder().encode(["alfredsnippet": testSnippet])
        let testFile = tempDirectory.appendingPathComponent("test.json")
        try jsonData.write(to: testFile)
        
        let converter = DefaultSnippetConverter(
            snippetExportPath: tempDirectory.path,
            outputDestination: outputDirectory.path,
            outputFileName: "output.plist"
        )
        
        try converter.run()
        
        let outputFile = outputDirectory.appendingPathComponent("output.plist")
        let content = try String(contentsOf: outputFile)
        
        // Verify snippet conversion
        XCTAssertTrue(content.contains("<key>phrase</key>"))
        XCTAssertTrue(content.contains("<string>Hello World!</string>"))
        XCTAssertTrue(content.contains("<key>shortcut</key>"))
        XCTAssertTrue(content.contains("<string>:hello</string>"))
    }
    
    func test_run_handlesMultipleSnippets() throws {
        // Create multiple test snippets
        let snippets = [
            ("snippet1", "hello", "Hello World!", "Greeting 1", "uid-1"),
            ("snippet2", "bye", "Goodbye!", "Farewell", "uid-2"),
            ("snippet3", "thanks", "Thank you!", "Gratitude", "uid-3")
        ]
        
        for (fileName, keyword, snippet, name, uid) in snippets {
            let testSnippet = createTestSnippet(keyword: keyword, snippet: snippet, name: name, uid: uid)
            let jsonData = try JSONEncoder().encode(["alfredsnippet": testSnippet])
            let testFile = tempDirectory.appendingPathComponent("\(fileName).json")
            try jsonData.write(to: testFile)
        }
        
        let converter = DefaultSnippetConverter(
            snippetExportPath: tempDirectory.path,
            outputDestination: outputDirectory.path,
            outputFileName: "output.plist"
        )
        
        try converter.run()
        
        let outputFile = outputDirectory.appendingPathComponent("output.plist")
        let content = try String(contentsOf: outputFile)
        
        // Verify all snippets are included
        XCTAssertTrue(content.contains(":hello"))
        XCTAssertTrue(content.contains(":bye"))
        XCTAssertTrue(content.contains(":thanks"))
        XCTAssertTrue(content.contains("Hello World!"))
        XCTAssertTrue(content.contains("Goodbye!"))
        XCTAssertTrue(content.contains("Thank you!"))
    }
    
    func test_run_ignoresNonJsonFiles() throws {
        // Create JSON and non-JSON files
        try createTestSnippetFiles()
        
        // Add some non-JSON files
        let textFile = tempDirectory.appendingPathComponent("readme.txt")
        try "This is not a JSON file".write(to: textFile, atomically: true, encoding: .utf8)
        
        let imageFile = tempDirectory.appendingPathComponent("image.png")
        try Data([0x89, 0x50, 0x4E, 0x47]).write(to: imageFile) // PNG header
        
        let converter = DefaultSnippetConverter(
            snippetExportPath: tempDirectory.path,
            outputDestination: outputDirectory.path,
            outputFileName: "output.plist"
        )
        
        try converter.run()
        
        // Should complete successfully, ignoring non-JSON files
        let outputFile = outputDirectory.appendingPathComponent("output.plist")
        XCTAssertTrue(FileManager.default.fileExists(atPath: outputFile.path))
    }
    
    func test_run_throwsErrorForInvalidJson() throws {
        // Create invalid JSON file
        let invalidFile = tempDirectory.appendingPathComponent("invalid.json")
        try "{ invalid json content }".write(to: invalidFile, atomically: true, encoding: .utf8)
        
        let converter = DefaultSnippetConverter(
            snippetExportPath: tempDirectory.path,
            outputDestination: outputDirectory.path,
            outputFileName: "output.plist"
        )
        
        XCTAssertThrowsError(try converter.run())
    }
    
    func test_run_handlesSpecialCharactersInSnippets() throws {
        let specialSnippet = createTestSnippet(
            keyword: "special",
            snippet: "Special chars: <>&\"'\n\t\r",
            name: "Special Characters Test",
            uid: "special-uid"
        )
        
        let jsonData = try JSONEncoder().encode(["alfredsnippet": specialSnippet])
        let testFile = tempDirectory.appendingPathComponent("special.json")
        try jsonData.write(to: testFile)
        
        let converter = DefaultSnippetConverter(
            snippetExportPath: tempDirectory.path,
            outputDestination: outputDirectory.path,
            outputFileName: "output.plist"
        )
        
        try converter.run()
        
        let outputFile = outputDirectory.appendingPathComponent("output.plist")
        let content = try String(contentsOf: outputFile)
        
        // Verify content contains the special characters
        XCTAssertTrue(content.contains("Special chars: <>&\"'"))
    }
    
    // MARK: - Input Handler Integration Tests
    
    func test_run_worksWithDirectoryInputHandler() throws {
        try createTestSnippetFiles()
        
        let handler = DirectoryInputHandler(directoryPath: tempDirectory.path)
        let converter = DefaultSnippetConverter(
            inputHandler: handler,
            outputDestination: outputDirectory.path,
            outputFileName: "output.plist"
        )
        
        try converter.run()
        
        let outputFile = outputDirectory.appendingPathComponent("output.plist")
        XCTAssertTrue(FileManager.default.fileExists(atPath: outputFile.path))
    }
    
    // MARK: - Helper Methods
    
    private func createTemporaryDirectory() -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let uniqueID = UUID().uuidString
        let tempURL = tempDir.appendingPathComponent("SnippetConverterTest-\(uniqueID)")
        
        do {
            try FileManager.default.createDirectory(at: tempURL, withIntermediateDirectories: true, attributes: nil)
            return tempURL
        } catch {
            fatalError("Failed to create temporary directory: \(error)")
        }
    }
    
    private func createTestSnippetFiles() throws {
        let snippets = [
            createTestSnippet(keyword: "hello", snippet: "Hello World!", name: "Greeting", uid: "uid-1"),
            createTestSnippet(keyword: "bye", snippet: "Goodbye!", name: "Farewell", uid: "uid-2")
        ]
        
        for (index, snippet) in snippets.enumerated() {
            let jsonData = try JSONEncoder().encode(["alfredsnippet": snippet])
            let testFile = tempDirectory.appendingPathComponent("snippet\(index + 1).json")
            try jsonData.write(to: testFile)
        }
    }
    
    private func createTestSnippet(keyword: String, snippet: String, name: String, uid: String) -> Alfredsnippet {
        return Alfredsnippet(snippet: snippet, uid: uid, name: name, keyword: keyword)
    }
}