# CLAUDE.md - AlfredSnippetConverter Project Guidelines

## Project Overview
This is a macOS project built with Xcode using Swift and SwiftUI. The project consists of a macOS app and a Swift Package Manager (SPM) package with CLI tools for converting Alfred snippets.

## Prerequisites
- Xcode installed
- Swift Package Manager
- macOS development certificate (for code signing)

## Build and Run Commands

### Build the App
```bash
xcodebuild -project SnippetConverter.xcodeproj -scheme SnippetConverter -destination 'platform=macOS' clean build
```

### Run Tests
```bash
# Run unit tests only (UI tests are empty - skip them to save time)
xcodebuild -project SnippetConverter.xcodeproj -scheme SnippetConverterTests test > test_output.log 2>&1 && echo "✅ UNIT TESTS PASSED" || echo "❌ UNIT TESTS FAILED - Check test_output.log"

# Run Swift Package Manager tests (SnippetConverterCore package)
cd Packages && swift test
```

### Build CLI Tool
```bash
cd Packages && swift build
```

### Run CLI Tool
```bash
cd Packages && swift run snippet-converter --help
```

## Testing Rules

### Unit Testing Guidelines
- **Don't write unit tests unless specifically asked to**
- All test names should follow the format: `test_whatWeTest_expectedResult`
- Example: `test_snippetConversion_returnsValidOutput`

## Project Structure
- **Main App**: `SnippetConverter/` - SwiftUI macOS application
- **Core Logic**: `Packages/Sources/SnippetConverterCore/` - Core conversion logic
- **CLI Tool**: `Packages/Sources/SnippetConverterCLI/` - Command-line interface
- **Tests**: 
  - `SnippetConverterTests/` - Xcode unit tests for the main app
  - `SnippetConverterUITests/` - Xcode UI tests (currently empty - skip to save time)
  - `Packages/Tests/` - SPM tests for the core package

## Common Issues
- **Code Signing**: Ensure proper development certificate is configured in Xcode
- **Package Dependencies**: The project uses Swift Argument Parser (1.3.0) for CLI functionality
- **Dual Build System**: Project uses both Xcode project files and SPM - prefer SPM for package development

## Dependency Management
- **NEVER update Swift Package dependencies by hand** unless user specifies that a dependency has been added to the project locally
- Current dependencies: `swift-argument-parser @ 1.3.0`
- Only update dependencies when explicitly requested by the user

## Pull Request Format
When preparing PR descriptions, use this format:

```markdown
## Changes
- List all introduced changes. Be brief and direct

## Notes
- List all things worth mentioning to the person who's going to review your code.
```

## Project Configuration
- **Main Scheme**: `SnippetConverter` (for macOS app)
- **Package Schemes**: `SnippetConverterCore`, `SnippetConverterCLI`, `snippet-converter`
- **Platform**: macOS 13.0+ (for app), macOS 14.0+ (for tests)
- **Bundle ID**: `com.bkunat.SnippetConverter`

## Workflow Summary
1. Make your changes to the appropriate target (App or Package)
2. For app changes: Run `xcodebuild -project SnippetConverter.xcodeproj -scheme SnippetConverter -destination 'platform=macOS' clean build` to verify the app builds
3. For package changes: Run `cd Packages && swift build` to verify package builds
4. Run tests to verify they pass:
   - App unit tests: Use the unit tests command from "Run Tests" section (skip UI tests - they're empty)
   - Package tests: Use `cd Packages && swift test`
5. Test CLI functionality: `cd Packages && swift run snippet-converter --help`

## Development Notes
- The app uses SwiftUI for the macOS interface
- Core business logic is separated into the SnippetConverterCore package
- CLI tool provides command-line access to the same core functionality
- Project follows standard Swift/SwiftUI conventions and patterns

## Project Features & Architecture
- **Dual Input Support**: Accepts both Alfred snippet directories and `.alfredsnippets` zip files
- **Input Handler Pattern**: Uses `SnippetInputHandler` protocol with `DirectoryInputHandler` and `ZipInputHandler` implementations
- **Automatic Input Detection**: `determineInputType()` function identifies directory vs zip file vs unsupported formats
- **Temporary File Management**: Zip extraction uses unique temporary directories with proper cleanup
- **Full Backward Compatibility**: All existing directory-based workflows preserved
- **Comprehensive Error Handling**: Custom `SnippetConverterError` cases for zip operations

## Build Dependencies & Issues
- **Xcode vs SPM**: Package builds reliably with `swift build`, but app may have module import issues in Xcode
- **Testing Strategy**: SPM tests (`swift test`) are comprehensive and reliable - prefer them for validation
- **File Type Validation**: Uses both file extension (.alfredsnippets) and binary signature checking for zip detection
- **macOS System Integration**: Utilizes `/usr/bin/unzip` for extraction to avoid third-party dependencies