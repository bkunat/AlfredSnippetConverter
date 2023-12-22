import Foundation

struct FileHandler {
    static let fileManager = FileManager.default

    static func fileExists(at url: URL) -> Bool {
        return fileManager.fileExists(atPath: url.path)
    }

    static func createFile(at url: URL) {
        fileManager.createFile(atPath: url.path, contents: nil)
    }

    static func contentsOfDirectory(atPath path: String) throws -> [String] {
        return try fileManager.contentsOfDirectory(atPath: path)
    }
}
