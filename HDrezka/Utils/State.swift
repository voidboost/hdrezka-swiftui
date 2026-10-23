import Foundation

enum DataState<T: Equatable>: Equatable {
    /// Nothing has been requested yet.
    case idle
    case data(T)
    case loading
    case error(Error)
}

extension DataState {
    /// Whether there is nothing to show yet, either because the first request is in flight or hasn't started.
    var isLoading: Bool {
        switch self {
        case .idle, .loading: true
        case .data, .error: false
        }
    }

    /// Whether content still has to be requested: it never was, or the last attempt failed.
    var needsLoad: Bool {
        switch self {
        case .idle, .error: true
        case .data, .loading: false
        }
    }

    var data: T? {
        guard case let .data(data) = self else { return nil }

        return data
    }

    var error: Error? {
        guard case let .error(error) = self else { return nil }

        return error
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case let (.data(lhsData), .data(rhsData)):
            return lhsData == rhsData
        case (.idle, .idle), (.loading, .loading):
            return true
        case let (.error(lhsError), .error(rhsError)):
            let lhsNSError = lhsError as NSError?
            let rhsNSError = rhsError as NSError?

            return lhsNSError == rhsNSError
        default:
            return false
        }
    }
}

extension DataState where T: RangeReplaceableCollection {
    mutating func append(_ newData: T) {
        if case let .data(data) = self {
            self = .data(data + newData)
        } else {
            self = .data(newData)
        }
    }

    mutating func receivePage(_ result: Result<T, any Error>, isInitial: Bool, emptyPageIsError: Bool = false) -> DataPaginationState {
        switch result {
        case let .success(items) where isInitial:
            self = .data(items)
            return .idle
        case let .success(items) where emptyPageIsError && items.isEmpty:
            return .error(HDrezkaError.unknown)
        case let .success(items):
            append(items)
            return .idle
        case let .failure(error) where isInitial:
            self = .error(error)
            return .idle
        case let .failure(error):
            return .error(error)
        }
    }
}

enum DataPaginationState: Equatable {
    case idle
    case loading
    case error(Error)
}

extension DataPaginationState {
    var error: Error? {
        guard case let .error(error) = self else { return nil }

        return error
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle),
             (.loading, .loading):
            return true
        case let (.error(lhsError), .error(rhsError)):
            let lhsNSError = lhsError as NSError?
            let rhsNSError = rhsError as NSError?

            return lhsNSError == rhsNSError
        default:
            return false
        }
    }
}

enum EmptyState: Equatable {
    case data
    case loading
    case error(Error)
}

extension EmptyState {
    var error: Error? {
        guard case let .error(error) = self else { return nil }

        return error
    }

    var isLoading: Bool {
        guard case .loading = self else { return false }

        return true
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.data, .data),
             (.loading, .loading):
            return true
        case let (.error(lhsError), .error(rhsError)):
            let lhsNSError = lhsError as NSError?
            let rhsNSError = rhsError as NSError?

            return lhsNSError == rhsNSError
        default:
            return false
        }
    }
}

struct EquatableError: Equatable {
    let base: any Error

    init(_ base: any Error) {
        self.base = base
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.base as NSError == rhs.base as NSError
    }
}
