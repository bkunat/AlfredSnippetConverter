import XCTest
@testable import SnippetConverterCore
import Foundation

final class ZipHandlingTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    // MARK: - File Detection Tests
    
    func test_determineInputType_identifiesDirectory() {
        let tempDir = createTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: tempDir) }
        
        let result = determineInputType(tempDir.path)
        XCTAssertEqual(result, .directory)
    }
    
    func test_determineInputType_identifiesZipFile() {
        let tempDir = createTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: tempDir) }
        
        let zipFile = tempDir.appendingPathComponent("test.alfredsnippets")
        FileManager.default.createFile(atPath: zipFile.path, contents: Data())
        
        let result = determineInputType(zipFile.path)
        XCTAssertEqual(result, .zipFile)
    }
    
    func test_determineInputType_identifiesUnsupportedFormat() {
        let tempDir = createTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: tempDir) }
        
        let textFile = tempDir.appendingPathComponent("test.txt")
        FileManager.default.createFile(atPath: textFile.path, contents: Data())
        
        let result = determineInputType(textFile.path)
        XCTAssertEqual(result, .unsupported)
    }
    
    // MARK: - DirectoryInputHandler Tests
    
    func test_directoryInputHandler_preparesValidDirectory() throws {
        let tempDir = createTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: tempDir) }
        
        let handler = DirectoryInputHandler(directoryPath: tempDir.path)
        let result = try handler.prepareInput()
        
        XCTAssertEqual(result.path, tempDir.path)
    }
    
    func test_directoryInputHandler_throwsForNonexistentDirectory() {
        let nonexistentPath = "/path/that/does/not/exist"
        let handler = DirectoryInputHandler(directoryPath: nonexistentPath)
        
        XCTAssertThrowsError(try handler.prepareInput()) { error in
            if case SnippetConverterError.directoryNotFound(let path) = error {
                XCTAssertEqual(path, nonexistentPath)
            } else {
                XCTFail("Expected directoryNotFound error, got \(error)")
            }
        }
    }
    
    func test_directoryInputHandler_throwsForFile() throws {
        let tempDir = createTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: tempDir) }
        
        let textFile = tempDir.appendingPathComponent("test.txt")
        FileManager.default.createFile(atPath: textFile.path, contents: Data())
        
        let handler = DirectoryInputHandler(directoryPath: textFile.path)
        
        XCTAssertThrowsError(try handler.prepareInput()) { error in
            XCTAssertTrue(error is SnippetConverterError)
        }
    }
    
    // MARK: - ZipInputHandler Tests
    
    func test_zipInputHandler_throwsForNonexistentFile() {
        let nonexistentPath = "/path/that/does/not/exist.alfredsnippets"
        let handler = ZipInputHandler(zipFilePath: nonexistentPath)
        
        XCTAssertThrowsError(try handler.prepareInput()) { error in
            if case SnippetConverterError.zipFileNotFound(let path) = error {
                XCTAssertEqual(path, nonexistentPath)
            } else {
                XCTFail("Expected zipFileNotFound error, got \(error)")
            }
        }
    }
    
    // MARK: - FileHandler Tests
    
    func test_fileHandler_isZipFile_returnsFalseForNonZipFile() {
        let tempDir = createTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: tempDir) }
        
        let textFile = tempDir.appendingPathComponent("test.txt")
        FileManager.default.createFile(atPath: textFile.path, contents: "Hello World".data(using: .utf8))
        
        let result = FileHandler.isZipFile(at: textFile.path)
        XCTAssertFalse(result)
    }
    
    func test_fileHandler_isZipFile_returnsFalseForInvalidExtension() {
        let tempDir = createTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: tempDir) }
        
        let textFile = tempDir.appendingPathComponent("test.txt")
        FileManager.default.createFile(atPath: textFile.path, contents: Data())
        
        let result = FileHandler.isZipFile(at: textFile.path)
        XCTAssertFalse(result)
    }
    
    func test_fileHandler_createTemporaryDirectory_createsUniqueDirectories() throws {
        let dir1 = try FileHandler.createTemporaryDirectory()
        let dir2 = try FileHandler.createTemporaryDirectory()
        
        defer {
            try? FileHandler.removeDirectory(at: dir1)
            try? FileHandler.removeDirectory(at: dir2)
        }
        
        XCTAssertNotEqual(dir1.path, dir2.path)
        XCTAssertTrue(FileManager.default.fileExists(atPath: dir1.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: dir2.path))
    }
    
    func test_fileHandler_removeDirectory_removesDirectory() throws {
        let tempDir = try FileHandler.createTemporaryDirectory()
        
        XCTAssertTrue(FileManager.default.fileExists(atPath: tempDir.path))
        
        try FileHandler.removeDirectory(at: tempDir)
        
        XCTAssertFalse(FileManager.default.fileExists(atPath: tempDir.path))
    }
    
    // MARK: - Error Handling Tests
    
    func test_snippetConverterError_localization() {
        let errors: [SnippetConverterError] = [
            .invalidZipFile(filePath: "/test/path"),
            .zipExtractionFailed(error: NSError(domain: "test", code: 1)),
            .temporaryDirectoryCreationFailed,
            .cleanupFailed(error: NSError(domain: "test", code: 1)),
            .unsupportedInputFormat,
            .directoryNotFound(path: "/test/path"),
            .zipFileNotFound(path: "/test/path"),
            .invalidArchiveContent(reason: "test reason")
        ]
        
        for error in errors {
            XCTAssertNotNil(error.errorDescription, "Error \(error) should have a description")
            XCTAssertFalse(error.errorDescription!.isEmpty, "Error description should not be empty")
        }
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
}