# Alfred Snippet Converter - Zipped Archive Support Specification

## Overview

This specification outlines the implementation plan to add support for zipped Alfred snippet archives (`.alfredsnippets` files) to the existing SnippetConverter project, while maintaining full backward compatibility with unzipped directory formats.

## Current State Analysis

### Existing Architecture
- **Core Logic**: `SnippetConverterCore` package handles conversion from JSON files to plist format
- **Input Format**: Currently supports only unzipped directories containing individual `.json` files
- **Processing Flow**: `DefaultSnippetConverter` → reads directory → fetches JSON files → processes snippets
- **File Structure**: Each snippet is a separate `.json` file with `alfredsnippet` object containing `snippet`, `uid`, `name`, `keyword`
- **Metadata**: `info.plist` contains snippet configuration (prefix/suffix settings)

### Target Formats
1. **Unzipped Format** (current): Directory with `.json` files + `info.plist`
2. **Zipped Format** (new): `.alfredsnippets` files (ZIP archives containing same structure as unzipped)

## Implementation Plan

### 1. Core Architecture Changes

#### 1.1 Create Input Handler Abstraction
**File**: `Packages/Sources/SnippetConverterCore/SnippetInputHandler.swift`

```swift
public protocol SnippetInputHandler {
    func prepareInput() throws -> URL  // Returns directory URL to process
    func cleanup() throws             // Cleanup any temporary resources
}

public class DirectoryInputHandler: SnippetInputHandler {
    // Existing directory handling logic
}

public class ZipInputHandler: SnippetInputHandler {
    // New zip extraction logic
}
```

#### 1.2 Temporary Directory Management
- **Location**: Use `FileManager.default.temporaryDirectory`
- **Unique Path**: Create UUID-based subdirectory for each extraction
- **Cleanup**: Explicit cleanup after processing, don't rely solely on system
- **Error Handling**: Robust cleanup in error scenarios

#### 1.3 Zip Detection and Extraction
**File**: `Packages/Sources/SnippetConverterCore/FileHandler.swift`

Add methods:
```swift
static func isZipFile(at path: String) -> Bool
static func extractZip(from sourcePath: String, to destinationPath: String) throws
static func createTemporaryDirectory() throws -> URL
static func removeDirectory(at url: URL) throws
```

### 2. File-Specific Changes

#### 2.1 DefaultSnippetConverter.swift
- Refactor constructor to accept input handler instead of direct path
- Update `fetchJSONFileURLs()` to work with input handler
- Add cleanup logic in `run()` method
- Maintain backward compatibility with existing API

#### 2.2 SnippetConverterError.swift
Add new error cases:
```swift
case invalidZipFile(filePath: String)
case zipExtractionFailed(error: Error)
case temporaryDirectoryCreationFailed
case cleanupFailed(error: Error)
case unsupportedInputFormat
```

#### 2.3 SnippetConverterCLI.swift
- Update argument validation to accept both directories and `.alfredsnippets` files
- Add file type detection logic
- Create appropriate input handler based on input type

#### 2.4 GUI Components

**ViewModel.swift**:
- Update `validateDroppedPath()` to accept both directories and `.alfredsnippets` files
- Add file extension validation for `.alfredsnippets`
- Update error messages to reflect both supported formats

**DropZoneView.swift**:
- Update UI text to mention both formats
- Update file type validation in drop handler

### 3. Implementation Details

#### 3.1 File Detection Logic
```swift
func determineInputType(_ path: String) -> InputType {
    let url = URL(fileURLWithPath: path)
    
    if url.pathExtension.lowercased() == "alfredsnippets" {
        return .zipFile
    } else if FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory) && isDirectory.boolValue {
        return .directory
    } else {
        return .unsupported
    }
}
```

#### 3.2 Zip Extraction Process
1. Validate zip file integrity
2. Create unique temporary directory
3. Extract zip contents to temporary location
4. Validate extracted contents (has JSON files and info.plist)
5. Return temporary directory path for processing
6. Schedule cleanup after processing

#### 3.3 Error Handling Strategy
- **Corrupted zips**: Clear error message with file path
- **Extraction failures**: Include underlying system error
- **Cleanup failures**: Log but don't block main operation
- **Invalid content**: Validate extracted directory has expected structure

### 4. Testing Strategy

