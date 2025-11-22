//
//  WebSocketManager.swift
//  Cafe
//
//  Generic WebSocket manager with reconnection and heartbeat support
//

import Foundation
import Combine

@MainActor
@Observable
class WebSocketManager {
    static let shared = WebSocketManager()
    
    // MARK: - Properties
    
    private var webSocketTask: URLSessionWebSocketTask?
    private var isConnected = false
    private var reconnectAttempts = 0
    private let maxReconnectAttempts = 5
    private let baseReconnectDelay: TimeInterval = 1.0
    private var reconnectTask: _Concurrency.Task<Void, Never>?
    private var heartbeatTask: _Concurrency.Task<Void, Never>?
    
    private let session: URLSession
    private let delegate: WebSocketDelegate
    private var url: URL?
    private var authToken: String?
    
    // Message handlers
    var onMessage: ((String) -> Void)?
    var onConnect: (() -> Void)?
    var onDisconnect: ((Error?) -> Void)?
    var onError: ((Error) -> Void)?
    
    // WebSocket close code handler - called when connection closes with specific code
    var onClose: ((Int, String?) -> Void)? // (closeCode, reason)
    
    // Connection state
    var connectionState: ConnectionState = .disconnected {
        didSet {
            if connectionState != oldValue {
                if connectionState == .connected {
                    onConnect?()
                } else if connectionState == .disconnected {
                    onDisconnect?(nil)
                }
            }
        }
    }
    
    enum ConnectionState {
        case disconnected
        case connecting
        case connected
        case reconnecting
    }
    
    // MARK: - Initialization
    
