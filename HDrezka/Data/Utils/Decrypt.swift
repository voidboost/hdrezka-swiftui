import Foundation

func decrypt(encrypted: String) -> String {
    guard encrypted.hasPrefix("#") else { return encrypted }

    var cache: [[UInt8]: [UInt8]] = [:]

    func decryptRecursive(_ input: [UInt8]) -> [UInt8] {
        if let cached = cache[input] {
            return cached
        }

        let result = input.offsets(of: marker)
            .map { offset in
                let (before, after) = input[(offset + marker.count)...].divideAtFirstOccurrenceOfSymbols()
                return decryptRecursive(Array(input[..<offset]) + before.clear(trash: trash) + after)
            }
            .min { $0.count < $1.count } ?? input

        cache[input] = result
        return result
    }

    let decrypted = decryptRecursive(Array(encrypted.utf8.dropFirst(2)))

    guard let data = Data(base64Encoded: Data(decrypted)), let string = String(data: data, encoding: .utf8) else { return "" }

    return string
}

private let marker = Array("//_//".utf8)

private let trash = [2, 3].flatMap(["@", "#", "!", "^", "$"].cartesianProduct).map { Array($0.base64Encoded.utf8) }

private extension [String] {
    func cartesianProduct(count: Int) -> [String] {
        count == 1 ? self : cartesianProduct(count: count - 1).flatMap { item in self.map { "\(item)\($0)" } }
    }
}

private extension [UInt8] {
    func matches(_ pattern: [UInt8], at index: Int) -> Bool {
        guard index + pattern.count <= count, self[index] == pattern[0] else { return false }

        for offset in 1 ..< pattern.count where self[index + offset] != pattern[offset] {
            return false
        }

        return true
    }

    func firstOffset(of pattern: [UInt8]) -> Int? {
        guard count >= pattern.count else { return nil }

        return (0 ... count - pattern.count).first { matches(pattern, at: $0) }
    }

    func offsets(of pattern: [UInt8]) -> [Int] {
        guard count >= pattern.count else { return [] }

        return (0 ... count - pattern.count).filter { matches(pattern, at: $0) }
    }
}

private extension ArraySlice<UInt8> {
    func divideAtFirstOccurrenceOfSymbols() -> (ArraySlice<UInt8>, ArraySlice<UInt8>) {
        guard let symbol = firstIndex(where: { $0 == UInt8(ascii: "/") || $0 == UInt8(ascii: "=") }), symbol != endIndex - 1 else {
            return (self, [])
        }

        return (self[...symbol], self[(symbol + 1)...])
    }

    func clear(trash: [[UInt8]]) -> [UInt8] {
        var bytes = Array(self)

        for pattern in trash {
            guard let first = bytes.firstOffset(of: pattern) else { continue }

            var result = Array(bytes[..<first])
            result.reserveCapacity(bytes.count)

            var index = first + pattern.count
            while index < bytes.count {
                if bytes.matches(pattern, at: index) {
                    index += pattern.count
                } else {
                    result.append(bytes[index])
                    index += 1
                }
            }

            bytes = result
        }

        return bytes
    }
}

extension String {
    var base64Encoded: String {
        Data(utf8).base64EncodedString()
    }

    var base64Decoded: String {
        guard let data = Data(base64Encoded: self), let string = String(data: data, encoding: .utf8) else { return "" }

        return string
    }
}
