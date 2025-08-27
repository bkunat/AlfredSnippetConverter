import XCTest
@testable import SnippetConverterCore
import Foundation

final class InputHandlerIntegrationTests: XCTestCase {
    
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
    
    // MARK: - DirectoryInputHandler Integration Tests
    
    func test_directoryInputHandler_integrationWithDefaultSnippetConverter() throws {
        try createTestSnippetFiles()
        
        let handler = DirectoryInputHandler(directoryPath: tempDirectory.path)
        let converter = DefaultSnippetConverter(
            inputHandler: handler,
            outputDestination: outputDirectory.path,
            outputFileName: "directory-integration.plist"
        )
        
        try converter.run()
        
        let outputFile = outputDirectory.appendingPathComponent("directory-integration.plist")
        XCTAssertTrue(FileManager.default.fileExists(atPath: outputFile.path))
        
        let content = try String(contentsOf: outputFile)
        XCTAssertTrue(content.contains("Hello World!"))
        XCTAssertTrue(content.contains("Goodbye!"))
        XCTAssertTrue(content.contains(":hello"))
        XCTAssertTrue(content.contains(":bye"))
    }
    
    func test_directoryInputHandler_withComplexSnippetStructures() throws {
        // Create more realistic Alfred snippet structures
        try createComplexSnippetFiles()
        
        let handler = DirectoryInputHandler(directoryPath: tempDirectory.path)
        let converter = DefaultSnippetConverter(
            inputHandler: handler,
            outputDestination: outputDirectory.path,
            outputFileName: "complex-snippets.plist"
        )
        
        try converter.run()
        
        let outputFile = outputDirectory.appendingPathComponent("complex-snippets.plist")
        let content = try String(contentsOf: outputFile)
        
        // Verify complex content is handled correctly
        XCTAssertTrue(content.contains("Multi-line content") || content.contains("Line 1"))
        XCTAssertTrue(content.contains("Special chars:") || content.contains("<>&"))
        XCTAssertTrue(content.contains(":multiline"))
        XCTAssertTrue(content.contains(":special"))
        XCTAssertTrue(content.contains(":longtext"))
    }
    
    func test_directoryInputHandler_withMixedFileTypes() throws {
        // Create directory with JSON snippets and other files
        try createTestSnippetFiles()
        
        // Add non-JSON files that should be ignored
        let readmeFile = tempDirectory.appendingPathComponent("README.md")
        try "# Snippet Collection\nThis is a collection of Alfred snippets.".write(to: readmeFile, atomically: true, encoding: .utf8)
        
        let infoPlist = tempDirectory.appendingPathComponent("info.plist")
        try createInfoPlistContent().write(to: infoPlist, atomically: true, encoding: .utf8)
        
        let imageFile = tempDirectory.appendingPathComponent("icon.png")
        try Data([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]).write(to: imageFile) // PNG header
        
        let handler = DirectoryInputHandler(directoryPath: tempDirectory.path)
        let converter = DefaultSnippetConverter(
            inputHandler: handler,
            outputDestination: outputDirectory.path,
            outputFileName: "mixed-files.plist"
        )
        
        try converter.run()
        
        let outputFile = outputDirectory.appendingPathComponent("mixed-files.plist")
        XCTAssertTrue(FileManager.default.fileExists(atPath: outputFile.path))
        
        // Should only contain snippet content, not other files
        let content = try String(contentsOf: outputFile)
        XCTAssertTrue(content.contains(":hello"))
        XCTAssertTrue(content.contains(":bye"))
        XCTAssertFalse(content.contains("README"))
        XCTAssertFalse(content.contains("info.plist"))
    }
    
    func test_directoryInputHandler_errorHandling_preservesState() throws {
        // Create directory with invalid JSON
        let invalidJsonFile = tempDirectory.appendingPathComponent("invalid.json")
        try "{ invalid json content".write(to: invalidJsonFile, atomically: true, encoding: .utf8)
        
        let handler = DirectoryInputHandler(directoryPath: tempDirectory.path)
        let converter = DefaultSnippetConverter(
            inputHandler: handler,
            outputDestination: outputDirectory.path,
            outputFileName: "error-test.plist"
        )
        
        XCTAssertThrowsError(try converter.run())
        
        // Verify no partial output file was created or it's empty
        let outputFile = outputDirectory.appendingPathComponent("error-test.plist")
        if FileManager.default.fileExists(atPath: outputFile.path) {
            let fileSize = try FileManager.default.attributesOfItem(atPath: outputFile.path)[.size] as? UInt64 ?? 0
            XCTAssertEqual(fileSize, 0, "Output file should be empty after error")
        }
    }
    
