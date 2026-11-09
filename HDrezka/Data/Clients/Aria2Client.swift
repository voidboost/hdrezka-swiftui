import Alamofire
import Defaults
import Dependencies
import DependenciesMacros
import Foundation

@DependencyClient
struct Aria2Client {
    var start: @Sendable () throws -> Void
    var waitUntilExit: @Sendable () async -> Void
    var terminate: @Sendable () -> Void
    var addUri: @Sendable (_ uris: [URL], _ directory: URL, _ fileName: String) async throws -> String
    var statuses: @Sendable () async throws -> [StatusResult]
    var pause: @Sendable (_ gid: String) async throws -> Void
    var unpause: @Sendable (_ gid: String) async throws -> Void
    var remove: @Sendable (_ gid: String) async throws -> Void
    var removeDownloadResult: @Sendable (_ gid: String) async throws -> Void
    var setMaxConcurrentDownloads: @Sendable (_ count: Int) async throws -> Void
}

extension Aria2Client: DependencyKey {
    static let liveValue: Self = {
        @Dependency(\.session) var session

        let process = Process()
        let (exits, exited) = AsyncStream.makeStream(of: Void.self)

        process.terminationHandler = { _ in
            exited.finish()
        }

        return Self(
            start: {
                #if arch(arm64)
                    let executableURL = Bundle.main.url(forResource: "aria2c-arm64", withExtension: nil)
                #elseif arch(x86_64)
                    let executableURL = Bundle.main.url(forResource: "aria2c-x86_64", withExtension: nil)
                #else
                    let executableURL: URL? = nil
                #endif

                guard let executableURL else {
                    throw HDrezkaError.null("aria2c", #line, #column)
                }

                process.executableURL = executableURL
                process.arguments = [
                    "--enable-rpc=true",
                    "--rpc-listen-port=\(Const.rpcPort)",
                    "--rpc-secret=\(Const.token)",
                    "--min-split-size=1M",
                    "--max-connection-per-server=16",
                    "--split=16",
                    "--max-concurrent-downloads=\(Defaults[.maxConcurrentDownloads])",
                    "--allow-overwrite=true",
                    "--stop-with-process=\(ProcessInfo.processInfo.processIdentifier)",
                    "--quiet=true",
                    "--no-conf",
                    "--user-agent=\(Const.userAgent)",
                ]

                try process.run()
            },
            waitUntilExit: {
                for await _ in exits {}
            },
            terminate: {
                guard process.isRunning else { return }

                process.terminate()
            },
            addUri: { uris, directory, fileName in
                try await session.aria2(
                    .addUri,
                    AddUriParams(
                        token: Const.token,
                        uris: uris.map(\.absoluteString),
                        options: [
                            "dir": directory.path(percentEncoded: false),
                            "out": fileName,
                        ],
                    ),
                )
            },
            statuses: {
                let keys = ["gid", "status", "totalLength", "completedLength", "downloadSpeed", "errorCode"]

                let responses: [Aria2Response<[StatusResult]>] = try await session.aria2([
                    Aria2Request(method: .tellActive, params: OffsetParams(token: Const.token, keys: keys)),
                    Aria2Request(method: .tellWaiting, params: OffsetParams(token: Const.token, offset: 0, num: 1000, keys: keys)),
                    Aria2Request(method: .tellStopped, params: OffsetParams(token: Const.token, offset: 0, num: 1000, keys: keys)),
                ])

                return responses.flatMap { $0.result ?? [] }
            },
            pause: { gid in
                let _: String = try await session.aria2(.pause, GidParams(token: Const.token, gid: gid))
            },
            unpause: { gid in
                let _: String = try await session.aria2(.unpause, GidParams(token: Const.token, gid: gid))
            },
            remove: { gid in
                let _: String = try await session.aria2(.remove, GidParams(token: Const.token, gid: gid))
            },
            removeDownloadResult: { gid in
                let _: String = try await session.aria2(.removeDownloadResult, GidParams(token: Const.token, gid: gid))
            },
            setMaxConcurrentDownloads: { count in
                let _: String = try await session.aria2(.changeGlobalOption, OptionsParams(token: Const.token, options: ["max-concurrent-downloads": count]))
            },
        )
    }()
}

extension DependencyValues {
    var aria2Client: Aria2Client {
        get { self[Aria2Client.self] }
        set { self[Aria2Client.self] = newValue }
    }
}

private extension Session {
    func aria2<D: Decodable & Sendable>(_ method: Aria2Method, _ params: some Encodable & Sendable) async throws -> D {
        let response: Aria2Response<D> = try await aria2(Aria2Request(method: method, params: params))

        guard let result = response.result else {
            throw response.error ?? HDrezkaError.unknown
        }

        return result
    }

    func aria2<D: Decodable & Sendable>(_ body: some Encodable & Sendable) async throws -> D {
        let data = try await request(Aria2Service(body: JSONEncoder().encode(body)))
            .serializingData()
            .value

        return try JSONDecoder().decode(D.self, from: data)
    }
}
