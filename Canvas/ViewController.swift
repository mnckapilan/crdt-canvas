//
//  ViewController.swift
//
//
//  Created by Jack Morrison on 14/10/2019.
//

import MultipeerConnectivity
import UIKit

class ViewController: UIViewController, MCSessionDelegate, MCBrowserViewControllerDelegate {
    
    @IBOutlet var drawView: DrawView!
    @IBOutlet var blueBtn: UIBarButtonItem!
    @IBOutlet var greenBtn: UIBarButtonItem!
    @IBOutlet var yellowBtn: UIBarButtonItem!
    @IBOutlet var redBtn: UIBarButtonItem!
    @IBOutlet var whiteBtn: UIBarButtonItem!
    @IBOutlet var eraser: UIBarButtonItem!

    var peerID: MCPeerID!
    var mcSession: MCSession!
    var mcAdvertiserAssistant: MCAdvertiserAssistant!

    override func viewDidLoad() {
        super.viewDidLoad()

        peerID = MCPeerID(displayName: UIDevice.current.name)
        mcSession = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        mcSession.delegate = self
        drawView.mcSession = mcSession
    }

    @IBAction func showConnectionPrompt() {
        let ac = UIAlertController(title: "Connect to others", message: nil, preferredStyle: .actionSheet)
        ac.addAction(UIAlertAction(title: "Host a session", style: .default, handler: startHosting))
        ac.addAction(UIAlertAction(title: "Join a session", style: .default, handler: joinSession))
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        if let popoverController = ac.popoverPresentationController {
               popoverController.sourceView = self.view
               popoverController.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
               popoverController.permittedArrowDirections = []
           }
        
        present(ac, animated: true)
    }
    
    @IBAction func btnClicked(_ sender: UIBarButtonItem) {
        let btnTag = sender.tag
        let buttons: [UIBarButtonItem] = [blueBtn, greenBtn, yellowBtn, redBtn, whiteBtn]
        
//        for i in 1...5 {
//            if (i == btnTag) {
//                buttons[i - 1].isSelected = true
//            } else {
//                buttons[i - 1].isSelected = false
//            }
//        }
//
//        if (btnTag == 20) {
//            eraser.isSelected = true
//        } else {
//            eraser.isSelected = false
//        }
    }

    func startHosting(action: UIAlertAction) {
        mcAdvertiserAssistant = MCAdvertiserAssistant(serviceType: "hws-project25", discoveryInfo: nil, session: mcSession)
        mcAdvertiserAssistant.start()
    }

    func joinSession(action: UIAlertAction) {
        let mcBrowser = MCBrowserViewController(serviceType: "hws-project25", session: mcSession)
        mcBrowser.delegate = self
        present(mcBrowser, animated: true)
    }

    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {

    }

    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {

    }

    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {

    }

    func browserViewControllerDidFinish(_ browserViewController: MCBrowserViewController) {
        dismiss(animated: true)
    }

    func browserViewControllerWasCancelled(_ browserViewController: MCBrowserViewController) {
        dismiss(animated: true)
    }

    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        switch state {
        case MCSessionState.connected:
            print("Connected: \(peerID.displayName)")
            AutomergeJavaScript.shared.getAllChanges() { (returnValue) in
                self.drawView.sendPath(returnValue)
            }

        case MCSessionState.connecting:
            print("Connecting: \(peerID.displayName)")

        case MCSessionState.notConnected:
            print("Not Connected: \(peerID.displayName)")
        @unknown default:
            print("fatal error")
        }
    }

    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        do {
            let data = String(data: data, encoding: .utf8)!
            DispatchQueue.main.async { [unowned self] in
                print("here")
                self.drawView.incomingChange(data)
            }
        } catch {
            print(error)
        }
        
    }
    
    @IBAction func disconnectSession() {
        mcSession.disconnect();
        print("Disconnected");
    }
}

