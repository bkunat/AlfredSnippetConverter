import Foundation
import Compression

struct FileHandler {
    static func fileExists(at url: URL) -> Bool {
        return FileManager.default.fileExists(atPath: url.path)
    }

    static func createFile(at url: URL) {
        FileManager.default.createFile(atPath: url.path, contents: nil)
    }

    static func contentsOfDirectory(atPath path: String) throws -> [String] {
        return try FileManager.default.contentsOfDirectory(atPath: path)
    }
    
    static func isZipFile(at path: String) -> Bool {
        let url = URL(fileURLWithPath: path)
        let pathExtension = url.pathExtension.lowercased()
        
        guard pathExtension == "alfredsnippets" || pathExtension == "zip" else {
            return false
        }
        
        guard let fileHandle = FileHandle(forReadingAtPath: path) else {
            return false
        }
        
        defer { fileHandle.closeFile() }
        
        let data = fileHandle.readData(ofLength: 4)
        guard data.count >= 4 else { return false }
        
        let signature = data.withUnsafeBytes { bytes in
            bytes.bindMemory(to: UInt32.self).first ?? 0
        }
        
        // Check for ZIP file signatures: 0x504B0304 (PK\003\004) or 0x504B0506 (PK\005\006) or 0x504B0708 (PK\007\008)
        return signature == 0x04034B50 || signature == 0x06054B50 || signature == 0x08074B50
    }
    
    static func extractZip(from sourcePath: String, to destinationPath: String) throws {
        let sourceURL = URL(fileURLWithPath: sourcePath)
        let destinationURL = URL(fileURLWithPath: destinationPath)
        
        try FileManager.default.unzipItem(at: sourceURL, to: destinationURL)
    }
    
    static func createTemporaryDirectory() throws -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let uniqueID = UUID().uuidString
        let tempURL = tempDir.appendingPathComponent("SnippetConverter-\(uniqueID)")
        
        do {
            try FileManager.default.createDirectory(at: tempURL, withIntermediateDirectories: true, attributes: nil)
            return tempURL
        } catch {
            throw SnippetConverterError.temporaryDirectoryCreationFailed
        }
    }
    
    static func removeDirectory(at url: URL) throws {
        try FileManager.default.removeItem(at: url)
    }
}

extension FileManager {
    func unzipItem(at sourceURL: URL, to destinationURL: URL) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/unzip")
        process.arguments = ["-q", sourceURL.path, "-d", destinationURL.path]
        
        let pipe = Pipe()
        process.standardError = pipe
        
        try process.run()
        process.waitUntilExit()
        
        if process.terminationStatus != 0 {
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown unzip error"
            throw NSError(domain: "UnzipError", code: Int(process.terminationStatus), userInfo: [NSLocalizedDescriptionKey: errorMessage])
        }
    }
}
