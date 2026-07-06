import Foundation

nonisolated struct SemanticVersion: Comparable, Sendable {
    private let parts: [Int]

    init(_ rawValue: String) {
        parts = rawValue
            .split(separator: "+")[0]
            .split(separator: ".")
            .map { Int($0.filter(\.isNumber)) ?? 0 }
    }

    static func < (lhs: SemanticVersion, rhs: SemanticVersion) -> Bool {
        let count = max(lhs.parts.count, rhs.parts.count)
        for index in 0..<count {
            let left = lhs.parts.indices.contains(index) ? lhs.parts[index] : 0
            let right = rhs.parts.indices.contains(index) ? rhs.parts[index] : 0
            if left != right {
                return left < right
            }
        }
        return false
    }
}
