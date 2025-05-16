import Foundation
import PackagePlugin

@main
struct PrepareLicensesList: BuildToolPlugin {
    struct SourcePackagesNotFoundError: Error & CustomStringConvertible {
        let description: String = "SourcePackages not found"
    }

    func existsSourcePackages(in url: URL) throws -> Bool {
        guard url.isFileURL,
              url.pathComponents.count > 1,
              let isDirectory = try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory
        else {
            throw SourcePackagesNotFoundError()
        }

        let existsSourcePackagesInDirectory = FileManager.default
            .fileExists(atPath: url.appending(path: "SourcePackages").path())

        return isDirectory && existsSourcePackagesInDirectory
    }

    func sourcePackages(_ pluginWorkDirectory: URL) throws -> URL {
        var tmpURL = pluginWorkDirectory.absoluteURL

        while try !existsSourcePackages(in: tmpURL) {
            tmpURL.deleteLastPathComponent()
        }

        tmpURL.append(path: "SourcePackages")

        return tmpURL
    }

    func makeBuildCommand(executableURL: URL, sourcePackagesURL: URL, outputURL: URL) -> Command {
        .buildCommand(
            displayName: "Prepare LicensesList",
            executable: executableURL,
            arguments: [
                outputURL.absoluteURL.path(),
                sourcePackagesURL.absoluteURL.path()
            ],
            outputFiles: [
                outputURL
            ]
        )
    }

    func createBuildCommands(context: PluginContext, target: Target) async throws -> [Command] {
        try [
            makeBuildCommand(
                executableURL: context.tool(named: "SourcePackagesParser").url,
                sourcePackagesURL: sourcePackages(context.pluginWorkDirectoryURL),
                outputURL: context.pluginWorkDirectoryURL.appending(path: "LicensesList.swift")
            )
        ]
    }
}
