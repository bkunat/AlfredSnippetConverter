# AlfredSnippetConverter - Comprehensive Test Coverage Improvement Plan

## Current Test Coverage Assessment

### ✅ Well-Tested Components:
- **ZipHandlingTests**: Good coverage of input handling, file detection, and error scenarios
- **Error localization**: All error cases have proper descriptions

### ❌ Critical Gaps in Test Coverage:
- **DefaultSnippetConverter**: Core business logic is completely untested
- **CLI functionality**: No tests for argument parsing or validation
- **ViewModel**: Complex UI business logic lacks any testing
- **JSON parsing**: Snippet decoding/encoding is untested
- **File operations**: Several FileHandler methods lack coverage

### 🔧 Testability Issues:
- **ViewModel**: Tightly coupled to AppKit (NSOpenPanel, NSWorkspace)
- **DefaultSnippetConverter**: Direct file system dependencies
- **FileHandler**: System process execution is hard to mock

## Implementation Plan

### Code Quality Standards
- **Final Classes**: All classes should be marked `final` by default unless inheritance is explicitly required
- **Protocol Organization**: Protocols and their default implementations should be stored in a single file, named after the protocol

### Phase 1: Core Logic Unit Tests (High Priority)
1. **DefaultSnippetConverter Tests**:
   - Test both constructors and initialization paths
   - Test main `run()` method with valid inputs
   - Test `validateOutputFileName()` with valid/invalid extensions
   - Test `checkIfFileExists()` scenarios
   - Test `fetchJSONFileURLs()` with various directory contents
   - Test `decodeSnippet()` with valid/invalid JSON
   - Test `writeSnippets()` and plist generation
   - Test `createSystemSnippet()` XML formatting
   - Test error handling for all failure scenarios

2. **Snippet Model Tests**:
   - Test JSON decoding/encoding with complete data
   - Test handling of missing/invalid fields
   - Test edge cases (empty strings, special characters)

3. **FileHandler Missing Tests**:
   - Test `extractZip()` method (requires refactoring for testability)
   - Test `fileExists()`, `createFile()`, `contentsOfDirectory()`
   - Test FileManager `unzipItem()` extension

### Phase 2: CLI and Integration Tests
4. **CLI Tests**:
   - Test argument parsing with valid/invalid inputs
   - Test `validateInput()` method
   - Integration tests for end-to-end CLI functionality

5. **Input Handler Integration Tests**:
   - Test `ZipInputHandler.validateExtractedContent()`
   - Test complete workflow scenarios

### Phase 3: UI Logic Tests (Requires Refactoring)
6. **ViewModel Refactoring and Tests**:
   - Extract file system operations into testable protocols
   - Add dependency injection for NSOpenPanel/NSWorkspace
   - Test `generateUniqueFileName()` logic
   - Test validation methods (`validateDroppedPath`, etc.)
   - Test conversion workflow methods
   - Test ValidationError scenarios

### Phase 4: Test Infrastructure
7. **Test Data and Helpers**:
   - Create sample Alfred snippet JSON files
   - Create test zip archives
   - Implement test utilities for temporary directories
   - Add mock implementations for system dependencies

### Refactoring for Better Testability
- Extract file system operations into protocols
- Add dependency injection for system services (NSOpenPanel, NSWorkspace)
- Split complex methods into smaller, testable units
- Abstract external process execution (unzip command)
- Apply `final` keyword to all classes unless inheritance is needed
- Reorganize protocol files to include implementations alongside protocols

**Estimated Impact**: ~95% test coverage improvement, significantly enhanced code quality and maintainability.

## Test Naming Convention
All tests should follow the format: `test_whatWeTest_expectedResult`
- Example: `test_snippetConversion_returnsValidOutput`
- Example: `test_invalidJsonFile_throwsDecodingError`