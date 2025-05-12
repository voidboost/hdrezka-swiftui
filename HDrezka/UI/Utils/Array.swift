import Foundation

extension BidirectionalCollection where Element: Equatable {
    func element(before element: Element, wrapping: Bool = false) -> Element? {
        if let index = self.firstIndex(of: element) {
            let precedingIndex = self.index(before: index)
            if precedingIndex >= self.startIndex {
                return self[precedingIndex]
            } else if wrapping {
                return self[self.index(before: self.endIndex)]
            }
        }
        return nil
    }

    func element(after element: Element, wrapping: Bool = false) -> Element? {
        if let index = self.firstIndex(of: element) {
            let followingIndex = self.index(after: index)
            if followingIndex < self.endIndex {
                return self[followingIndex]
            } else if wrapping {
                return self[self.startIndex]
            }
        }
        return nil
    }
}
