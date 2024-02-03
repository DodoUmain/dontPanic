//
//  ContentView.swift
//  websocket
//
//  Created by Doortje Spanjerberg on 2024-02-02.
//

import SwiftUI

import Foundation

struct Cursor: Decodable, Identifiable {
    let id: String
    var y: Double
}

enum ServerMessage: Decodable {
    case InitialState(id: String, users: [Cursor])
    case ClientConnect(id: String)
    case ClientDisconnect(id: String)
    case CursorPress(id: String, y:Double)
    case CursorRelease(id: String, y:Double)
    case CursorMove(id: String, y:Double)
}

class WebSocketManager: ObservableObject {
    var webSocketTask: URLSessionWebSocketTask!
    
    @Published var cursors: [Cursor] = []
    
    func connectToWebSocket() {
        let url = URL(string: "ws://172.26.2.83:8000/ws")!
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
                    print("Received messagasdasde: \(text)")
                    
                    let decoder = JSONDecoder()
                    do{
                        // let somedata = Data(json.utf8)
                        let serverMessage = try decoder.decode(ServerMessage.self, from: text.data(using:.utf8)!)
                        
                        switch serverMessage {
                        case .InitialState(let id, let users):
                            self.cursors = users
                            print("z")
                        case .ClientConnect(let id):
                            print("a")
                            self.cursors.append(Cursor(id: id, y: 0.5))
                            
                        case .ClientDisconnect(id: let id):
                            print("b")
                            self.cursors.removeAll(where: {$0.id == id})
                            
                        case .CursorPress(id: let id, y: let y):
                            print("c")
                            
                        case .CursorRelease(id: let id, y: let y):
                            print("d")
                            
                        case .CursorMove(id: let id, y: let y):
                            if var index = self.cursors.firstIndex(where: {$0.id == id}) {
                                self.cursors[index].y = y
                            }
                            
                        }
                        
                    }catch let jsonErr {
                        print(jsonErr)
                    }
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
    @StateObject var webSocketManager = WebSocketManager()
    
    func makeConnection() {
        // Usage
        webSocketManager.connectToWebSocket()
        updatedText = "Hello, WebSocket!123"
    }
    
    
    var body: some View {
        GeometryReader { geo in
            
            ForEach(webSocketManager.cursors) { cursor in
                Text(String(cursor.id) + ": " + String(cursor.y)).offset(x:100, y: cursor.y * geo.size.height)
            }
        }
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