#### 4.1 Unit Tests (SnippetConverterCoreTests)
**File**: `Packages/Tests/SnippetConverterCoreTests/ZipHandlingTests.swift`

Test cases:
- `test_zipFileDetection_identifiesValidZipFiles`
- `test_zipExtraction_extractsValidArchive`
- `test_zipExtraction_handlesCorruptedFiles`
- `test_temporaryDirectory_createsUniqueLocations`
- `test_cleanup_removesTemporaryFiles`
- `test_endToEndConversion_fromZipToOutput`
- `test_errorHandling_invalidZipFile`
- `test_errorHandling_extractionFailure`

#### 4.2 Integration Tests (SnippetConverterTests)
**File**: `SnippetConverterTests/ZipIntegrationTests.swift`

Test cases:
- `test_guiDropZone_acceptsZipFiles`
- `test_cliExecution_processesZipFiles`
- `test_validation_rejectsInvalidFormats`

#### 4.3 Test Resources
Create test zip files:
- Valid `.alfredsnippets` file with sample snippets
- Corrupted zip file for error testing
- Empty zip file
- Zip file with invalid internal structure

### 5. Backward Compatibility

#### 5.1 API Compatibility
- Existing `DefaultSnippetConverter` constructor remains unchanged
- New constructor overload accepts input handler
- All existing method signatures preserved
- No breaking changes to public API

#### 5.2 Behavior Compatibility
- Directory processing logic unchanged
- Output format identical
- Error messages for directory issues unchanged
- CLI argument parsing maintains existing behavior for directories

### 6. Dependencies

#### 6.1 System Frameworks
- **Foundation**: For FileManager, URL, and zip handling
- **Compression**: Consider using if Foundation's built-in zip handling is insufficient

#### 6.2 No New External Dependencies
- Leverage Swift's built-in zip capabilities through Foundation
- No need for third-party zip libraries

### 7. Implementation Order

1. **Phase 1**: Core infrastructure
   - Create `SnippetInputHandler` protocol
   - Implement `DirectoryInputHandler` with existing logic
   - Update `FileHandler` with zip utilities

2. **Phase 2**: Zip handling
   - Implement `ZipInputHandler`
   - Add temporary directory management
   - Implement zip extraction logic

3. **Phase 3**: Integration
   - Update `DefaultSnippetConverter` to use input handlers
   - Update CLI to detect and handle zip files
   - Update GUI validation and error handling

4. **Phase 4**: Testing and validation
   - Implement comprehensive test suite
   - Test with real Alfred snippet archives
   - Validate error handling scenarios

### 8. Success Criteria

#### 8.1 Functional Requirements
- [ ] App accepts `.alfredsnippets` files via CLI argument
- [ ] App accepts `.alfredsnippets` files via GUI drag-and-drop
- [ ] Zip files extract correctly to temporary directory
- [ ] Extracted content processes identically to directory input
- [ ] Temporary files clean up properly
- [ ] All existing directory functionality preserved

#### 8.2 Quality Requirements
- [ ] Comprehensive error handling for all zip-related operations
- [ ] Unit test coverage >95% for new code
- [ ] No memory leaks or file handle leaks
- [ ] Proper cleanup in all error scenarios
- [ ] Clear, actionable error messages for users

#### 8.3 Performance Requirements
- [ ] Zip extraction time <5 seconds for typical Alfred archives
- [ ] No significant performance impact on existing directory processing
- [ ] Efficient temporary file cleanup

## Technical Notes

### File Validation Strategy
Both input types should contain:
- Multiple `.json` files with valid snippet structure
- `info.plist` with snippet configuration
- Valid JSON structure in all snippet files

### Security Considerations
- Validate zip contents before extraction
- Limit extraction path depth to prevent zip bombs
- Use secure temporary directory creation
- Proper file permissions on extracted content

### Platform Support
- **macOS 13.0+**: Primary target for GUI application
- **macOS 14.0+**: For test execution environment
- **Swift 5.9+**: Leveraging modern Swift features

## Future Enhancements (Out of Scope)

- Support for other Alfred export formats
- Compression ratio optimization for output
- Batch processing of multiple archives
- GUI preview of archive contents before conversion

---

**Last Updated**: August 14, 2025  
**Version**: 1.0  
**Status**: Ready for Implementation