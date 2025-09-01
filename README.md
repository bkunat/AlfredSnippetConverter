# Alfred Snippet Converter

Easily convert Alfred Text Snippets into macOS Text Replacements.

<p align="center">
  <img src="https://github.com/bkunat/AlfredSnippetConverter/assets/79861311/2ed1ad8b-febe-4c58-9f0d-00d948fd0674">
</p>

## Features

- **Multiple Collection Processing**: Convert multiple Alfred snippet collections in a single operation
- **Flexible Output Strategies**: 
  - **Merge**: Combine all collections into a single plist file with collection prefixes
  - **Separate**: Generate individual plist files for each collection
- **Dual Input Support**: Process both exported snippet directories and `.alfredsnippets` zip files
- **CLI**: Support for multiple inputs with output strategy control

## Requirements

- macOS 13 (Ventura)

## Getting Started

You can either build the project from source using Xcode or download one of the pre-built packages from the Releases tab.

### Building CLI from the Command Line

1. Navigate to the project's package directory:
   ```bash
   cd Packages
   ```
2. Build and run the snippet converter:
   ```bash
   # Single collection
   swift run snippet-converter path-to-exported-snippets-collection-from-alfred
   ```
   
   - Tip: Execute `swift run snippet-converter --help` to view all available options and arguments.

## Usage

### Exporting Snippets from Alfred

1. [Export](https://www.alfredapp.com/help/features/snippets/#sharing) a Snippets Collection from Alfred.
2. Use the exported `.alfredsnippets` file directly, or extract the archive to get a directory.

> Alfred Text Snippets are exported as `.alfredsnippets` zip archives. The converter supports both the zip files and extracted directories.

### Converting with the CLI

The CLI supports both single and multiple collection processing:

```bash
# Single collection (backward compatible)
./snippet-converter-cli path-to-exported-snippets-collection-from-alfred

# Multiple collections - merge into single file (default)
./snippet-converter-cli work-snippets/ personal.alfredsnippets team-snippets/

# Multiple collections - create separate files
./snippet-converter-cli work-snippets/ personal.alfredsnippets --output-strategy separate

# Add collection prefixes to snippet keywords
./snippet-converter-cli work-snippets/ personal.alfredsnippets --add-collection-prefix
```

### Converting with the macOS App

1. Open the macOS Snippet Converter app.
2. Either:
   - **Drag and drop** your `.alfredsnippets` file or extracted directory into the app
   - **Click to browse** and select your snippets file or directory
3. Click "Convert".

![header](https://github.com/user-attachments/assets/da493210-5e47-4d09-aca6-d2611a79e513)
