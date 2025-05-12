import Foundation

func decrypt(encrypted: String) -> String {
    guard encrypted.hasPrefix("#") else {
        return encrypted
    }

    let trash = generateTrash()
    var cache = [String: String]()

    func decryptRecursive(input: String) -> String {
        if let cached = cache[input] {
            return cached
        } else {
            let indexes = input.indexesOf(substr: "//_//")

            if indexes.isEmpty {
                cache[input] = input
                return input
            } else {
                let result = indexes.map { index in
                    let (before, after) = String(input[input.index(input.startIndex, offsetBy: index + 5)...]).divideAtFirstOccurrenceOfSymbols()
                    return decryptRecursive(input: "\(String(input[..<input.index(input.startIndex, offsetBy: index)]))\(before.clear(trash: trash))\(after)")
                }.min { $0.count < $1.count } ?? ""

                cache[input] = result
                return result
            }
        }
    }

    return decryptRecursive(input: String(encrypted.dropFirst(2))).base64Decoded
}

private func generateTrash(trashList: [String] = ["@", "#", "!", "^", "$"]) -> [String] {
    [2, 3].flatMap(trashList.cartesianProduct).map(\.base64Encoded)
}

private extension [String] {
    func cartesianProduct(n: Int) -> [String] {
        n == 1 ? self : self.cartesianProduct(n: n - 1).flatMap { item in self.map { "\(item)\($0)" } }
    }
}

extension String {
    fileprivate func clear(trash: [String]) -> String {
        trash.reduce(self) { acc, t in acc.replacingOccurrences(of: t, with: "") }
    }

    fileprivate func indexesOf(substr: String) -> [Int] {
        var indices = [Int]()
        var searchStartIndex = self.startIndex

        while searchStartIndex < self.endIndex,
              let range = self.range(of: substr, range: searchStartIndex ..< self.endIndex),
              !range.isEmpty
        {
            let index = distance(from: self.startIndex, to: range.lowerBound)
            indices.append(index)
            searchStartIndex = self.index(range.lowerBound, offsetBy: 1, limitedBy: endIndex) ?? endIndex
        }

        return indices
    }

    fileprivate func divideAtFirstOccurrenceOfSymbols() -> (String, String) {
        if let first = firstIndex(where: { $0 == "/" || $0 == "=" }), let next = index(first, offsetBy: 1, limitedBy: endIndex) {
            (String(self[..<next]), String(self[next...]))
        } else {
            (self, "")
        }
    }

    var base64Encoded: String {
        guard let data = self.data(using: .utf8) else { return "" }

        return data.base64EncodedString()
    }

    var base64Decoded: String {
        guard let data = Data(base64Encoded: self), let string = String(data: data, encoding: .utf8) else { return "" }

        return string
    }
}
