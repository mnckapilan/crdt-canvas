//
//  XMPPController.swift
//  Canvas
//
//  Created by Kapilan M on 13/11/2019.
//  Copyright © 2019 jackmorrison. All rights reserved.
//

import Foundation
import XMPPFrameworkSwift

enum XMPPControllerError: Error {
    case wrongUserJID
}

class XMPPController: NSObject {
    var xmppStream: XMPPStream
    
    let hostName: String
    let userJID: XMPPJID
    let hostPort: UInt16
    let password: String
    var room: XMPPRoom?
    var drawView: DrawView?
    var members: [String]?
    var currentRoom: String?
    var mainViewController : ViewController?
    
    init(hostName: String, userJIDString: String, hostPort: UInt16 = 5222, password: String) throws {
        guard let userJID = XMPPJID(string: userJIDString) else {
            throw XMPPControllerError.wrongUserJID
        }
        
        self.hostName = hostName
        self.userJID = userJID
        self.hostPort = hostPort
        self.password = password
        
        // Stream Configuration
        self.xmppStream = XMPPStream()
        self.xmppStream.hostName = hostName
        self.xmppStream.hostPort = hostPort
        self.xmppStream.startTLSPolicy = XMPPStreamStartTLSPolicy.allowed
        self.xmppStream.myJID = userJID
        
        super.init()
        
        self.xmppStream.addDelegate(self, delegateQueue: DispatchQueue.main)
    }
    
    func connect(_ name: String) {
        if !self.xmppStream.isDisconnected {
            return
        }
        self.currentRoom = name
        try! self.xmppStream.connect(withTimeout: XMPPStreamTimeoutNone)
    }
    
    func disconnect() {
        if self.xmppStream.isDisconnected {
            return
        }
        
        self.xmppStream.disconnect()
    }
    
    func isConnected() -> Bool {
        return self.xmppStream.isConnected
    }
    
}

extension XMPPController: XMPPRoomDelegate {
    func xmppRoomDidJoin(_ sender: XMPPRoom) {
        print("roomdidjoin", sender)
    }
    
    func xmppStream(_ sender: XMPPStream, didReceive message: XMPPMessage) {
        // If it is the master, then render it and also send it over bluetooth to every other device
        if (mainViewController!.isMaster && message.body != nil) {
            drawView?.incomingChange(message.body!)
            mainViewController!.bluetoothService.send(data: message.body!)
        }
    }
    
    func xmppRoom(_ sender: XMPPRoom, occupantDidJoin occupantJID: XMPPJID, with presence: XMPPPresence) {
        print("joined", occupantJID)
        self.room!.sendMessage(withBody: self.drawView!.engine.getAllChanges())
    }
    
    func xmppRoom(_ sender: XMPPRoom, occupantDidLeave occupantJID: XMPPJID, with presence: XMPPPresence) {
        print("left", occupantJID)
    }
    
    func xmppRoom(_ sender: XMPPRoom, didFetchMembersList items: [Any]) {
        print(items)
    }
    
}

extension XMPPController: XMPPStreamDelegate {
    
    func xmppStreamDidConnect(_ stream: XMPPStream) {
        print("Stream: Connected")
        try! stream.authenticate(withPassword: self.password)
    }
    
    func xmppStreamDidAuthenticate(_ sender: XMPPStream) {
        self.xmppStream.send(XMPPPresence())
        let userID = XMPPJID(string: self.currentRoom! + "@conference.cloud-vm-41-92.doc.ic.ac.uk")!
        let roomStorage = XMPPRoomCoreDataStorage.sharedInstance()!
        let room = XMPPRoom(roomStorage: roomStorage, jid: userID)
        self.room = room
        room.addDelegate(self, delegateQueue: DispatchQueue.main)
        room.activate(xmppStream)
        room.join(usingNickname: UIDevice.current.name, history: nil)
        print("Stream: Authenticated")
    }

    
    func xmppStream(_ sender: XMPPStream, didNotAuthenticate error: DDXMLElement) {
        print("Stream: Fail to Authenticate")
    }
}
