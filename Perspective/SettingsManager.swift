import Foundation

struct SettingsManager {
    private enum Keys {
        static let ipAddress = "ipAddressKey"
        static let port = "portKey"
    }

    static func save(ip: String, port: String) {
        let d = UserDefaults.standard
        d.set(ip, forKey: Keys.ipAddress)
        d.set(port, forKey: Keys.port)
    }

    static func load() -> (ip: String?, port: Int?) {
        let d = UserDefaults.standard
        let ip = d.string(forKey: Keys.ipAddress)
        let port = d.object(forKey: Keys.port) as? Int
        return (ip, port)
    }
}
