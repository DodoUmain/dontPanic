//
//  ContentView.swift
//  websocket
//
//  Created by Doortje Spanjerberg on 2024-02-02.
//

import SwiftUI

import Foundation

class WebSocketManager {
    var webSocketTask: URLSessionWebSocketTask!
    
    func connectToWebSocket() {
        let url = URL(string: "ws://192.168.142.103:8000/ws")!
        let request = URLRequest(url: url)
        
        webSocketTask = URLSession.shared.webSocketTask(with: request)
        
        webSocketTask.resume()
        
        receiveMessages()
    }
    
    func receiveMessages() {
        webSocketTask.receive { result in
            switch result {
            case .success(let message):
                switch message {
                case .data(let data):
                    // Handle received data
                    let receivedString = String(data: data, encoding: .utf8)
                    print("Received message: \(receivedString ?? "")")
                case .string(let text):
                    // Handle received text
                    print("Received message: \(text)")
                }
                
                // Continue to receive more messages
                self.receiveMessages()
                
            case .failure(let error):
                print("WebSocket error: \(error)")
            }
        }
    }
    
    func sendMessage(message: String) {
        let messageData = URLSessionWebSocketTask.Message.string(message)
        webSocketTask.send(messageData) { error in
            if let error = error {
                print("Error sending message: \(error)")
            }
        }
    }
    
    func disconnect() {
        webSocketTask.cancel(with: .goingAway, reason: nil)
    }
}

// To disconnect
// webSocketManager.disconnect()


struct ContentView: View {
    @State var updatedText = "Connecting!!!!"
    func makeConnection() {
        // Usage
        let webSocketManager = WebSocketManager()
        webSocketManager.connectToWebSocket()
        webSocketManager.sendMessage(message: "Hello, WebSocket!123")
        updatedText = "Hello, WebSocket!123"
    }
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text(updatedText).task(delayText)
        }
        .padding()
        .onAppear {
           
        }
    }
    
    func delayText() async {
        try? await Task.sleep(nanoseconds: 3_000_000_000)
        makeConnection()
    }
}

#Preview {
    ContentView()
}
