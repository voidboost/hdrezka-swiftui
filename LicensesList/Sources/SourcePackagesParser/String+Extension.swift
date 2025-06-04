import Foundation

extension String {
    func nest() -> String {
        components(separatedBy: .newlines)
            .filter { !$0.isEmpty }
            .map { "    \($0)" }
            .joined(separator: "\n")
    }
}
