//
//  ViewController.swift
//
//
//  Created by Jack Morrison on 14/10/2019.
//

import MultipeerConnectivity
import UIKit
import FlexColorPicker

class ViewController: UIViewController, MCSessionDelegate, MCBrowserViewControllerDelegate {
    
    @IBOutlet var drawView: DrawView!
    @IBOutlet var eraser: UIBarButtonItem!
    @IBOutlet var sessionDetails: UIBarButtonItem!
    @IBOutlet var shapeRecognition: UIBarButtonItem!
    @IBOutlet var colourPicker: UIBarButtonItem!
    
    var peerID: MCPeerID!
    var mcSession: MCSession!
    var mcAdvertiserAssistant: MCAdvertiserAssistant!
    let sb = UIStoryboard(name: "Main", bundle: nil)
    var colourPickerVC : ColourPickerViewController!

    override func viewDidLoad() {
        super.viewDidLoad()

        peerID = MCPeerID(displayName: UIDevice.current.name)
        mcSession = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        mcSession.delegate = self
        drawView.mcSession = mcSession
        colourPickerVC = sb.instantiateViewController(
            withIdentifier: "colourPickerViewController") as? ColourPickerViewController
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
    
    @IBAction func showSessionDetails() {
        print(mcSession.connectedPeers)
        let sessionDetailsVC = sb.instantiateViewController(
            withIdentifier: "sessionDetailsViewController") as! sessionDetailsViewController
        // Use the popover presentation style for your view controller.
        sessionDetailsVC.modalPresentationStyle = .popover

        // Specify the anchor point for the popover.
        sessionDetailsVC.popoverPresentationController?.barButtonItem =
                   sessionDetails
        
        sessionDetailsVC.datasourceArray = mcSession.connectedPeers
        

        // Present the view controller (in a popover).
        self.present(sessionDetailsVC, animated: true) {
           // The popover is visible.
        }
    }
    
    @IBAction func showColorPicker() {
        // Use the popover presentation style for your view controller.
        colourPickerVC.modalPresentationStyle = .popover

        // Specify the anchor point for the popover.
        colourPickerVC.popoverPresentationController?.barButtonItem =
                   colourPicker
        
        //colourPickerVC.datasourceArray = mcSession.connectedPeers
        colourPickerVC.mainViewController = self
        // Present the view controller (in a popover).
        self.present(colourPickerVC, animated: true) {
           // The popover is visible.
        }
        
        
    }
    
    func colourChange(_ sender: ColourPickerViewController) {
        let chosenColour = sender.selectedColor
        drawView.colourChosen(chosenColour)
        colourPicker.tintColor = chosenColour

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

