import XCTest
@testable import SnippetConverterCore
import Foundation

final class FileHandlerTests: XCTestCase {
    
    private var tempDirectory: URL!
    
    override func setUp() {
        super.setUp()
        tempDirectory = createTemporaryDirectory()
    }
    
    override func tearDown() {
        super.tearDown()
        try? FileManager.default.removeItem(at: tempDirectory)
    }
    
    // MARK: - fileExists Tests
    
    func test_fileExists_returnsTrue_forExistingFile() {
        let testFile = tempDirectory.appendingPathComponent("test.txt")
        FileManager.default.createFile(atPath: testFile.path, contents: Data())
        
        let result = FileHandler.fileExists(at: testFile)
        
        XCTAssertTrue(result)
    }
    
    func test_fileExists_returnsTrue_forExistingDirectory() {
        let testDir = tempDirectory.appendingPathComponent("testdir")
        try! FileManager.default.createDirectory(at: testDir, withIntermediateDirectories: true, attributes: nil)
        
        let result = FileHandler.fileExists(at: testDir)
        
        XCTAssertTrue(result)
    }
    
    func test_fileExists_returnsFalse_forNonexistentFile() {
        let nonexistentFile = tempDirectory.appendingPathComponent("nonexistent.txt")
        
        let result = FileHandler.fileExists(at: nonexistentFile)
        
        XCTAssertFalse(result)
    }
    
    func test_fileExists_returnsFalse_forNonexistentDirectory() {
        let nonexistentDir = tempDirectory.appendingPathComponent("nonexistentdir")
        
        let result = FileHandler.fileExists(at: nonexistentDir)
        
        XCTAssertFalse(result)
    }
    
    // MARK: - createFile Tests
    
    func test_createFile_createsEmptyFile_atSpecifiedPath() {
        let testFile = tempDirectory.appendingPathComponent("newfile.txt")
        
        FileHandler.createFile(at: testFile)
        
        XCTAssertTrue(FileManager.default.fileExists(atPath: testFile.path))
        
        let fileSize = try! FileManager.default.attributesOfItem(atPath: testFile.path)[.size] as! UInt64
        XCTAssertEqual(fileSize, 0)
    }
    
    func test_createFile_overwritesExistingFile() {
        let testFile = tempDirectory.appendingPathComponent("existing.txt")
        
        // Create file with content
        try! "Original content".write(to: testFile, atomically: true, encoding: .utf8)
        XCTAssertTrue(FileManager.default.fileExists(atPath: testFile.path))
        
        // Overwrite with empty file
        FileHandler.createFile(at: testFile)
        
        XCTAssertTrue(FileManager.default.fileExists(atPath: testFile.path))
        
        let fileSize = try! FileManager.default.attributesOfItem(atPath: testFile.path)[.size] as! UInt64
        XCTAssertEqual(fileSize, 0)
    }
    
    func test_createFile_createsFileInNestedDirectory() {
        let nestedDir = tempDirectory.appendingPathComponent("nested").appendingPathComponent("deep")
        try! FileManager.default.createDirectory(at: nestedDir, withIntermediateDirectories: true, attributes: nil)
        
        let testFile = nestedDir.appendingPathComponent("nested.txt")
        
        FileHandler.createFile(at: testFile)
        
        XCTAssertTrue(FileManager.default.fileExists(atPath: testFile.path))
    }
    
    // MARK: - contentsOfDirectory Tests
    
    func test_contentsOfDirectory_returnsEmptyArray_forEmptyDirectory() throws {
        let emptyDir = tempDirectory.appendingPathComponent("empty")
        try FileManager.default.createDirectory(at: emptyDir, withIntermediateDirectories: true, attributes: nil)
        
        let contents = try FileHandler.contentsOfDirectory(atPath: emptyDir.path)
        
        XCTAssertEqual(contents.count, 0)
    }
    
