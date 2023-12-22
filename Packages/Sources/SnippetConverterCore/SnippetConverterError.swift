import Foundation

enum SnippetConverterError: Error {
    case fileAlreadyExists(filePath: String)
    case invalidOutputFileType
    case invalidData
}

extension SnippetConverterError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .fileAlreadyExists(let path):
            return NSLocalizedString("\"\(path)\" already exists.", comment: "File already exists error")
        case .invalidOutputFileType:
            return NSLocalizedString("Outpu file must be of type `.plist`.", comment: "Invalid output file type")
        case .invalidData:
            return NSLocalizedString("Exported data has an invalid format.", comment: "Invalid data")
        }
    }
}
