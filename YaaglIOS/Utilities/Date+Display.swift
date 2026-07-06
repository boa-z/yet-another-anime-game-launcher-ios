import Foundation

extension Date {
    var shortTimeDisplay: String {
        formatted(date: .omitted, time: .shortened)
    }
}