    func test_contentsOfDirectory_returnsFileNames_forDirectoryWithFiles() throws {
        let testDir = tempDirectory.appendingPathComponent("testdir")
        try FileManager.default.createDirectory(at: testDir, withIntermediateDirectories: true, attributes: nil)
        
        // Create test files
        let file1 = testDir.appendingPathComponent("file1.txt")
        let file2 = testDir.appendingPathComponent("file2.json")
        let file3 = testDir.appendingPathComponent("file3.log")
        
        FileManager.default.createFile(atPath: file1.path, contents: Data())
        FileManager.default.createFile(atPath: file2.path, contents: Data())
        FileManager.default.createFile(atPath: file3.path, contents: Data())
        
        let contents = try FileHandler.contentsOfDirectory(atPath: testDir.path)
        
        XCTAssertEqual(contents.count, 3)
        XCTAssertTrue(contents.contains("file1.txt"))
        XCTAssertTrue(contents.contains("file2.json"))
        XCTAssertTrue(contents.contains("file3.log"))
    }
    
    func test_contentsOfDirectory_includesSubdirectories() throws {
        let testDir = tempDirectory.appendingPathComponent("testdir")
        try FileManager.default.createDirectory(at: testDir, withIntermediateDirectories: true, attributes: nil)
        
        // Create files and subdirectories
        let file = testDir.appendingPathComponent("file.txt")
        let subdir1 = testDir.appendingPathComponent("subdir1")
        let subdir2 = testDir.appendingPathComponent("subdir2")
        
        FileManager.default.createFile(atPath: file.path, contents: Data())
        try FileManager.default.createDirectory(at: subdir1, withIntermediateDirectories: true, attributes: nil)
        try FileManager.default.createDirectory(at: subdir2, withIntermediateDirectories: true, attributes: nil)
        
        let contents = try FileHandler.contentsOfDirectory(atPath: testDir.path)
        
        XCTAssertEqual(contents.count, 3)
        XCTAssertTrue(contents.contains("file.txt"))
        XCTAssertTrue(contents.contains("subdir1"))
        XCTAssertTrue(contents.contains("subdir2"))
    }
    
    func test_contentsOfDirectory_throwsError_forNonexistentDirectory() {
        let nonexistentDir = tempDirectory.appendingPathComponent("nonexistent")
        
        XCTAssertThrowsError(try FileHandler.contentsOfDirectory(atPath: nonexistentDir.path)) { error in
            XCTAssertTrue(error is CocoaError)
        }
    }
    
    func test_contentsOfDirectory_throwsError_forFile() {
        let testFile = tempDirectory.appendingPathComponent("notadirectory.txt")
        FileManager.default.createFile(atPath: testFile.path, contents: Data())
        
        XCTAssertThrowsError(try FileHandler.contentsOfDirectory(atPath: testFile.path)) { error in
            XCTAssertTrue(error is CocoaError)
        }
    }
    
    func test_contentsOfDirectory_handlesHiddenFiles() throws {
        let testDir = tempDirectory.appendingPathComponent("testdir")
        try FileManager.default.createDirectory(at: testDir, withIntermediateDirectories: true, attributes: nil)
        
        // Create visible and hidden files
        let visibleFile = testDir.appendingPathComponent("visible.txt")
        let hiddenFile = testDir.appendingPathComponent(".hidden.txt")
        
        FileManager.default.createFile(atPath: visibleFile.path, contents: Data())
        FileManager.default.createFile(atPath: hiddenFile.path, contents: Data())
        
        let contents = try FileHandler.contentsOfDirectory(atPath: testDir.path)
        
        XCTAssertEqual(contents.count, 2)
        XCTAssertTrue(contents.contains("visible.txt"))
        XCTAssertTrue(contents.contains(".hidden.txt"))
    }
    
    // MARK: - isZipFile Enhanced Tests
    
    func test_isZipFile_returnsFalse_forDirectory() {
        let testDir = tempDirectory.appendingPathComponent("testdir")
        try! FileManager.default.createDirectory(at: testDir, withIntermediateDirectories: true, attributes: nil)
        
        let result = FileHandler.isZipFile(at: testDir.path)
        
        XCTAssertFalse(result)
    }
    
