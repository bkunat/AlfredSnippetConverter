import Foundation

enum SnippetConverterError: Error, Equatable {
    case fileAlreadyExists(filePath: String)
    case invalidOutputFileType
    case invalidData
    case invalidZipFile(filePath: String)
    case zipExtractionFailed(error: Error)
    case temporaryDirectoryCreationFailed
    case cleanupFailed(error: Error)
    case unsupportedInputFormat
    case directoryNotFound(path: String)
    case zipFileNotFound(path: String)
    case invalidArchiveContent(reason: String)
    case noInputPathsProvided
    case duplicateInputPaths
    
    static func == (lhs: SnippetConverterError, rhs: SnippetConverterError) -> Bool {
        switch (lhs, rhs) {
        case (.fileAlreadyExists(let lhsPath), .fileAlreadyExists(let rhsPath)):
            return lhsPath == rhsPath
        case (.invalidOutputFileType, .invalidOutputFileType):
            return true
        case (.invalidData, .invalidData):
            return true
        case (.invalidZipFile(let lhsPath), .invalidZipFile(let rhsPath)):
            return lhsPath == rhsPath
        case (.zipExtractionFailed(let lhsError), .zipExtractionFailed(let rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
        case (.temporaryDirectoryCreationFailed, .temporaryDirectoryCreationFailed):
            return true
        case (.cleanupFailed(let lhsError), .cleanupFailed(let rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
        case (.unsupportedInputFormat, .unsupportedInputFormat):
            return true
        case (.directoryNotFound(let lhsPath), .directoryNotFound(let rhsPath)):
            return lhsPath == rhsPath
        case (.zipFileNotFound(let lhsPath), .zipFileNotFound(let rhsPath)):
            return lhsPath == rhsPath
        case (.invalidArchiveContent(let lhsReason), .invalidArchiveContent(let rhsReason)):
            return lhsReason == rhsReason
        case (.noInputPathsProvided, .noInputPathsProvided):
            return true
        case (.duplicateInputPaths, .duplicateInputPaths):
            return true
        default:
            return false
        }
    }
}

extension SnippetConverterError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .fileAlreadyExists(let path):
            return NSLocalizedString("\"\(path)\" already exists.", comment: "File already exists error")
        case .invalidOutputFileType:
            return NSLocalizedString("Output file must be of type `.plist`.", comment: "Invalid output file type")
        case .invalidData:
            return NSLocalizedString("Exported data has an invalid format.", comment: "Invalid data")
        case .invalidZipFile(let filePath):
            return NSLocalizedString("Invalid or corrupted zip file: \"\(filePath)\"", comment: "Invalid zip file error")
        case .zipExtractionFailed(let error):
            return NSLocalizedString("Failed to extract zip file: \(error.localizedDescription)", comment: "Zip extraction failed error")
        case .temporaryDirectoryCreationFailed:
            return NSLocalizedString("Failed to create temporary directory for extraction.", comment: "Temporary directory creation failed error")
        case .cleanupFailed(let error):
            return NSLocalizedString("Failed to clean up temporary files: \(error.localizedDescription)", comment: "Cleanup failed error")
        case .unsupportedInputFormat:
            return NSLocalizedString("Unsupported input format. Please provide a directory or .alfredsnippets file.", comment: "Unsupported input format error")
        case .directoryNotFound(let path):
            return NSLocalizedString("Directory not found: \"\(path)\"", comment: "Directory not found error")
        case .zipFileNotFound(let path):
            return NSLocalizedString("Zip file not found: \"\(path)\"", comment: "Zip file not found error")
        case .invalidArchiveContent(let reason):
            return NSLocalizedString("Invalid archive content: \(reason)", comment: "Invalid archive content error")
        case .noInputPathsProvided:
            return NSLocalizedString("No input paths provided. Please specify one or more directories or .alfredsnippets files.", comment: "No input paths provided error")
        case .duplicateInputPaths:
            return NSLocalizedString("Duplicate input paths provided. Please ensure all paths are unique.", comment: "Duplicate input paths error")
        }
    }
}
