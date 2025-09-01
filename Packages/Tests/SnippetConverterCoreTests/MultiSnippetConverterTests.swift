import XCTest
@testable import SnippetConverterCore

final class MultiSnippetConverterTests: XCTestCase {
    private var tempDirectory: URL!
    private var testCollection1: URL!
    private var testCollection2: URL!
    private var outputDirectory: URL!
    
    override func setUp() {
        super.setUp()
        
        tempDirectory = createTemporaryDirectory()
        testCollection1 = tempDirectory.appendingPathComponent("Collection1")
        testCollection2 = tempDirectory.appendingPathComponent("Collection2")
        outputDirectory = tempDirectory.appendingPathComponent("Output")
        
        try! FileManager.default.createDirectory(at: testCollection1, withIntermediateDirectories: true)
        try! FileManager.default.createDirectory(at: testCollection2, withIntermediateDirectories: true)
        try! FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)
    }
    
    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDirectory)
        super.tearDown()
    }
    
    func test_multiSnippetConverter_throwsErrorForEmptyInputPaths() {
        let converter = MultiSnippetConverter(
            inputPaths: [],
            outputStrategy: .merge(fileName: "test.plist"),
            outputDestination: outputDirectory.path,
            outputFileName: "test.plist"
        )
        
        XCTAssertThrowsError(try converter.run()) { error in
            XCTAssertEqual(error as? SnippetConverterError, .noInputPathsProvided)
        }
    }
    
    func test_multiSnippetConverter_mergeStrategy_combinesMultipleCollections() throws {
        // Create test snippets in collection 1
        let snippet1 = createTestSnippet(keyword: "test1", snippet: "Test snippet 1")
        let snippet1Data = try JSONEncoder().encode(["alfredsnippet": snippet1])
        let snippet1File = testCollection1.appendingPathComponent("test1.json")
        try snippet1Data.write(to: snippet1File)
        
        // Create test snippets in collection 2
        let snippet2 = createTestSnippet(keyword: "test2", snippet: "Test snippet 2")
        let snippet2Data = try JSONEncoder().encode(["alfredsnippet": snippet2])
        let snippet2File = testCollection2.appendingPathComponent("test2.json")
        try snippet2Data.write(to: snippet2File)
        
        let outputFile = "merged.plist"
        let converter = MultiSnippetConverter(
            inputPaths: [testCollection1.path, testCollection2.path],
            outputStrategy: .merge(fileName: outputFile),
            outputDestination: outputDirectory.path,
            outputFileName: "unused.plist"
        )
        
        try converter.run()
        
        let outputPath = outputDirectory.appendingPathComponent(outputFile)
        XCTAssertTrue(FileManager.default.fileExists(atPath: outputPath.path))
        
        let outputContent = try String(contentsOf: outputPath)
        XCTAssertTrue(outputContent.contains("Test snippet 1"))
        XCTAssertTrue(outputContent.contains("Test snippet 2"))
        XCTAssertTrue(outputContent.contains(":Collection1_test1"))
        XCTAssertTrue(outputContent.contains(":Collection2_test2"))
    }
    
    func test_multiSnippetConverter_separateStrategy_createsIndividualFiles() throws {
        // Create test snippets in collection 1
        let snippet1 = createTestSnippet(keyword: "test1", snippet: "Test snippet 1")
        let snippet1Data = try JSONEncoder().encode(["alfredsnippet": snippet1])
        let snippet1File = testCollection1.appendingPathComponent("test1.json")
        try snippet1Data.write(to: snippet1File)
        
        // Create test snippets in collection 2
        let snippet2 = createTestSnippet(keyword: "test2", snippet: "Test snippet 2")
        let snippet2Data = try JSONEncoder().encode(["alfredsnippet": snippet2])
        let snippet2File = testCollection2.appendingPathComponent("test2.json")
        try snippet2Data.write(to: snippet2File)
        
        let baseFileName = "separate.plist"
        let converter = MultiSnippetConverter(
            inputPaths: [testCollection1.path, testCollection2.path],
            outputStrategy: .separate(baseFileName: baseFileName),
            outputDestination: outputDirectory.path,
            outputFileName: "unused.plist"
        )
        
        try converter.run()
        
        let outputFile1 = outputDirectory.appendingPathComponent("separate-Collection1.plist")
        let outputFile2 = outputDirectory.appendingPathComponent("separate-Collection2.plist")
        
        XCTAssertTrue(FileManager.default.fileExists(atPath: outputFile1.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: outputFile2.path))
        
        let outputContent1 = try String(contentsOf: outputFile1)
        let outputContent2 = try String(contentsOf: outputFile2)
        
        XCTAssertTrue(outputContent1.contains("Test snippet 1"))
        XCTAssertFalse(outputContent1.contains("Test snippet 2"))
        
        XCTAssertTrue(outputContent2.contains("Test snippet 2"))
        XCTAssertFalse(outputContent2.contains("Test snippet 1"))
    }
    
    func test_snippetInputHandlerFactory_validateInputs_detectsDuplicatePaths() {
        let paths = [testCollection1.path, testCollection1.path]
        
        XCTAssertThrowsError(try SnippetInputHandlerFactory.validateInputs(paths)) { error in
            XCTAssertEqual(error as? SnippetConverterError, .duplicateInputPaths)
        }
    }
    
    func test_snippetInputHandlerFactory_createHandlers_returnsCorrectHandlers() throws {
        let paths = [testCollection1.path, testCollection2.path]
        let handlers = try SnippetInputHandlerFactory.createHandlers(from: paths)
        
        XCTAssertEqual(handlers.count, 2)
        XCTAssertTrue(handlers[0] is DirectoryInputHandler)
        XCTAssertTrue(handlers[1] is DirectoryInputHandler)
    }
    
    func test_collectionMetadata_createsCorrectMetadata() throws {
        // Create test snippet
        let snippet = createTestSnippet(keyword: "test", snippet: "Test snippet")
        let snippetData = try JSONEncoder().encode(["alfredsnippet": snippet])
        let snippetFile = testCollection1.appendingPathComponent("test.json")
        try snippetData.write(to: snippetFile)
        
        let handler = DirectoryInputHandler(directoryPath: testCollection1.path)
        let metadata = try CollectionMetadata.create(from: testCollection1.path, handler: handler)
        
        XCTAssertEqual(metadata.collectionName, "Collection1")
        XCTAssertEqual(metadata.snippetCount, 1)
        XCTAssertEqual(metadata.sourcePath, testCollection1.path)
    }
    
    private func createTemporaryDirectory() -> URL {
        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory())
        let uniqueURL = tempURL.appendingPathComponent(UUID().uuidString)
        try! FileManager.default.createDirectory(at: uniqueURL, withIntermediateDirectories: true)
        return uniqueURL
    }
    
    private func createTestSnippet(keyword: String, snippet: String) -> Alfredsnippet {
        return Alfredsnippet(snippet: snippet, uid: UUID().uuidString, name: keyword, keyword: keyword)
    }
}