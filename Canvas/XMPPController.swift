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
    
    func connect() {
        if !self.xmppStream.isDisconnected {
            return
        }

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
    
    func returnMembers() -> [String] {
        
        room!.fetchMembersList()
        while (members == nil){
            members = []
            break
        }
        return members!
    }
}

extension XMPPController: XMPPRoomDelegate {
    func xmppRoomDidJoin(_ sender: XMPPRoom) {
        print("roomdidjoin", sender)
    }
    
    func xmppStream(_ sender: XMPPStream, didReceive message: XMPPMessage) {
        drawView?.incomingChange(message.body!)
    }
    
    func xmppRoom(_ sender: XMPPRoom, occupantDidJoin occupantJID: XMPPJID, with presence: XMPPPresence) {
        print("joined", occupantJID)
        AutomergeJavaScript.shared.getAllChanges() { (returnValue) in
            self.room!.sendMessage(withBody: returnValue)
        }
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
        let userID = XMPPJID(string: "test3@conference.cloud-vm-41-92.doc.ic.ac.uk")!
        let roomStorage = XMPPRoomCoreDataStorage.sharedInstance()!
        let room = XMPPRoom(roomStorage: roomStorage, jid: userID)
        self.room = room
        room.addDelegate(self, delegateQueue: DispatchQueue.main)
        room.activate(xmppStream)
        room.join(usingNickname: UIDevice.current.name, history: nil)
        //let message = XMPPMessage(messageType: XMPPMessage.MessageType.groupchat, to: userID, elementID: NSUUID().uuidString)
        //message.addBody("what's up")
        //self.xmppStream.send(message)
        print("Stream: Authenticated")
    }

    
    func xmppStream(_ sender: XMPPStream, didNotAuthenticate error: DDXMLElement) {
        print("Stream: Fail to Authenticate")
    }
}
