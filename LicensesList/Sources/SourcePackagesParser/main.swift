import Foundation

func exitWithUsage() -> Never {
    print("USAGE: swift run SourcePackagesParser [output directory path] [SourcePackages directory path]")

    exit(1)
}

func exitWithSourcePackagesParserError(_ sourcePackagesParserError: SourcePackagesParserError) -> Never {
    switch sourcePackagesParserError {
    case let .couldNotReadFile(fileName):
        print("Error: Could not read \(fileName).")
    case .couldNotExportLicensesList:
        print("Error: Could not export LicensesList.swift.")
    }

    exit(1)
}

func main() {
    guard CommandLine.arguments.count == 3 else {
        exitWithUsage()
    }

    let outputPath = CommandLine.arguments[1]
    let sourcePackagesPath = CommandLine.arguments[2]

    do {
        try SourcePackagesParser(outputPath, sourcePackagesPath).run()
    } catch {
        if let sourcePackagesParserError = error as? SourcePackagesParserError {
            exitWithSourcePackagesParserError(sourcePackagesParserError)
        }
    }
}

main()
