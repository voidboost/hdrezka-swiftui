import Foundation

// MARK: RPC

struct Aria2Request<E: Encodable>: Encodable {
    let method: Aria2Method
    let params: E?

    init(method: Aria2Method, params: E? = nil) {
        self.method = method
        self.params = params
    }

    enum CodingKeys: String, CodingKey {
        case id, jsonrpc, method, params
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(UUID().uuidString, forKey: .id)
        try container.encode("2.0", forKey: .jsonrpc)
        try container.encode(method, forKey: .method)

        if let params {
            try container.encode(params, forKey: .params)
        }
    }
}

struct Aria2Response<D: Decodable>: Decodable {
    let result: D?
    let error: Aria2Error?
}

struct Aria2Error: Decodable {
    let code: Aria2ErrorCode
}

enum Aria2ErrorCode: Int, Codable {
    case finished = 0
    case unknownError
    case timeOut
    case resourceNotFound
    case maxFileNotFound
    case tooSlowDownloadSpeed
    case networkProblem
    case inProgress
    case cannotResume
    case notEnoughDiskSpace
    case pieceLengthChanged
    case duplicateDownload
    case duplicateInfoHash
    case fileAlreadyExists
    case fileRenamingFailed
    case fileOpenError
    case fileCreateError
    case fileIoError
    case dirCreateError
    case nameResolveError
    case metalinkParseError
    case ftpProtocolError
    case httpProtocolError
    case httpTooManyRedirects
    case httpAuthFailed
    case bencodeParseError
    case bittorrentParseError
    case magnetParseError
    case optionError
    case httpServiceUnavailable
    case jsonParseError
    case removed
    case checksumError

    var description: String {
        switch self {
        case .finished:
            String(localized: "key.aria2.error.finished")
        case .unknownError:
            String(localized: "key.aria2.error.unknownError")
        case .timeOut:
            String(localized: "key.aria2.error.timeOut")
        case .resourceNotFound:
            String(localized: "key.aria2.error.resourceNotFound")
        case .maxFileNotFound:
            String(localized: "key.aria2.error.maxFileNotFound")
        case .tooSlowDownloadSpeed:
            String(localized: "key.aria2.error.tooSlowDownloadSpeed")
        case .networkProblem:
            String(localized: "key.aria2.error.networkProblem")
        case .inProgress:
            String(localized: "key.aria2.error.inProgress")
        case .cannotResume:
            String(localized: "key.aria2.error.cannotResume")
        case .notEnoughDiskSpace:
            String(localized: "key.aria2.error.notEnoughDiskSpace")
        case .pieceLengthChanged:
            String(localized: "key.aria2.error.pieceLengthChanged")
        case .duplicateDownload:
            String(localized: "key.aria2.error.duplicateDownload")
        case .duplicateInfoHash:
            String(localized: "key.aria2.error.duplicateInfoHash")
        case .fileAlreadyExists:
            String(localized: "key.aria2.error.fileAlreadyExists")
        case .fileRenamingFailed:
            String(localized: "key.aria2.error.fileRenamingFailed")
        case .fileOpenError:
            String(localized: "key.aria2.error.fileOpenError")
        case .fileCreateError:
            String(localized: "key.aria2.error.fileCreateError")
        case .fileIoError:
            String(localized: "key.aria2.error.fileIoError")
        case .dirCreateError:
            String(localized: "key.aria2.error.dirCreateError")
        case .nameResolveError:
            String(localized: "key.aria2.error.nameResolveError")
        case .metalinkParseError:
            String(localized: "key.aria2.error.metalinkParseError")
        case .ftpProtocolError:
            String(localized: "key.aria2.error.ftpProtocolError")
        case .httpProtocolError:
            String(localized: "key.aria2.error.httpProtocolError")
        case .httpTooManyRedirects:
            String(localized: "key.aria2.error.httpTooManyRedirects")
        case .httpAuthFailed:
            String(localized: "key.aria2.error.httpAuthFailed")
        case .bencodeParseError:
            String(localized: "key.aria2.error.bencodeParseError")
        case .bittorrentParseError:
            String(localized: "key.aria2.error.bittorrentParseError")
        case .magnetParseError:
            String(localized: "key.aria2.error.magnetParseError")
        case .optionError:
            String(localized: "key.aria2.error.optionError")
        case .httpServiceUnavailable:
            String(localized: "key.aria2.error.httpServiceUnavailable")
        case .jsonParseError:
            String(localized: "key.aria2.error.jsonParseError")
        case .removed:
            String(localized: "key.aria2.error.removed")
        case .checksumError:
            String(localized: "key.aria2.error.checksumError")
        }
    }
}

// MARK: Params

protocol TokenParams: Encodable {
    var token: String { get }
    func encodeAdditional(to container: inout UnkeyedEncodingContainer) throws
}

