import Foundation
import Network
import Combine

class NMEAManager: ObservableObject {
    // MARK: - Published Properties
    @Published var connectionState: ConnectionState = .disconnected
    @Published var rawSentences: [String] = []
    @Published var parsedData: [NMEAParser.NMEAData] = []
    
    // MARK: - Public Properties
    enum ConnectionState: Equatable { case disconnected, connecting, connected, error(String) }
    
    // MARK: - Private Properties
    private var tcpClient: TCPClient?
    private let settings = SettingsManager.load()
    
    // MARK: - Public Methods
    func connect() {
        guard let ip = settings.ip, let port = settings.port else { return }
        connectionState = .connecting
        tcpClient = TCPClient()
        tcpClient?.delegate = self
        tcpClient?.connect(to: ip, port: UInt16(port))
    }
    
    func disconnect() {
        tcpClient?.disconnect()
    }
    
    func saveSettings(ip: String, port: String) {
        SettingsManager.save(ip: ip, port: port)
    }
}

// MARK: - TCPClientDelegate Conformance
extension NMEAManager: TCPClientDelegate {
    func tcpClientDidConnect() {
        DispatchQueue.main.async {
            self.connectionState = .connected
        }
    }
    
    func tcpClientDidDisconnect() {
        DispatchQueue.main.async {
            self.connectionState = .disconnected
        }
    }
    
    func tcpClientEncountered(error: String) {
        DispatchQueue.main.async {
            self.connectionState = .error(error)
        }
    }
    
    func tcpClientDidReceive(sentence: String) {
        DispatchQueue.main.async {
            self.rawSentences.append(sentence)
            if let data = NMEAParser.parse(sentence) {
                self.parsedData.append(data)
            }
        }
    }
}
