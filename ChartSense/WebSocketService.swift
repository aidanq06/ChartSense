import Foundation
import Combine

// MARK: - WebSocket Service for Real-time Stock Data
class WebSocketService: ObservableObject {
    static let shared = WebSocketService()
    
    private let apiKey = Config.finnhubAPIKey
    private var webSocket: URLSessionWebSocketTask?
    private var isConnected = false
    
    @Published var realTimePrices: [String: Double] = [:]
    @Published var connectionStatus: ConnectionStatus = .disconnected
    @Published var lastUpdate: Date?
    
    private var cancellables = Set<AnyCancellable>()
    
    enum ConnectionStatus: Equatable {
        case disconnected
        case connecting
        case connected
        case error(String)
        
        static func == (lhs: ConnectionStatus, rhs: ConnectionStatus) -> Bool {
            switch (lhs, rhs) {
            case (.disconnected, .disconnected),
                 (.connecting, .connecting),
                 (.connected, .connected):
                return true
            case (.error(let lhsMessage), .error(let rhsMessage)):
                return lhsMessage == rhsMessage
            default:
                return false
            }
        }
    }
    
    private init() {
        print("🔌 Initializing WebSocket Service...")
    }
    
    // MARK: - Public Methods
    
    func connect() {
        guard !isConnected else { return }
        
        connectionStatus = .connecting
        print("🔌 Connecting to Finnhub WebSocket...")
        
        let urlString = "wss://ws.finnhub.io?token=\(apiKey)"
        guard let url = URL(string: urlString) else {
            connectionStatus = .error("Invalid WebSocket URL")
            return
        }
        
        let session = URLSession(configuration: .default)
        webSocket = session.webSocketTask(with: url)
        webSocket?.resume()
        
        receiveMessage()
    }
    
    func disconnect() {
        webSocket?.cancel(with: .normalClosure, reason: nil)
        isConnected = false
        connectionStatus = .disconnected
        print("🔌 Disconnected from WebSocket")
    }
    
    func subscribeToSymbols(_ symbols: [String]) {
        guard isConnected else {
            print("⚠️ WebSocket not connected, attempting to connect...")
            connect()
            return
        }
        
        for symbol in symbols {
            let message = """
            {
                "type": "subscribe",
                "symbol": "\(symbol)"
            }
            """
            
            let webSocketMessage = URLSessionWebSocketTask.Message.string(message)
            webSocket?.send(webSocketMessage) { error in
                if let error = error {
                    print("❌ Failed to subscribe to \(symbol): \(error)")
                } else {
                    print("✅ Subscribed to \(symbol)")
                }
            }
        }
    }
    
    func unsubscribeFromSymbols(_ symbols: [String]) {
        guard isConnected else { return }
        
        for symbol in symbols {
            let message = """
            {
                "type": "unsubscribe",
                "symbol": "\(symbol)"
            }
            """
            
            let webSocketMessage = URLSessionWebSocketTask.Message.string(message)
            webSocket?.send(webSocketMessage) { error in
                if let error = error {
                    print("❌ Failed to unsubscribe from \(symbol): \(error)")
                } else {
                    print("✅ Unsubscribed from \(symbol)")
                }
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func receiveMessage() {
        webSocket?.receive { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let message):
                    self?.handleMessage(message)
                    self?.receiveMessage() // Continue receiving
                case .failure(let error):
                    print("❌ WebSocket receive error: \(error)")
                    self?.connectionStatus = .error(error.localizedDescription)
                    self?.isConnected = false
                }
            }
        }
    }
    
    private func handleMessage(_ message: URLSessionWebSocketTask.Message) {
        switch message {
        case .string(let text):
            handleStringMessage(text)
        case .data(let data):
            handleDataMessage(data)
        @unknown default:
            print("⚠️ Unknown WebSocket message type")
        }
    }
    
    private func handleStringMessage(_ text: String) {
        guard let data = text.data(using: .utf8) else { return }
        
        do {
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                if let type = json["type"] as? String {
                    switch type {
                    case "trade":
                        handleTradeMessage(json)
                    case "ping":
                        handlePingMessage()
                    case "error":
                        handleErrorMessage(json)
                    default:
                        print("📨 Unknown message type: \(type)")
                    }
                }
            }
        } catch {
            print("❌ Failed to parse WebSocket message: \(error)")
        }
    }
    
    private func handleDataMessage(_ data: Data) {
        // Handle binary data if needed
        print("📨 Received binary data: \(data.count) bytes")
    }
    
    private func handleTradeMessage(_ json: [String: Any]) {
        guard let data = json["data"] as? [[String: Any]] else { return }
        
        for trade in data {
            if let symbol = trade["s"] as? String,
               let price = trade["p"] as? Double {
                realTimePrices[symbol] = price
                lastUpdate = Date()
                
                print("📈 Real-time update: \(symbol) = $\(price)")
            }
        }
    }
    
    private func handlePingMessage() {
        // Send pong response to keep connection alive
        let pongMessage = """
        {
            "type": "pong"
        }
        """
        
        let webSocketMessage = URLSessionWebSocketTask.Message.string(pongMessage)
        webSocket?.send(webSocketMessage) { error in
            if let error = error {
                print("❌ Failed to send pong: \(error)")
            }
        }
    }
    
    private func handleErrorMessage(_ json: [String: Any]) {
        if let message = json["msg"] as? String {
            print("❌ WebSocket error: \(message)")
            connectionStatus = .error(message)
        }
    }
    
    // MARK: - Connection Management
    
    func startConnection() {
        connect()
        
        // Auto-reconnect on failure
        Timer.publish(every: 30, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                if self?.connectionStatus == .disconnected {
                    print("🔄 Attempting to reconnect...")
                    self?.connect()
                }
            }
            .store(in: &cancellables)
    }
    
    func stopConnection() {
        disconnect()
        cancellables.removeAll()
    }
}

// MARK: - Real-time Price Updates
extension WebSocketService {
    func getRealTimePrice(for symbol: String) -> Double? {
        return realTimePrices[symbol]
    }
    
    func isPriceUpdated(for symbol: String) -> Bool {
        return realTimePrices[symbol] != nil
    }
    
    func clearPrices() {
        realTimePrices.removeAll()
    }
} 