    // MARK: - ZipInputHandler Integration Tests
    
    func test_zipInputHandler_integrationWithRealZipFile() throws {
        // Create a real zip file with snippet content
        let snippetDir = tempDirectory.appendingPathComponent("snippets")
        try FileManager.default.createDirectory(at: snippetDir, withIntermediateDirectories: true, attributes: nil)
        
        try createTestSnippetFiles(in: snippetDir)
        try createInfoPlistContent().write(to: snippetDir.appendingPathComponent("info.plist"), atomically: true, encoding: .utf8)
        
        let zipFile = tempDirectory.appendingPathComponent("test.alfredsnippets")
        try createZipFile(from: snippetDir, to: zipFile)
        
        let handler = ZipInputHandler(zipFilePath: zipFile.path)
        let converter = DefaultSnippetConverter(
            inputHandler: handler,
            outputDestination: outputDirectory.path,
            outputFileName: "zip-integration.plist"
        )
        
        try converter.run()
        
        let outputFile = outputDirectory.appendingPathComponent("zip-integration.plist")
        XCTAssertTrue(FileManager.default.fileExists(atPath: outputFile.path))
        
        let content = try String(contentsOf: outputFile)
        XCTAssertTrue(content.contains(":hello"))
        XCTAssertTrue(content.contains(":bye"))
    }
    
    func test_zipInputHandler_errorHandling_cleansUpTemporaryFiles() throws {
        // Create an invalid zip file
        let invalidZipFile = tempDirectory.appendingPathComponent("invalid.alfredsnippets")
        try "This is not a zip file".write(to: invalidZipFile, atomically: true, encoding: .utf8)
        
        let handler = ZipInputHandler(zipFilePath: invalidZipFile.path)
        
        // Count temp directories before
        let tempDirCount = countTemporaryDirectories()
        
        XCTAssertThrowsError(try handler.prepareInput())
        
        // Verify cleanup occurred (no additional temp directories)
        let tempDirCountAfter = countTemporaryDirectories()
        XCTAssertEqual(tempDirCount, tempDirCountAfter)
    }
    
    func test_zipInputHandler_validateExtractedContent_comprehensive() throws {
        // Test various invalid archive contents
        
        // Case 1: Archive with no JSON files
        let noJsonDir = tempDirectory.appendingPathComponent("nojson")
        try FileManager.default.createDirectory(at: noJsonDir, withIntermediateDirectories: true, attributes: nil)
        try createInfoPlistContent().write(to: noJsonDir.appendingPathComponent("info.plist"), atomically: true, encoding: .utf8)
        try "readme content".write(to: noJsonDir.appendingPathComponent("readme.txt"), atomically: true, encoding: .utf8)
        
        let noJsonZip = tempDirectory.appendingPathComponent("nojson.alfredsnippets")
        try createZipFile(from: noJsonDir, to: noJsonZip)
        
        let handler1 = ZipInputHandler(zipFilePath: noJsonZip.path)
        XCTAssertThrowsError(try handler1.prepareInput()) { error in
            if case SnippetConverterError.zipExtractionFailed(_) = error {
                // Expected error due to invalid content
            } else {
                XCTFail("Expected zipExtractionFailed error, got \(error)")
            }
        }
        
        // Case 2: Archive with no info.plist
        let noInfoDir = tempDirectory.appendingPathComponent("noinfo")
        try FileManager.default.createDirectory(at: noInfoDir, withIntermediateDirectories: true, attributes: nil)
        try createTestSnippetFiles(in: noInfoDir)
        
        let noInfoZip = tempDirectory.appendingPathComponent("noinfo.alfredsnippets")
        try createZipFile(from: noInfoDir, to: noInfoZip)
        
        let handler2 = ZipInputHandler(zipFilePath: noInfoZip.path)
        XCTAssertThrowsError(try handler2.prepareInput()) { error in
            if case SnippetConverterError.zipExtractionFailed(_) = error {
                // Expected error due to invalid content
            } else {
                XCTFail("Expected zipExtractionFailed error, got \(error)")
            }
        }
    }
    
    // MARK: - Cross Handler Integration Tests
    
