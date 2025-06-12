import SwiftUI

class CustomScanner {
    private let scanner: Scanner
    private let length: Int

    init(string: String) {
        scanner = Scanner(string: string)
        scanner.charactersToBeSkipped = nil
        length = (string as NSString).length
    }

    var scanLocation: Int {
        get {
            return scanner.string.distance(from: scanner.string.startIndex, to: scanner.currentIndex)
        }
        set {
            scanner.currentIndex = scanner.string.index(scanner.string.startIndex, offsetBy: newValue)
        }
    }

    var isAtEnd: Bool {
        return scanLocation == length
    }

    @discardableResult
    func scanUpToCharacters(from set: CharacterSet, thenSkip skipCount: Int = 0) -> String? {
        let string = scanner.scanUpToCharacters(from: set)

        if string != nil, skipCount > 0 {
            skip(skipCount)
        }

        return string
    }

    @discardableResult
    func scanCharacters(from set: CharacterSet, thenSkip skipCount: Int = 0) -> String? {
        let string = scanner.scanCharacters(from: set)

        if string != nil, skipCount > 0 {
            skip(skipCount)
        }

        return string
    }

    func scanInt(hexadecimal: Bool = false) -> Int? {
        switch hexadecimal {
        case true:
            let allowedSet = CharacterSet(charactersIn: "0123456789ABCDEFabcdef")

            guard let text = scanner.scanCharacters(from: allowedSet) else {
                break
            }

            let scanner = Scanner(string: "0x\(text)")
            var value: UInt64 = 0

            guard scanner.scanHexInt64(&value) else {
                break
            }

            return Int(value)
        case false:
            guard let text = scanner.scanCharacters(from: .decimalDigits) else {
                break
            }

            return Int(text)
        }
        return nil
    }

    func peek(_ count: Int, thenSkip: Bool = false) -> String? {
        guard !isAtEnd else {
            return nil
        }

        let count = min(count, length - scanLocation)
        let string = scanner.string as NSString
        let range = NSRange(location: scanLocation, length: count)

        if thenSkip {
            skip(count)
        }

        return string.substring(with: range) as String
    }

    func peekCharacter(thenSkip: Bool = false) -> Character? {
        guard !isAtEnd else {
            return nil
        }

        let string = scanner.string as NSString
        let character = string.character(at: scanLocation)

        if thenSkip {
            skip(1)
        }

        if let scalar = Unicode.Scalar(character) {
            return Character(scalar)
        }

        return nil
    }

    func skip(_ count: Int) {
        if scanLocation + count < length {
            scanLocation += count
        } else {
            scanLocation = length
        }
    }
}
