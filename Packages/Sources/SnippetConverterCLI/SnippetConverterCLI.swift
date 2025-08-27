@preconcurrency import ArgumentParser
import Foundation
import SnippetConverterCore

@main
struct SnippetConverter: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "A utility for converting Alfred text snippets")

    @Argument(
        help: "The directory containing JSON files exported from Alfred, or an .alfredsnippets file.")
    var snippetExportPath: String

    @Option(name: .long, help: "The output path for the plist file. Defaults to `~/Desktop`.")
    var outputDestination = "~/Desktop/"

    @Option(name: .long, help: "The name of the output file.")
    var outputFileName = "snippet-converter-output.plist"

    func run() throws {
        try validateInput()

        let snippetConverter = SnippetConverterCore.DefaultSnippetConverter(
            snippetExportPath: snippetExportPath,
            outputDestination: outputDestination,
            outputFileName: outputFileName)
        try snippetConverter.run()
    }

    func validateInput() throws {
        let inputType = SnippetConverterCore.determineInputType(snippetExportPath)

        switch inputType {
        case .directory, .zipFile:
            break
        case .unsupported:
            throw ValidationError(
                "Invalid input: '\(snippetExportPath)'. Please provide a directory containing JSON files or an .alfredsnippets file.")
        }
    }
}
