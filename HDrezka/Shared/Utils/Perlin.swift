import Foundation

struct Perlin {
    private let perm: [Int]

    init() {
        let tmp = (0 ..< 256).map { _ in Int.random(in: 0 ..< 256) }

        perm = tmp + tmp
    }

    private func grad(_ i: Int, _ x: CGFloat) -> CGFloat {
        let h = i & 0xF
        let grad = CGFloat(1 + (h & 7))

        if (h & 8) != 0 {
            return -grad * x
        }
        return grad * x
    }

    func getValue(_ x: CGFloat) -> CGFloat {
        let i0 = Int(floor(x))
        let i1 = i0 + 1

        let x0 = x - CGFloat(i0)
        let x1 = x0 - 1.0

        var t0 = 1.0 - x0 * x0
        t0 *= t0

        var t1 = 1.0 - x1 * x1
        t1 *= t1

        let n0 = t0 * t0 * grad(perm[i0 & 0xFF], x0)
        let n1 = t1 * t1 * grad(perm[i1 & 0xFF], x1)

        return 0.395 * (n0 + n1)
    }
}
