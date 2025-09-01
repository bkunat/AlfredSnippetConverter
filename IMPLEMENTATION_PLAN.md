# Multiple Snippet Collections Implementation Plan

## Overview
Implement support for processing multiple Alfred snippet collections in both CLI and GUI interfaces. This will allow users to select/drop multiple snippet collections (directories or .alfredsnippets files) and convert them in a single operation.

## Architecture Analysis

### Current State
- **CLI**: Accepts single `@Argument snippetExportPath: String`
- **Core**: `DefaultSnippetConverter` processes one input via single `SnippetInputHandler`
- **UI**: `ViewModel.selectedPath: String?` tracks single selection
- **DropZone**: Handles single file/folder drop via `providers.first`

### Target State
- **CLI**: Accept variadic arguments `[String]` with output strategy control
- **Core**: Process multiple inputs with flexible merging/separation options  
- **UI**: Track multiple selections `[String]` with individual management
- **DropZone**: Handle multiple drops with visual feedback for each

## Implementation Strategy

### Phase 1: Core Architecture Changes

#### 1.1 New Multi-Input Converter
**File**: `Packages/Sources/SnippetConverterCore/MultiSnippetConverter.swift`
```swift
public struct MultiSnippetConverter: SnippetConverter {
    private let inputPaths: [String]
    private let outputStrategy: OutputStrategy
    private let outputDestination: String
    private let outputFileName: String
    
    public enum OutputStrategy {
        case merge(fileName: String)
        case separate(baseFileName: String) // Generates multiple files
    }
}
```

#### 1.2 Enhanced Input Handler Factory
**File**: `Packages/Sources/SnippetConverterCore/SnippetInputHandlerFactory.swift`
```swift
public struct SnippetInputHandlerFactory {
    public static func createHandlers(from paths: [String]) throws -> [SnippetInputHandler]
    public static func validateInputs(_ paths: [String]) throws
}
```

#### 1.3 Collection Metadata Support
**File**: `Packages/Sources/SnippetConverterCore/CollectionMetadata.swift`
```swift
public struct CollectionMetadata {
    let sourcePath: String
    let collectionName: String
    let snippetCount: Int
}
```

### Phase 2: CLI Implementation

#### 2.1 CLI Argument Changes
**File**: `Packages/Sources/SnippetConverterCLI/SnippetConverterCLI.swift`

**Current:**
```swift
@Argument(help: "The directory containing JSON files...")
var snippetExportPath: String
```

**New:**
```swift
@Argument(help: "One or more directories or .alfredsnippets files")
var snippetExportPaths: [String]

@Option(name: .long, help: "Output strategy: 'merge' or 'separate'")
var outputStrategy: OutputStrategyOption = .merge

@Flag(name: .long, help: "Add collection name prefix to snippets")
var addCollectionPrefix: Bool = false
```

#### 2.2 Enhanced Validation
- Validate all input paths before processing
- Check for duplicate paths
- Ensure output strategy compatibility

### Phase 3: UI Implementation

#### 3.1 ViewModel Changes
**File**: `SnippetConverter/ViewModel.swift`

**Current:**
```swift
@Published var selectedPath: String?
```

**New:**
```swift
@Published var selectedPaths: [SelectedCollection] = []

public struct SelectedCollection: Identifiable, Equatable {
    let id = UUID()
    let path: String
    let displayName: String
    let type: InputType
    let snippetCount: Int?
}
```

#### 3.2 DropZone UI Enhancement
**File**: `SnippetConverter/DropZoneView.swift`

**Changes:**
- Handle multiple drops in single operation
- Show list of selected collections
- Allow individual collection removal
- Support mixed collection types (directories + zip files)

**New UI Structure:**
```
┌─ Drop Zone (when empty) ─────────────────┐
│  📁 Drop Multiple Snippet Collections    │
│     Folders or .alfredsnippets files     │
│           Or click to browse             │
└─────────────────────────────────────────┘

┌─ Selected Collections ──────────────────┐
│ ✅ Alfred Snippets Folder 1    [Remove] │
│ ✅ MySnippets.alfredsnippets   [Remove] │  
│ ✅ Work Snippets Folder        [Remove] │
│                                [+ Add]   │
└─────────────────────────────────────────┘
```

#### 3.3 Collection Management UI
**File**: `SnippetConverter/CollectionListView.swift` (new)
- Display selected collections with metadata
- Individual remove buttons
- Drag-to-reorder support
- Collection validation indicators

### Phase 4: Output Strategy Implementation