    private init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 300
        let delegate = WebSocketDelegate()
        self.delegate = delegate
        self.session = URLSession(configuration: configuration, delegate: delegate, delegateQueue: .main)
        delegate.manager = self
    }
    
    // MARK: - Connection Management
    
    func connect(url: URL, authToken: String?) async {
        guard connectionState != .connected && connectionState != .connecting else {
            return
        }
        
        self.url = url
        self.authToken = authToken
        connectionState = .connecting
        
        await performConnect()
    }
    
    private func performConnect() async {
        guard let url = url else { return }
        
        var request = URLRequest(url: url)
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            #if DEBUG
            let tokenPreview = String(token.prefix(20)) + "..."
            print("[WebSocket] Connecting with Authorization header (token: \(tokenPreview))")
            #endif
        } else {
            #if DEBUG
            print("[WebSocket] ⚠️ WARNING: Connecting without Authorization token")
            #endif
        }
        
        webSocketTask = session.webSocketTask(with: request)
        webSocketTask?.resume()
        
        receiveMessage()
        startHeartbeat()
        
        #if DEBUG
        print("[WebSocket] Connecting to \(url.absoluteString)")
        print("[WebSocket] Expected path: /ws/... (should NOT include /api/)")
        #endif
    }
    
    func disconnect() {
        reconnectTask?.cancel()
        reconnectTask = nil
        heartbeatTask?.cancel()
        heartbeatTask = nil
        webSocketTask?.cancel(with: .normalClosure, reason: nil)
        webSocketTask = nil
        isConnected = false
        connectionState = .disconnected
        reconnectAttempts = 0
        
        #if DEBUG
        print("[WebSocket] Disconnected")
        #endif
    }
    
    // MARK: - Message Handling
    
    func send(_ message: String) async throws {
        guard let webSocketTask = webSocketTask, connectionState == .connected else {
            throw WebSocketError.notConnected
        }
        
        let message = URLSessionWebSocketTask.Message.string(message)
        try await webSocketTask.send(message)
    }
    
    func send(_ data: Data) async throws {
        guard let webSocketTask = webSocketTask, connectionState == .connected else {
            throw WebSocketError.notConnected
        }
        
        let message = URLSessionWebSocketTask.Message.data(data)
        try await webSocketTask.send(message)
    }
    
    private func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            _Concurrency.Task { @MainActor [weak self] in
                guard let self = self else { return }
                
                switch result {
                case .success(let message):
                    self.handleMessage(message)
                    self.receiveMessage() // Continue listening
                case .failure(let error):
                    #if DEBUG
                    let nsError = error as NSError
                    print("[WebSocket] Receive error: \(error.localizedDescription)")
                    print("[WebSocket] Error code: \(nsError.code), domain: \(nsError.domain)")
                    if nsError.code == -1011 {
                        print("[WebSocket] Interpretation: Bad response from server (likely nginx routing issue or auth failure)")
                        print("[WebSocket] Check: 1) nginx /ws/ location block exists, 2) Authorization header is set, 3) backend is running")
                    }
                    #endif
                    self.handleDisconnection(error: error)
                }
            }
        }
    }
    
    private func handleMessage(_ message: URLSessionWebSocketTask.Message) {
        switch message {
        case .string(let text):
            onMessage?(text)
        case .data(let data):
            if let text = String(data: data, encoding: .utf8) {
                onMessage?(text)
            }
        @unknown default:
            break
        }
    }
    
    // MARK: - Heartbeat
    
    private func startHeartbeat() {
        heartbeatTask?.cancel()
        heartbeatTask = _Concurrency.Task {
            while !_Concurrency.Task.isCancelled {
                try? await _Concurrency.Task.sleep(nanoseconds: 30_000_000_000) // 30 seconds
                
                guard connectionState == .connected else {
                    break
                }
                
                do {
                    // Send ping/heartbeat
                    let heartbeat = ["type": "heartbeat"]
                    if let data = try? JSONEncoder().encode(heartbeat),
                       let text = String(data: data, encoding: .utf8) {
                        try await self.send(text)
                    }
                } catch {
                    #if DEBUG
                    print("[WebSocket] Heartbeat failed: \(error)")
                    #endif
                    await MainActor.run {
                        self.handleDisconnection(error: error)
                    }
                }
            }
        }
    }
    
    // MARK: - Reconnection
    
    private func handleDisconnection(error: Error?) {
        guard connectionState != .disconnected else { return }
        
        isConnected = false
        connectionState = .reconnecting
        onDisconnect?(error)
        
        guard reconnectAttempts < maxReconnectAttempts else {
            #if DEBUG
            print("[WebSocket] Max reconnection attempts reached")
            #endif
            connectionState = .disconnected
            return
        }
        
        let delay = baseReconnectDelay * pow(2.0, Double(reconnectAttempts))
        reconnectAttempts += 1
        
        #if DEBUG
        print("[WebSocket] Reconnecting in \(delay)s (attempt \(reconnectAttempts))")
        #endif
        
        reconnectTask?.cancel()
        reconnectTask = _Concurrency.Task { @MainActor in
            try? await _Concurrency.Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            await self.performConnect()
        }
    }
    
    func handleConnection() {
        isConnected = true
        connectionState = .connected
        reconnectAttempts = 0
        reconnectTask?.cancel()
        reconnectTask = nil
        
        #if DEBUG
        print("[WebSocket] Connected successfully")
        #endif
    }
    
    func handleClose(closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        let reasonString = reason.flatMap { String(data: $0, encoding: .utf8) } ?? "No reason"
        let closeCodeValue = closeCode.rawValue
        
        #if DEBUG
        print("[WebSocket] Closed with code: \(closeCodeValue) (\(closeCode)), reason: \(reasonString)")
        
        // Helpful error interpretation
        switch closeCodeValue {
        case 1001:
            print("[WebSocket] Interpretation: Going away (normal closure)")
        case 1002:
            print("[WebSocket] Interpretation: Protocol error")
        case 1003:
            print("[WebSocket] Interpretation: Unsupported data")
        case 1006:
            print("[WebSocket] Interpretation: Abnormal closure (connection lost)")
        case 1008:
            print("[WebSocket] Interpretation: Policy violation")
        case 1009:
            print("[WebSocket] Interpretation: Message too large")
        case 1011:
            print("[WebSocket] Interpretation: Server error (likely nginx routing or backend issue)")
        case 4001:
            print("[WebSocket] Interpretation: Unauthorized - Invalid or missing token")
        case 4003:
            print("[WebSocket] Interpretation: Forbidden - User ID mismatch")
        case 4004:
            print("[WebSocket] Interpretation: User not found")
        default:
            if closeCodeValue >= 4000 && closeCodeValue < 5000 {
                print("[WebSocket] Interpretation: Application-defined error")
            }
        }
        #endif
        
        // Notify listeners of close code for UI handling
        onClose?(closeCodeValue, reasonString)
        
        handleDisconnection(error: nil)
    }
}

// MARK: - WebSocket Delegate

private class WebSocketDelegate: NSObject, URLSessionWebSocketDelegate {
    weak var manager: WebSocketManager?
    
    override init() {
        super.init()
        // Manager will be set after initialization
    }
    
    nonisolated func urlSession(
        _ session: URLSession,
        webSocketTask: URLSessionWebSocketTask,
        didOpenWithProtocol protocol: String?
    ) {
        _Concurrency.Task { @MainActor in
            self.manager?.handleConnection()
        }
    }
    
    nonisolated func urlSession(
        _ session: URLSession,
        webSocketTask: URLSessionWebSocketTask,
        didCloseWith closeCode: URLSessionWebSocketTask.CloseCode,
        reason: Data?
    ) {
        _Concurrency.Task { @MainActor in
            self.manager?.handleClose(closeCode: closeCode, reason: reason)
        }
    }
}

// MARK: - Errors

enum WebSocketError: LocalizedError {
    case notConnected
    case invalidURL
    case encodingFailed
    
    var errorDescription: String? {
        switch self {
        case .notConnected:
            return "WebSocket is not connected"
        case .invalidURL:
            return "Invalid WebSocket URL"
        case .encodingFailed:
            return "Failed to encode message"
        }
    }
}

