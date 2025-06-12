import Foundation

enum DataState<T: Hashable>: Hashable {
    case data(T)
    case loading
    case nsError(NSError)
}

extension DataState {
    static func error(_ error: Error) -> DataState {
        .nsError(error as NSError)
    }

    var data: T? {
        guard case let .data(data) = self else { return nil }

        return data
    }

    var error: Error? {
        guard case let .nsError(error) = self else { return nil }

        return error
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
}

enum DataPaginationState: Hashable {
    case idle
    case loading
    case nsError(NSError)
}

extension DataPaginationState {
    static func error(_ error: Error) -> DataPaginationState {
        .nsError(error as NSError)
    }

    var error: Error? {
        guard case let .nsError(error) = self else { return nil }

        return error
    }
}

enum EmptyState: Hashable {
    case data
    case loading
    case error
}