#### 4.1 Merge Strategy
- Combine all snippets from all collections into single plist
- Optional: Add collection name prefix to snippet keywords
- Handle duplicate keywords across collections

#### 4.2 Separate Strategy  
- Generate one plist file per collection
- Use collection name or path-based naming
- Batch processing with progress indication

#### 4.3 Collection Naming
- Directory collections: Use folder name
- Zip collections: Use filename without extension
- Duplicate name resolution with numeric suffixes

### Phase 5: Testing Strategy

#### 5.1 CLI Tests
**File**: `Packages/Tests/SnippetConverterCLITests/MultiInputCLITests.swift`
- Test variadic argument parsing
- Test output strategy options
- Test validation with multiple invalid inputs
- Test mixed input types (directories + zip files)

#### 5.2 Core Tests
**File**: `Packages/Tests/SnippetConverterCoreTests/MultiSnippetConverterTests.swift`
- Test merge strategy with multiple collections
- Test separate strategy output generation
- Test collection metadata extraction
- Test error handling with partial failures

#### 5.3 UI Tests
**File**: `SnippetConverterTests/MultiSelectionTests.swift`
- Test multiple file selection in picker
- Test multiple drag & drop operations
- Test collection list management
- Test validation display for multiple inputs

### Phase 6: Integration & Refinement

#### 6.1 Backward Compatibility
- Ensure single-collection workflows continue working
- Maintain existing API for single input scenarios
- Preserve current CLI argument behavior for single inputs

#### 6.2 Error Handling Enhancement
- Partial failure scenarios (some collections valid, others not)
- Progress reporting for multiple collections
- Rollback on failure with cleanup

#### 6.3 Performance Considerations
- Parallel processing of multiple collections where safe
- Memory management for large collection sets
- Progress indication for long-running operations

## Implementation Order

1. **Core Multi-Input Support** (Phase 1)
   - Create `MultiSnippetConverter`
   - Add input validation for multiple paths
   - Implement merge strategy

2. **CLI Multi-Input** (Phase 2)  
   - Update CLI argument parsing
   - Add output strategy options
   - Update validation logic

3. **Basic UI Multi-Selection** (Phase 3.1-3.2)
   - Update ViewModel for multiple selections
   - Basic DropZone multi-drop support
   - Simple list display

4. **Enhanced UI** (Phase 3.3)
   - Advanced collection management
   - Better visual feedback
   - Individual collection controls

5. **Advanced Features** (Phase 4)
   - Separate output strategy
   - Collection naming/prefixing
   - Advanced merge options

6. **Testing & Polish** (Phase 5-6)
   - Comprehensive test coverage
   - Performance optimization
   - Error handling refinement

## Key Design Decisions

### Decision 1: Output Strategy Default
**Choice**: Default to merge strategy with single output file
**Rationale**: Simpler for most users, matches current single-collection behavior

### Decision 2: CLI Backward Compatibility  
**Choice**: Maintain support for single argument while adding array support
**Rationale**: Existing scripts and workflows should continue working

### Decision 3: UI Collection Display
**Choice**: Show list of collections with individual controls vs. summary view
**Rationale**: Users need visibility into what's selected and ability to fine-tune

### Decision 4: Collection Naming
**Choice**: Use filesystem names (folder/file names) as collection identifiers
**Rationale**: Most intuitive for users, matches file system mental model

### Decision 5: Error Handling
**Choice**: Fail fast - validate all inputs before processing any
**Rationale**: Better user experience than partial failures mid-processing

## Risk Mitigation

### Risk 1: Breaking Changes
**Mitigation**: Extensive backward compatibility testing, gradual rollout

### Risk 2: Complex UI State Management
**Mitigation**: Clear separation of concerns, comprehensive state validation

### Risk 3: Performance with Large Collections
**Mitigation**: Progress indication, memory profiling, incremental processing

### Risk 4: File System Edge Cases
**Mitigation**: Robust path validation, comprehensive error handling tests

## Success Criteria

1. **CLI**: `swift run snippet-converter collection1/ collection2.alfredsnippets collection3/`
2. **UI**: Drag multiple collections → see them listed → convert all at once
3. **Output**: Single merged plist contains all snippets from all collections
4. **Testing**: All existing tests pass + new multi-collection test coverage
5. **Performance**: No significant slowdown for single-collection scenarios

## Estimated Effort

- **Phase 1-2 (Core + CLI)**: ~2-3 days
- **Phase 3 (Basic UI)**: ~2-3 days  
- **Phase 4 (Advanced Features)**: ~1-2 days
- **Phase 5-6 (Testing + Polish)**: ~2-3 days

**Total**: ~7-11 days of development time