import Foundation

extension BidirectionalCollection where Element: Equatable {
    func element(before element: Element, wrapping: Bool = false) -> Element? {
        guard !isEmpty, let currentIndex = firstIndex(of: element) else { return nil }

        if currentIndex != startIndex {
            return self[index(before: currentIndex)]
        } else {
            return wrapping ? last : nil
        }
    }

//    func element(before predicate: (Element) -> Bool, wrapping: Bool = false) -> Element? {
//        guard !isEmpty, let currentIndex = firstIndex(where: predicate) else { return nil }
//
//        if currentIndex != startIndex {
//            return self[index(before: currentIndex)]
//        } else {
//            return wrapping ? last : nil
//        }
//    }

    func element(after element: Element, wrapping: Bool = false) -> Element? {
        guard !isEmpty, let currentIndex = firstIndex(of: element) else { return nil }

        if currentIndex != index(before: endIndex) {
            return self[index(after: currentIndex)]
        } else {
            return wrapping ? first : nil
        }
    }

//    func element(after predicate: (Element) -> Bool, wrapping: Bool = false) -> Element? {
//        guard !isEmpty, let currentIndex = firstIndex(where: predicate) else { return nil }
//
//        if currentIndex != index(before: endIndex) {
//            return self[index(after: currentIndex)]
//        } else {
//            return wrapping ? first : nil
//        }
//    }

//    func index(before element: Element, wrapping: Bool = false) -> Index? {
//        guard !isEmpty, let currentIndex = firstIndex(of: element) else { return nil }
//
//        if currentIndex != startIndex {
//            return index(before: currentIndex)
//        } else {
//            return wrapping ? index(before: endIndex) : nil
//        }
//    }

//    func index(before predicate: (Element) -> Bool, wrapping: Bool = false) -> Index? {
//        guard !isEmpty, let currentIndex = firstIndex(where: predicate) else { return nil }
//
//        if currentIndex != startIndex {
//            return index(before: currentIndex)
//        } else {
//            return wrapping ? index(before: endIndex) : nil
//        }
//    }

//    func index(after element: Element, wrapping: Bool = false) -> Index? {
//        guard !isEmpty, let currentIndex = firstIndex(of: element) else { return nil }
//
//        if currentIndex != index(before: endIndex) {
//            return index(after: currentIndex)
//        } else {
//            return wrapping ? startIndex : nil
//        }
//    }

    func index(after predicate: (Element) -> Bool, wrapping: Bool = false) -> Index? {
        guard !isEmpty, let currentIndex = firstIndex(where: predicate) else { return nil }

        if currentIndex != index(before: endIndex) {
            return index(after: currentIndex)
        } else {
            return wrapping ? startIndex : nil
        }
    }
}