    func test_isZipFile_returnsFalse_forNonexistentFile() {
        let nonexistentFile = tempDirectory.appendingPathComponent("nonexistent.alfredsnippets")
        
        let result = FileHandler.isZipFile(at: nonexistentFile.path)
        
        XCTAssertFalse(result)
    }
    
    func test_isZipFile_returnsFalse_forEmptyFile() {
        let emptyFile = tempDirectory.appendingPathComponent("empty.alfredsnippets")
        FileManager.default.createFile(atPath: emptyFile.path, contents: Data())
        
        let result = FileHandler.isZipFile(at: emptyFile.path)
        
        XCTAssertFalse(result)
    }
    
    func test_isZipFile_returnsFalse_forFileWithInsufficientBytes() {
        let smallFile = tempDirectory.appendingPathComponent("small.alfredsnippets")
        let smallData = Data([0x01, 0x02]) // Only 2 bytes
        try! smallData.write(to: smallFile)
        
        let result = FileHandler.isZipFile(at: smallFile.path)
        
        XCTAssertFalse(result)
    }
    
    func test_isZipFile_returnsFalse_forFileWithWrongSignature() {
        let wrongFile = tempDirectory.appendingPathComponent("wrong.alfredsnippets")
        let wrongData = Data([0xFF, 0xFF, 0xFF, 0xFF]) // Wrong signature
        try! wrongData.write(to: wrongFile)
        
        let result = FileHandler.isZipFile(at: wrongFile.path)
        
        XCTAssertFalse(result)
    }
    
    func test_isZipFile_returnsTrue_forValidZipSignature() {
        let zipFile = tempDirectory.appendingPathComponent("valid.alfredsnippets")
        let zipData = Data([0x50, 0x4B, 0x03, 0x04, 0x00, 0x00]) // Valid ZIP signature + extra bytes
        try! zipData.write(to: zipFile)
        
        let result = FileHandler.isZipFile(at: zipFile.path)
        
        XCTAssertTrue(result)
    }
    
    func test_isZipFile_returnsTrue_forAlternativeZipSignatures() {
        // Test different valid ZIP signatures
        let signatures: [(String, [UInt8])] = [
            ("local_file_header", [0x50, 0x4B, 0x03, 0x04]),  // PK\003\004
            ("central_dir_end", [0x50, 0x4B, 0x05, 0x06]),    // PK\005\006
            ("data_descriptor", [0x50, 0x4B, 0x07, 0x08])     // PK\007\008
        ]
        
        for (name, signature) in signatures {
            let testFile = tempDirectory.appendingPathComponent("\(name).alfredsnippets")
            let testData = Data(signature + [0x00, 0x00]) // Add extra bytes
            try! testData.write(to: testFile)
            
            let result = FileHandler.isZipFile(at: testFile.path)
            
            XCTAssertTrue(result, "Failed for signature: \(name)")
        }
    }
    
    func test_isZipFile_supportsRegularZipExtension() {
        let zipFile = tempDirectory.appendingPathComponent("test.zip")
        let zipData = Data([0x50, 0x4B, 0x03, 0x04, 0x00, 0x00])
        try! zipData.write(to: zipFile)
        
        let result = FileHandler.isZipFile(at: zipFile.path)
        
        XCTAssertTrue(result)
    }
    
    // MARK: - extractZip Tests (Mock/Integration Tests)
    
    func test_extractZip_throwsError_forNonexistentSourceFile() {
        let nonexistentSource = tempDirectory.appendingPathComponent("nonexistent.alfredsnippets")
        let destination = tempDirectory.appendingPathComponent("destination")
        try! FileManager.default.createDirectory(at: destination, withIntermediateDirectories: true, attributes: nil)
        
        XCTAssertThrowsError(try FileHandler.extractZip(from: nonexistentSource.path, to: destination.path)) { error in
            XCTAssertTrue(error is NSError)
        }
    }
    
