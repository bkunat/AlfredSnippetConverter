import ArgumentParser
import Foundation
import SnippetConverterCore

@main
struct SnippetConverter: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "A utility for converting Alfred text snippets")

    @Argument(help: "The directory containing the JSON files exported from Alfred.")
    var snippetExportPath: String

    @Option(name: .long, help: "The output path for the plist file. Defaults to `~/Desktop`.")
    var outputDestination: String = "~/Desktop/"

    @Option(name: .long, help: "The name of the output file.")
    var outputFileName = "snippet-converter-output.plist"

    func run() throws {
        let snippetConverter = SnippetConverterCore.DefaultSnippetConverter(
            snippetExportPath: snippetExportPath,
            outputDestination: outputDestination,
            outputFileName: outputFileName)
        try snippetConverter.run()
    }
}
