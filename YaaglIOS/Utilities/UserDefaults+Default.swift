import Foundation

extension UserDefaults {
    func integerOrDefault(forKey key: String, defaultValue: Int) -> Int {
        if object(forKey: key) == nil {
            defaultValue
        } else {
            integer(forKey: key)
        }
    }
}