    func test_inputHandlers_produceConsistentResults() throws {
        // Create test data
        let testData = try createTestDataSet()
        
        // Test with DirectoryInputHandler
        let dirHandler = DirectoryInputHandler(directoryPath: testData.directory.path)
        let dirConverter = DefaultSnippetConverter(
            inputHandler: dirHandler,
            outputDestination: outputDirectory.path,
            outputFileName: "directory-output.plist"
        )
        try dirConverter.run()
        
        // Test with ZipInputHandler using the same data
        let zipHandler = ZipInputHandler(zipFilePath: testData.zipFile.path)
        let zipConverter = DefaultSnippetConverter(
            inputHandler: zipHandler,
            outputDestination: outputDirectory.path,
            outputFileName: "zip-output.plist"
        )
        try zipConverter.run()
        
        // Compare outputs
        let dirOutput = try String(contentsOf: outputDirectory.appendingPathComponent("directory-output.plist"))
        let zipOutput = try String(contentsOf: outputDirectory.appendingPathComponent("zip-output.plist"))
        
        // Outputs should be functionally equivalent (may differ in order)
        let dirSnippetCount = dirOutput.components(separatedBy: "<key>phrase</key>").count - 1
        let zipSnippetCount = zipOutput.components(separatedBy: "<key>phrase</key>").count - 1
        XCTAssertEqual(dirSnippetCount, zipSnippetCount)
        
        // Both should contain the same snippets
        XCTAssertTrue(dirOutput.contains(":testsnippet1"))
        XCTAssertTrue(zipOutput.contains(":testsnippet1"))
        XCTAssertTrue(dirOutput.contains(":testsnippet2"))
        XCTAssertTrue(zipOutput.contains(":testsnippet2"))
    }
    
    func test_inputHandlers_memoryManagement() throws {
        // Test that handlers properly manage resources
        var handlers: [SnippetInputHandler] = []
        
        for _ in 0..<10 {
            try createTestSnippetFiles()
            
            let dirHandler = DirectoryInputHandler(directoryPath: tempDirectory.path)
            let result = try dirHandler.prepareInput()
            XCTAssertNotNil(result)
            
            handlers.append(dirHandler)
            
            // Cleanup
            try dirHandler.cleanup()
        }
        
        // All handlers should still be valid
        XCTAssertEqual(handlers.count, 10)
        
        // Test zip handlers
        let snippetDir = tempDirectory.appendingPathComponent("zip_test")
        try FileManager.default.createDirectory(at: snippetDir, withIntermediateDirectories: true, attributes: nil)
        try createTestSnippetFiles(in: snippetDir)
        try createInfoPlistContent().write(to: snippetDir.appendingPathComponent("info.plist"), atomically: true, encoding: .utf8)
        
        let zipFile = tempDirectory.appendingPathComponent("memory_test.alfredsnippets")
        try createZipFile(from: snippetDir, to: zipFile)
        
        var zipHandlers: [ZipInputHandler] = []
        for _ in 0..<5 {
            let handler = ZipInputHandler(zipFilePath: zipFile.path)
            _ = try handler.prepareInput()
            try handler.cleanup()
            zipHandlers.append(handler)
        }
        
        XCTAssertEqual(zipHandlers.count, 5)
    }
    
    // MARK: - Performance Integration Tests
    
    func test_inputHandlers_performanceWithLargeDataSet() throws {
        // Create a larger dataset
        let largeDir = tempDirectory.appendingPathComponent("large_dataset")
        try FileManager.default.createDirectory(at: largeDir, withIntermediateDirectories: true, attributes: nil)
        
        // Create 100 snippet files
        for i in 0..<100 {
            try createSnippetFile(
                in: largeDir,
                filename: "snippet\(i).json",
                keyword: "test\(i)",
                snippet: "This is test snippet number \(i) with content that varies.",
                name: "Test Snippet \(i)",
                uid: "test-uid-\(i)"
            )
        }
        
        try createInfoPlistContent().write(to: largeDir.appendingPathComponent("info.plist"), atomically: true, encoding: .utf8)
        
        // Test directory handler performance
        let startTime = Date()
        
        let dirHandler = DirectoryInputHandler(directoryPath: largeDir.path)
        let converter = DefaultSnippetConverter(
            inputHandler: dirHandler,
            outputDestination: outputDirectory.path,
            outputFileName: "large-dataset.plist"
        )
        
        try converter.run()
        
        let duration = Date().timeIntervalSince(startTime)
        
        // Should complete within reasonable time (adjust as needed)
        XCTAssertLessThan(duration, 10.0, "Large dataset processing took too long: \(duration) seconds")
        
        // Verify output
        let outputFile = outputDirectory.appendingPathComponent("large-dataset.plist")
        let content = try String(contentsOf: outputFile)
        let snippetCount = content.components(separatedBy: "<key>phrase</key>").count - 1
        XCTAssertEqual(snippetCount, 100)
    }
    
