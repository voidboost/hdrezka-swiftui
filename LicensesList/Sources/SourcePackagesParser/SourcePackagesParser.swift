import Foundation

final class SourcePackagesParser {
    let outputURL: URL
    let sourcePackagesURL: URL

    init(_ outputPath: String, _ sourcePackagesPath: String) {
        outputURL = URL(filePath: outputPath)
        sourcePackagesURL = URL(filePath: sourcePackagesPath)
    }

    func run() throws {
        let workspaceStateURL = sourcePackagesURL.appending(path: "workspace-state.json")

        guard let data = try? Data(contentsOf: workspaceStateURL),
              let workspaceState = try? JSONDecoder().decode(WorkspaceState.self, from: data)
        else {
            throw SourcePackagesParserError.couldNotReadFile(workspaceStateURL.lastPathComponent)
        }

        let checkoutsURL = sourcePackagesURL.appending(path: "checkouts")
        let libraries: [Library] = workspaceState.object.dependencies.compactMap { dependency in
            guard let repositoryName = dependency.packageRef.location
                .components(separatedBy: "/").filter({ !$0.isEmpty }).last?
                .replacingOccurrences(of: ".git", with: "")
            else {
                return nil
            }

            let directoryURL = checkoutsURL.appending(path: repositoryName)

            guard let licenseBody = extractLicenseBody(directoryURL) else {
                return nil
            }

            return Library(
                name: dependency.packageRef.name,
                url: dependency.packageRef.location.replacingOccurrences(of: ".git", with: ""),
                licenseBody: licenseBody,
                version: dependency.state.checkoutState.version,
                identity: dependency.packageRef.identity.components(separatedBy: .letters.inverted).filter { !$0.isEmpty }.joined(separator: "_"),
            )
        }
        .sorted { $0.name.lowercased() < $1.name.lowercased() }

        try exportLicensesList(libraries)
    }

    private func extractLicenseBody(_ directoryURL: URL) -> String? {
        let fileManager = FileManager.default
        let contents = (try? fileManager.contentsOfDirectory(atPath: directoryURL.path())) ?? []
        let licenseURL = contents
            .map { directoryURL.appending(path: $0) }
            .filter { contentURL in
                let fileName = contentURL.deletingPathExtension().lastPathComponent.lowercased()
                guard ["license", "licence"].contains(fileName) else {
                    return false
                }
                var isDirectory: ObjCBool = false
                fileManager.fileExists(atPath: contentURL.path(), isDirectory: &isDirectory)
                return isDirectory.boolValue == false
            }
            .first

        guard let licenseURL, let text = try? String(contentsOf: licenseURL, encoding: .utf8) else {
            return nil
        }

        return text
    }

    private func printLibraries(_ libraries: [Library]) {
        let length = libraries.map(\.name.count).max() ?? .zero

        for library in libraries {
            print(library.name.padding(toLength: length, withPad: " ", startingAt: .zero))
        }
    }

    private func makeCases(_ libraries: [Library]) -> String {
        libraries
            .map { "case \($0.identity)" }
            .joined(separator: "\n")
    }

    private func makeComputedProperty(
        _ libraries: [Library],
        variableName: String,
        keyPath: KeyPath<Library, String>,
    ) -> String {
        let cases = libraries
            .map { "case .\($0.identity): \($0[keyPath: keyPath].debugDescription)" }
            .joined(separator: "\n")
        let switchSelf = "switch self {\n\(cases)\n}".nest()

        return "var \(variableName): String {\n\(switchSelf)\n}"
    }

    private func exportLicensesList(_ libraries: [Library]) throws {
        var text = ""

        if libraries.isEmpty {
            print("Warning: No libraries.")
        } else {
            printLibraries(libraries)
            text = [
                makeCases(libraries),
                makeComputedProperty(libraries, variableName: "name", keyPath: \.name),
                makeComputedProperty(libraries, variableName: "url", keyPath: \.url),
                makeComputedProperty(libraries, variableName: "licenseBody", keyPath: \.licenseBody),
                makeComputedProperty(libraries, variableName: "version", keyPath: \.version),
            ].joined(separator: "\n\n")
        }

        text = "import Foundation\n\nenum SourcePackagesParserLibrary: CaseIterable {\n\(text.nest())\n}\n"

        if FileManager.default.fileExists(atPath: outputURL.path()) {
            try FileManager.default.removeItem(at: outputURL)
        }

        do {
            try text.data(using: .utf8)?.write(to: outputURL)
        } catch {
            throw SourcePackagesParserError.couldNotExportLicensesList
        }
    }
}
