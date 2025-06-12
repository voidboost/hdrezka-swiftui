import Foundation

extension BidirectionalCollection where Element: Equatable {
    func element(before element: Element, wrapping: Bool = false) -> Element? {
        if let index = firstIndex(of: element) {
            let precedingIndex = self.index(before: index)
            if precedingIndex >= startIndex {
                return self[precedingIndex]
            } else if wrapping {
                return self[self.index(before: endIndex)]
            }
        }
        return nil
    }

    func element(after element: Element, wrapping: Bool = false) -> Element? {
        if let index = firstIndex(of: element) {
            let followingIndex = self.index(after: index)
            if followingIndex < endIndex {
                return self[followingIndex]
            } else if wrapping {
                return self[startIndex]
            }
        }
        return nil
    }
}