extension TokenParams {
    func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode("token:\(token)")
        try encodeAdditional(to: &container)
    }
}

protocol KeysParams: TokenParams {
    var keys: [String]? { get }
}

extension KeysParams {
    func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode("token:\(token)")
        try encodeAdditional(to: &container)
        if let keys {
            try container.encode(keys)
        }
    }
}

struct EmptyTokenParams: TokenParams {
    let token: String

    func encodeAdditional(to _: inout UnkeyedEncodingContainer) throws {}
}

struct AddUriParams<E: Encodable>: TokenParams {
    let token: String
    let uris: [String]
    let options: [String: E]?
    let position: Int?

    init(token: String, uris: [String], options: [String: E]? = nil, position: Int? = nil) {
        self.token = token
        self.uris = uris
        self.options = options
        self.position = position
    }

    func encodeAdditional(to container: inout UnkeyedEncodingContainer) throws {
        try container.encode(uris)
        if let options {
            try container.encode(options)
        }
        if let position {
            try container.encode(position)
        }
    }
}

struct OffsetParams: KeysParams {
    let token: String
    let offset: Int?
    let num: Int?
    let keys: [String]?

    init(token: String, offset: Int? = nil, num: Int? = nil, keys: [String]? = nil) {
        self.token = token
        self.offset = offset
        self.num = num
        self.keys = keys
    }

    func encodeAdditional(to container: inout UnkeyedEncodingContainer) throws {
        if let offset, let num {
            try container.encode(offset)
            try container.encode(num)
        }
    }
}

struct GidParams: TokenParams {
    let token: String
    let gid: String

    func encodeAdditional(to container: inout UnkeyedEncodingContainer) throws {
        try container.encode(gid)
    }
}

struct OptionsParams<E: Encodable>: TokenParams {
    let token: String
    let options: [String: E]

    func encodeAdditional(to container: inout UnkeyedEncodingContainer) throws {
        try container.encode(options)
    }
}

// MARK: Results

struct GlobalStatusResult: Decodable {
    let numActive: Int
    let numWaiting: Int
    let numStopped: Int

    enum CodingKeys: String, CodingKey {
        case numActive, numWaiting, numStopped
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        numActive = try Int(container.decode(String.self, forKey: .numActive)).orThrow()
        numWaiting = try Int(container.decode(String.self, forKey: .numWaiting)).orThrow()
        numStopped = try Int(container.decode(String.self, forKey: .numStopped)).orThrow()
    }
}

struct StatusResult: Codable, Hashable {
    let gid: String
    private(set) var status: Status
    let totalLength: Int64
    let completedLength: Int64
    let downloadSpeed: Int
    let errorCode: Int?

    enum CodingKeys: String, CodingKey {
        case gid, status, totalLength, completedLength, downloadSpeed, errorCode
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        gid = try container.decode(String.self, forKey: .gid)
        status = try container.decode(Status.self, forKey: .status)
        totalLength = try Int64(container.decode(String.self, forKey: .totalLength)).orThrow()
        completedLength = try Int64(container.decode(String.self, forKey: .completedLength)).orThrow()
        downloadSpeed = try Int(container.decode(String.self, forKey: .downloadSpeed)).orThrow()

        if let codeStr = try container.decodeIfPresent(String.self, forKey: .errorCode) {
            errorCode = Int(codeStr)
        } else {
            errorCode = nil
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(gid, forKey: .gid)
        try container.encode(status.rawValue, forKey: .status)
        try container.encode(String(totalLength), forKey: .totalLength)
        try container.encode(String(completedLength), forKey: .completedLength)
        try container.encode(String(downloadSpeed), forKey: .downloadSpeed)

        if let errorCode {
            try container.encode(String(errorCode), forKey: .errorCode)
        }
    }

    mutating func pause() {
        if status != .paused {
            status = .paused
        }
    }

    mutating func unpause() {
        if status == .paused {
            status = .waiting
        }
    }
}

enum Status: String, Decodable {
    case active, waiting, paused, error, complete, removed
}

// MARK: Methods

enum Aria2Method: String, Encodable, Sendable {
    case addUri = "aria2.addUri"
    case remove = "aria2.remove"
    case pause = "aria2.pause"
    case pauseAll = "aria2.pauseAll"
    case unpause = "aria2.unpause"
    case unpauseAll = "aria2.unpauseAll"
    case tellActive = "aria2.tellActive"
    case tellWaiting = "aria2.tellWaiting"
    case tellStopped = "aria2.tellStopped"
    case changeGlobalOption = "aria2.changeGlobalOption"
    case removeDownloadResult = "aria2.removeDownloadResult"
    case getGlobalStat = "aria2.getGlobalStat"
}
