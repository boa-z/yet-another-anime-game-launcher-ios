import Foundation

nonisolated struct BinaryTranslationStage: Identifiable, Hashable, Sendable {
    let id: String
    let title: String
    let summary: String

    var logFragment: String {
        "\(title) (\(summary))"
    }
}
