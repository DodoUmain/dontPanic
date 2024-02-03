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
    var isPressed: Bool
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
    
    @Published var id: String = "";
    @Published var cursors: [Cursor] = []
    
    func connectToWebSocket() {
        let url = URL(string: "ws://192.168.0.137:8000/ws")!
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
                    //                    print("Received messagasdasde: \(text)")
                    
                    let decoder = JSONDecoder()
                    do{
                        // let somedata = Data(json.utf8)
                        let serverMessage = try decoder.decode(ServerMessage.self, from: text.data(using:.utf8)!)
                        
                        switch serverMessage {
                        case .InitialState(let id, let users):
                            self.cursors = users
                            self.id = id;
                        case .ClientConnect(let id):
                            self.cursors.append(Cursor(id: id, y: 0.5, isPressed: false))
                            
                        case .ClientDisconnect(id: let id):
                            self.cursors.removeAll(where: {$0.id == id})
                            
                        case .CursorPress(id: let id, y: let y):
                            if var index = self.cursors.firstIndex(where: {$0.id == id}) {
                                self.cursors[index].isPressed = true
                            }
                        case .CursorRelease(id: let id, y: let y):
                            if var index = self.cursors.firstIndex(where: {$0.id == id}) {
                                self.cursors[index].isPressed = false
                            }
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
    
    //    var drag: some Gesture {
    //        DragGesture()
    //            .onChanged { x in print(x) }
    //            .onEnded { x in print(x)}
    //    }
    
    @FocusState var focused1
    
    
    var body: some View {
        VStack {
            GeometryReader { geo in
                ForEach(webSocketManager.cursors) { cursor in
                    Text(String(cursor.id) + ": " + String(cursor.y) + "- " + String(cursor.isPressed)).offset(x:100, y: cursor.y * geo.size.height)
                }
            }
        }
        .focusable(true)
        .focused($focused1)
        .onTapGesture {
            print("clicked 1")
        }
        .onKeyPress(.upArrow) {
            print("up")
            return .handled
        }
        .background(.red)
        .task(makeConnection)
        .frame( maxWidth: .infinity, maxHeight: .infinity)
        
    }
}

#Preview {
    ContentView()
}
