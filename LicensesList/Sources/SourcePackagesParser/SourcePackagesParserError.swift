import Foundation

enum SourcePackagesParserError: Error {
    case couldNotReadFile(String)
    case couldNotExportLicensesList
}
