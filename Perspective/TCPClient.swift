import Foundation
import Network

protocol TCPClientDelegate: AnyObject {
    func tcpClientDidConnect()
    func tcpClientDidDisconnect()
    func tcpClientDidReceive(sentence: String)
    func tcpClientEncountered(error: String)
}

class TCPClient {
    weak var delegate: TCPClientDelegate?
    private var connection: NWConnection?
    private var buffer = Data()
    private let queue = DispatchQueue(label: "com.yourapp.tcpclient.network", qos: .userInitiated)

    func connect(to host: String, port: UInt16) {
        print("[TCP] Attempting to connect to \(host):\(port)")
        guard let nwPort = NWEndpoint.Port(rawValue: port) else {
            let msg = "Invalid Port: \(port)"
            print("[TCP] Error: \(msg)")
            delegate?.tcpClientEncountered(error: msg)
            return
        }
        
        let endpoint = NWEndpoint.Host(host)
        connection = NWConnection(host: endpoint, port: nwPort, using: .tcp)
        
        connection?.stateUpdateHandler = { [weak self] newState in
            print("[TCP] State changed: \(newState)")
            switch newState {
            case .ready:
                self?.delegate?.tcpClientDidConnect()
                self?.receive()
            case .failed(let error):
                self?.delegate?.tcpClientEncountered(error: error.localizedDescription)
                self?.disconnect()
            case .cancelled:
                self?.delegate?.tcpClientDidDisconnect()
            case .waiting(let error):
                self?.delegate?.tcpClientEncountered(error: "Connection waiting: \(error.localizedDescription)")
            default:
                break
            }
        }
        
        connection?.start(queue: queue)
    }

    func disconnect() {
        print("[TCP] Disconnecting.")
        connection?.cancel()
        connection = nil
    }

    private func receive() {
        connection?.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] (data, _, isComplete, error) in
            if let data = data, !data.isEmpty {
                self?.processReceivedData(data)
            }
            
            if let error = error {
                print("[TCP] Receive error: \(error.localizedDescription)")
                self?.delegate?.tcpClientEncountered(error: error.localizedDescription)
                self?.disconnect()
                return
            }
            
            if isComplete {
                print("[TCP] Connection closed by server.")
                self?.disconnect()
            } else {
                self?.receive()
            }
        }
    }

    private func processReceivedData(_ data: Data) {
        buffer.append(data)
        let terminator = "\r\n".data(using: .utf8)!
        
        while let range = buffer.range(of: terminator) {
            let sentenceData = buffer.subdata(in: 0..<range.lowerBound)
            if let sentenceString = String(data: sentenceData, encoding: .utf8), !sentenceString.isEmpty {
                print("[TCP] Received sentence: \(sentenceString)")
                delegate?.tcpClientDidReceive(sentence: sentenceString)
            }
            buffer.removeSubrange(0..<range.upperBound)
        }
    }
}