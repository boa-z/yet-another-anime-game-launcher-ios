import Foundation

enum ProgressCommand: Sendable {
    case setProgress(Double)
    case setUndeterminedProgress
    case setStateText(String)
    case appendLog(String)
}

