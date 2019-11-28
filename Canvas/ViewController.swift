//
//  ViewController.swift
//
//
//  Created by Jack Morrison on 14/10/2019.
//

import MultipeerConnectivity
import UIKit
import FlexColorPicker
import XMPPFrameworkSwift

class ViewController: UIViewController, MCSessionDelegate, MCBrowserViewControllerDelegate {
    
    @IBOutlet var drawView: DrawView!
    @IBOutlet var eraser: UIBarButtonItem!
    @IBOutlet var sessionDetails: UIBarButtonItem!
    @IBOutlet var shapeRecognition: UIBarButtonItem!
    @IBOutlet var colourPicker: UIBarButtonItem!
    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var gestureRecogniser: UIPanGestureRecognizer!
    
    var peerID: MCPeerID!
    var mcSession: MCSession!
    var mcAdvertiserAssistant: MCAdvertiserAssistant!
    let sb = UIStoryboard(name: "Main", bundle: nil)
    var colourPickerVC : ColourPickerViewController!
    var xmppController : XMPPController?
    var isBluetooth = true
    var connectedDevices : [String]?
    let bluetoothService = BluetoothService()
    var isMaster = false
    
    var centreX : CGFloat!
    var centreY : CGFloat!

    override func viewDidLoad() {
        super.viewDidLoad()

        peerID = MCPeerID(displayName: UIDevice.current.name)
        mcSession = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        mcSession.delegate = self
        drawView.mcSession = mcSession
        drawView.bluetoothService = bluetoothService
        colourPickerVC = sb.instantiateViewController(
            withIdentifier: "colourPickerViewController") as? ColourPickerViewController
        
        try! self.xmppController = XMPPController(hostName: "cloud-vm-41-92.doc.ic.ac.uk",
        userJIDString: "jack@cloud-vm-41-92.doc.ic.ac.uk",
             password: "testtest")
        
        self.xmppController!.connect("jacksroom")
        drawView.xmppController = self.xmppController
        self.xmppController!.drawView = drawView
        
        bluetoothService.delegate = self
        
        scrollView.panGestureRecognizer.minimumNumberOfTouches = 2
        scrollView.panGestureRecognizer.maximumNumberOfTouches = 2
        
        gestureRecogniser.minimumNumberOfTouches = 2
        gestureRecogniser.maximumNumberOfTouches = 2
        
        connectedDevices = []
        
        centreX = drawView.center.x
        centreY = drawView.center.y
    }
    
    @IBAction func getGesture(_ gesture : UIPanGestureRecognizer){
        gesture.minimumNumberOfTouches = 2
        gesture.maximumNumberOfTouches = 2
        let move = gesture.translation(in: gesture.view!.superview)
        drawView.center.x = move.x + centreX
        drawView.center.y = move.y + centreY
        
        if gesture.state  == .ended {
            centreX += move.x
            centreY += move.y
        }
        
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
        if (isBluetooth){
            sessionDetailsVC.datasourceArray = connectedDevices! //mcSession.connectedPeers.map{$0.displayName}
        } else {
            sessionDetailsVC.datasourceArray = [] //self.xmppController!.returnMembers()
            
        }

        sessionDetailsVC.mainViewController = self
        

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
    }
}


extension ViewController : BluetoothServiceDelegate {
    
    func receiveData(manager: BluetoothService, data: String) {
        do {
            DispatchQueue.main.async { [unowned self] in
                print("here")
                self.drawView.incomingChange(data)
            }
        } catch {
            print(error)
        }
    }
    

    func connectedDevicesChanged(manager: BluetoothService, connectedDevices: [String]) {
        OperationQueue.main.addOperation {
            self.connectedDevices = connectedDevices
            print(connectedDevices)
            // iterate over list of devices, if one has name before alphabetically, then not master
        }
    }


}