    func test_extractZip_throwsError_forInvalidZipFile() {
        let invalidZip = tempDirectory.appendingPathComponent("invalid.alfredsnippets")
        try! "This is not a zip file".write(to: invalidZip, atomically: true, encoding: .utf8)
        
        let destination = tempDirectory.appendingPathComponent("destination")
        try! FileManager.default.createDirectory(at: destination, withIntermediateDirectories: true, attributes: nil)
        
        XCTAssertThrowsError(try FileHandler.extractZip(from: invalidZip.path, to: destination.path)) { error in
            XCTAssertTrue(error is NSError)
            let nsError = error as! NSError
            XCTAssertEqual(nsError.domain, "UnzipError")
        }
    }
    
    func test_extractZip_throwsError_forNonexistentDestination() {
        // Create a minimal zip file for testing
        let testZip = tempDirectory.appendingPathComponent("test.alfredsnippets")
        let zipData = Data([0x50, 0x4B, 0x05, 0x06] + Array(repeating: 0x00, count: 18)) // Minimal empty ZIP
        try! zipData.write(to: testZip)
        
        let nonexistentDestination = "/this/path/should/not/exist"
        
        XCTAssertThrowsError(try FileHandler.extractZip(from: testZip.path, to: nonexistentDestination)) { error in
            XCTAssertTrue(error is NSError)
        }
    }
    
    // MARK: - Integration Tests for createTemporaryDirectory and removeDirectory
    
    func test_temporaryDirectoryLifecycle_createAndRemove() throws {
        let tempDir = try FileHandler.createTemporaryDirectory()
        
        // Verify directory was created
        XCTAssertTrue(FileManager.default.fileExists(atPath: tempDir.path))
        
        // Add some content to make sure removal works with content
        let testFile = tempDir.appendingPathComponent("test.txt")
        FileManager.default.createFile(atPath: testFile.path, contents: "test content".data(using: .utf8))
        
        let subDir = tempDir.appendingPathComponent("subdir")
        try FileManager.default.createDirectory(at: subDir, withIntermediateDirectories: true, attributes: nil)
        
        // Remove directory
        try FileHandler.removeDirectory(at: tempDir)
        
        // Verify directory was removed
        XCTAssertFalse(FileManager.default.fileExists(atPath: tempDir.path))
    }
    
    func test_createTemporaryDirectory_createsUniqueDirectories() throws {
        let dir1 = try FileHandler.createTemporaryDirectory()
        let dir2 = try FileHandler.createTemporaryDirectory()
        let dir3 = try FileHandler.createTemporaryDirectory()
        
        defer {
            try? FileHandler.removeDirectory(at: dir1)
            try? FileHandler.removeDirectory(at: dir2)
            try? FileHandler.removeDirectory(at: dir3)
        }
        
        // Verify all directories are different
        XCTAssertNotEqual(dir1.path, dir2.path)
        XCTAssertNotEqual(dir2.path, dir3.path)
        XCTAssertNotEqual(dir1.path, dir3.path)
        
        // Verify all exist
        XCTAssertTrue(FileManager.default.fileExists(atPath: dir1.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: dir2.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: dir3.path))
    }
    
    func test_removeDirectory_throwsError_forNonexistentDirectory() {
        let nonexistentDir = tempDirectory.appendingPathComponent("nonexistent")
        
        XCTAssertThrowsError(try FileHandler.removeDirectory(at: nonexistentDir)) { error in
            XCTAssertTrue(error is CocoaError)
        }
    }
    
    // MARK: - Helper Methods
    
    private func createTemporaryDirectory() -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let uniqueID = UUID().uuidString
        let tempURL = tempDir.appendingPathComponent("FileHandlerTest-\(uniqueID)")
        
        do {
            try FileManager.default.createDirectory(at: tempURL, withIntermediateDirectories: true, attributes: nil)
            return tempURL
        } catch {
            fatalError("Failed to create temporary directory: \(error)")
        }
    }
}