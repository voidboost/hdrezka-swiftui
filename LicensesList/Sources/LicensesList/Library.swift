import Foundation

public struct Library: Identifiable, Hashable {
    public let id: UUID
    public let name: String
    public let url: URL?
    public let licenseBody: String
    public let version: String

    init(sourcePackagesParserLibrary: SourcePackagesParserLibrary) {
        self.id = .init()
        self.name = sourcePackagesParserLibrary.name
        self.url = URL(string: sourcePackagesParserLibrary.url)
        self.licenseBody = sourcePackagesParserLibrary.licenseBody
        self.version = sourcePackagesParserLibrary.version
    }
}

public extension Library {
    static var libraries: [Library] {
        SourcePackagesParserLibrary.allCases.map(Library.init)
    }
}