    // MARK: - Helper Methods
    
    private func createTemporaryDirectory() -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let uniqueID = UUID().uuidString
        let tempURL = tempDir.appendingPathComponent("InputHandlerIntegrationTest-\(uniqueID)")
        
        do {
            try FileManager.default.createDirectory(at: tempURL, withIntermediateDirectories: true, attributes: nil)
            return tempURL
        } catch {
            fatalError("Failed to create temporary directory: \(error)")
        }
    }
    
    private func createTestSnippetFiles(in directory: URL? = nil) throws {
        let targetDir = directory ?? tempDirectory!
        let snippets = [
            ("snippet1.json", "hello", "Hello World!", "Greeting", "uid-1"),
            ("snippet2.json", "bye", "Goodbye!", "Farewell", "uid-2")
        ]
        
        for (filename, keyword, snippet, name, uid) in snippets {
            try createSnippetFile(in: targetDir, filename: filename, keyword: keyword, snippet: snippet, name: name, uid: uid)
        }
    }
    
    private func createComplexSnippetFiles() throws {
        let complexSnippets = [
            ("multiline.json", "multiline", "Line 1\nLine 2\nLine 3\n\nParagraph 2", "Multi-line content", "multi-uid"),
            ("special.json", "special", "Special chars: <>&\"'", "Special characters", "special-uid"),
            ("long.json", "longtext", String(repeating: "Lorem ipsum dolor sit amet. ", count: 50), "Long text snippet", "long-uid")
        ]
        
        for (filename, keyword, snippet, name, uid) in complexSnippets {
            try createSnippetFile(in: tempDirectory, filename: filename, keyword: keyword, snippet: snippet, name: name, uid: uid)
        }
    }
    
    private func createSnippetFile(in directory: URL, filename: String, keyword: String, snippet: String, name: String, uid: String) throws {
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
    
    private func createInfoPlistContent() -> String {
        return """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
            <key>bundleid</key>
            <string>com.test.snippets</string>
            <key>createdby</key>
            <string>Test Suite</string>
            <key>description</key>
            <string>Test snippet collection</string>
            <key>name</key>
            <string>Test Snippets</string>
            <key>version</key>
            <string>1.0</string>
        </dict>
        </plist>
        """
    }
    
    private func createZipFile(from sourceDirectory: URL, to destinationZip: URL) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/zip")
        process.arguments = ["-r", "-q", destinationZip.path, "."]
        process.currentDirectoryURL = sourceDirectory
        
        try process.run()
        process.waitUntilExit()
        
        if process.terminationStatus != 0 {
            throw NSError(domain: "ZipError", code: Int(process.terminationStatus), userInfo: [NSLocalizedDescriptionKey: "Failed to create zip file"])
        }
    }
    
    private func countTemporaryDirectories() -> Int {
        let tempDir = FileManager.default.temporaryDirectory
        do {
            let contents = try FileManager.default.contentsOfDirectory(atPath: tempDir.path)
            return contents.filter { $0.hasPrefix("SnippetConverter-") }.count
        } catch {
            return 0
        }
    }
    
    private func createTestDataSet() throws -> (directory: URL, zipFile: URL) {
        let testDir = tempDirectory.appendingPathComponent("test_dataset")
        try FileManager.default.createDirectory(at: testDir, withIntermediateDirectories: true, attributes: nil)
        
        try createSnippetFile(
            in: testDir,
            filename: "snippet1.json",
            keyword: "testsnippet1",
            snippet: "Test snippet 1 content",
            name: "Test Snippet 1",
            uid: "test-1"
        )
        
        try createSnippetFile(
            in: testDir,
            filename: "snippet2.json",
            keyword: "testsnippet2",
            snippet: "Test snippet 2 content",
            name: "Test Snippet 2",
            uid: "test-2"
        )
        
        try createInfoPlistContent().write(to: testDir.appendingPathComponent("info.plist"), atomically: true, encoding: .utf8)
        
        let zipFile = tempDirectory.appendingPathComponent("test_dataset.alfredsnippets")
        try createZipFile(from: testDir, to: zipFile)
        
        return (testDir, zipFile)
    }
}