import Foundation

public struct Library: Identifiable, Hashable {
    public let id: UUID
    public let name: String
    public let url: URL?
    public let licenseBody: String
    public let version: String

    init(sourcePackagesParserLibrary: SourcePackagesParserLibrary) {
        id = .init()
        name = sourcePackagesParserLibrary.name
        url = URL(string: sourcePackagesParserLibrary.url)
        licenseBody = sourcePackagesParserLibrary.licenseBody
        version = sourcePackagesParserLibrary.version
    }
}

public extension Library {
    static var libraries: [Library] {
        SourcePackagesParserLibrary.allCases.map(Library.init)
    }
}
