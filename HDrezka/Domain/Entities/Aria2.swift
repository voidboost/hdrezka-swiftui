import Foundation

// MARK: RPC

struct Aria2Request<E: Encodable>: Encodable {
    let id: String = UUID().uuidString
    let jsonrpc: String = "2.0"
    let method: Aria2Method
    let params: E?

    init(method: Aria2Method, params: E? = nil) {
        self.method = method
        self.params = params
    }
}

struct Aria2Response<D: Decodable>: Decodable {
    let id: String
    let jsonrpc: String
    let result: D?
    let error: Aria2Error?
}

struct Aria2Error: Decodable, Error {
    let code: Aria2ErrorCode
    let message: String
}

enum Aria2ErrorCode: Int, Codable {
    case undefined = -1
    case finished = 0
    case unknownError = 1
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
        case .undefined:
            "Undefined"
        case .finished:
            "Finished"
        case .unknownError:
            "Unknown error"
        case .timeOut:
            "Timed out"
        case .resourceNotFound:
            "Resource not found"
        case .maxFileNotFound:
            "Maximum number of file not found errors reached"
        case .tooSlowDownloadSpeed:
            "Download speed too slow"
        case .networkProblem:
            "Network problem"
        case .inProgress:
            "Unfinished downloads in progress"
        case .cannotResume:
            "Remote server did not support resume when resume was required to complete download"
        case .notEnoughDiskSpace:
            "Not enough disk space available"
        case .pieceLengthChanged:
            "Piece length was different from one in .aria2 control file"
        case .duplicateDownload:
            "Duplicate download"
        case .duplicateInfoHash:
            "Duplicate info hash torrent"
        case .fileAlreadyExists:
            "File already exists"
        case .fileRenamingFailed:
            "Renaming file failed"
        case .fileOpenError:
            "Could not open existing file"
        case .fileCreateError:
            "Could not create new file or truncate existing file"
        case .fileIoError:
            "File I/O error"
        case .dirCreateError:
            "Could not create directory"
        case .nameResolveError:
            "Name resolution failed"
        case .metalinkParseError:
            "Could not parse Metalink document"
        case .ftpProtocolError:
            "FTP command failed"
        case .httpProtocolError:
            "HTTP response header was bad or unexpected"
        case .httpTooManyRedirects:
            "Too many redirects occurred"
        case .httpAuthFailed:
            "HTTP authorization failed"
        case .bencodeParseError:
            "Could not parse bencoded file (usually \".torrent\" file)"
        case .bittorrentParseError:
            "\".torrent\" file was corrupted or missing information"
        case .magnetParseError:
            "Magnet URI was bad"
        case .optionError:
            "Bad/unrecognized option was given or unexpected option argument was given"
        case .httpServiceUnavailable:
            "HTTP service unavailable"
        case .jsonParseError:
            "Could not parse JSON-RPC request"
        case .removed:
            "Reserved. Not used."
        case .checksumError:
            "Checksum validation failed"
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
