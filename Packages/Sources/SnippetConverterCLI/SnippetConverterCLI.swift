import ArgumentParser
import Foundation
import SnippetConverterCore

public enum OutputStrategyOption: String, CaseIterable, ExpressibleByArgument {
    case merge
    case separate
    
    public static var allValueStrings: [String] {
        return Self.allCases.map { $0.rawValue }
    }
}

@main
struct SnippetConverter: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "A utility for converting Alfred text snippets")

    @Argument(
        help: "One or more directories containing JSON files exported from Alfred, or .alfredsnippets files.")
    var snippetExportPaths: [String]

    @Option(name: .long, help: "The output path for the plist file. Defaults to `~/Desktop`.")
    var outputDestination = "~/Desktop/"

    @Option(name: .long, help: "The name of the output file.")
    var outputFileName = "snippet-converter-output.plist"
    
    @Option(name: .long, help: "Output strategy: 'merge' (combine all into one file) or 'separate' (create individual files)")
    var outputStrategy: OutputStrategyOption = .merge
    
    @Flag(name: .long, help: "Add collection name prefix to snippet keywords in merge mode")
    var addCollectionPrefix: Bool = false

    func run() throws {
        try validateInputs()

        if snippetExportPaths.count == 1 {
            // Use single-input converter for backward compatibility
            let snippetConverter = SnippetConverterCore.DefaultSnippetConverter(
                snippetExportPath: snippetExportPaths[0],
                outputDestination: outputDestination,
                outputFileName: outputFileName)
            try snippetConverter.run()
        } else {
            // Use multi-input converter
            let strategy: SnippetConverterCore.MultiSnippetConverter.OutputStrategy
            
            switch outputStrategy {
            case .merge:
                strategy = .merge(fileName: outputFileName)
            case .separate:
                strategy = .separate(baseFileName: outputFileName)
            }
            
            let multiConverter = SnippetConverterCore.MultiSnippetConverter(
                inputPaths: snippetExportPaths,
                outputStrategy: strategy,
                outputDestination: outputDestination,
                outputFileName: outputFileName)
            try multiConverter.run()
        }
    }

    func validateInputs() throws {
        guard !snippetExportPaths.isEmpty else {
            throw ValidationError("No input paths provided. Please specify one or more directories or .alfredsnippets files.")
        }
        
        for path in snippetExportPaths {
            let inputType = SnippetConverterCore.determineInputType(path)

            switch inputType {
            case .directory, .zipFile:
                break
            case .unsupported:
                throw ValidationError(
                    "Invalid input: '\(path)'. Please provide a directory containing JSON files or an .alfredsnippets file.")
            }
        }
    }
}
