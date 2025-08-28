# Alfred Snippet Converter

Easily convert Alfred Text Snippets into macOS Text Replacements.

<p align="center">
  <img src="https://github.com/bkunat/AlfredSnippetConverter/assets/79861311/2ed1ad8b-febe-4c58-9f0d-00d948fd0674">
</p>

## Features

- Simple conversion of Alfred snippets to macOS format.
- Command Line Interface (CLI) for advanced users.
- User-friendly macOS app for straightforward conversions.

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
   swift run snippet-converter path-to-exported-snippets-collection-from-alfred
   ```
   - Tip: Execute `swift run snippet-converter` to view all available options and arguments.

## Usage

### Exporting Snippets from Alfred

1. [Export](https://www.alfredapp.com/help/features/snippets/#sharing) a Snippets Collection from Alfred.
2. Extract the `.zip` archive using macOS Archive Utility app. 

> Alfred Text Snippets are exported as `.zip` archives.

### Converting with the CLI

Run the following command in the terminal:

```bash
./snippet-converter-cli path-to-exported-snippets-collection-from-alfred
```

### Converting with the macOS App

![header](https://github.com/user-attachments/assets/da493210-5e47-4d09-aca6-d2611a79e513)

1. Open the macOS Snippet Converter app.
2. Select the directory containing the exported Snippets Collection from Alfred.
3. Click "Convert".

<p align="center">
  <img width="640" src="https://github.com/bkunat/AlfredSnippetConverter/assets/79861311/318d42f8-8823-4439-a4cb-60c50c2e5d6e"">
</p>
