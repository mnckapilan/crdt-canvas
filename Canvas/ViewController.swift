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
import Network

class ViewController: UIViewController {
    
    @IBOutlet var drawView: DrawView!
    @IBOutlet var sessionDetails: UIBarButtonItem!
    @IBOutlet var colourPicker: UIBarButtonItem!
    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var gestureRecogniser: UIPanGestureRecognizer!
    
    var peerID: MCPeerID!
    var mcAdvertiserAssistant: MCAdvertiserAssistant!
    let sb = UIStoryboard(name: "Main", bundle: nil)
    var colourPickerVC: ColourPickerViewController!
    var xmppController: XMPPController?
    var connectedDevices: [String]?
    var bluetoothService = BluetoothService(withRoomName: "imperial")
    var isMaster = true
    var currentRoom = "imperial"
    var centreX: CGFloat!
    var centreY: CGFloat!
    var monitor = NWPathMonitor()
    var connected = true

    override func viewDidLoad() {
        super.viewDidLoad()

        peerID = MCPeerID(displayName: UIDevice.current.name)
        drawView.bluetoothService = bluetoothService
        colourPickerVC = sb.instantiateViewController(
            withIdentifier: "colourPickerViewController") as? ColourPickerViewController
        colourPicker.tintColor = UIColor.blue
        try! self.xmppController = XMPPController(hostName: "xmpp.lets-draw.live",
        userJIDString: "grouptwo@xmpp.lets-draw.live",
             password: "grouptwo")
                
        self.xmppController!.connect(currentRoom)
        drawView.xmppController = self.xmppController
        self.xmppController!.drawView = drawView
        drawView.mainViewController = self
        self.xmppController!.mainViewController = self
        
        bluetoothService.delegate = self
        
        scrollView.panGestureRecognizer.minimumNumberOfTouches = 2
        scrollView.panGestureRecognizer.maximumNumberOfTouches = 2
        
        gestureRecogniser.minimumNumberOfTouches = 2
        gestureRecogniser.maximumNumberOfTouches = 2
        
        connectedDevices = []
        
        centreX = drawView.center.x
        centreY = drawView.center.y
        
        monitor.pathUpdateHandler = { path in
            if path.status == .satisfied {
                print("** Internet Connected")
                // Ask for all changes from someone
                self.xmppController!.disconnect()
                self.xmppController!.connect(self.currentRoom)
                self.connected = true
                
            } else {
                print("** Internet Disconnected")
                // Have an icon which displays the status of internet and bluetooth
                self.connected = false
            }
        }
        
        let queue = DispatchQueue(label: "Monitor")
        monitor.start(queue: queue)
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

    
    @IBAction func showSessionDetails() {
        let sessionDetailsVC = sb.instantiateViewController(
            withIdentifier: "sessionDetailsViewController") as! sessionDetailsViewController
        // Use the popover presentation style for your view controller.
        sessionDetailsVC.modalPresentationStyle = .popover

        // Specify the anchor point for the popover.
        sessionDetailsVC.popoverPresentationController?.barButtonItem = sessionDetails
        
        if (connectedDevices != nil) {
            sessionDetailsVC.datasourceArray = connectedDevices!
        } else {
            sessionDetailsVC.datasourceArray = []
        }

        sessionDetailsVC.mainViewController = self

        // Present the view controller (in a popover).
        self.present(sessionDetailsVC, animated: true) {
           // The popover is visible.
        }
    }
    
    @IBAction func showColorPicker() {
        // Use the popover presentation style for your view controller.
        drawView!.mode = .DRAWING
        drawView!.setButtonColour()
        colourPickerVC.modalPresentationStyle = .popover

        // Specify the anchor point for the popover.
        colourPickerVC.popoverPresentationController?.barButtonItem =
                   colourPicker
        
        //colourPickerVC.datasourceArray = mcSession.connectedPeers
        colourPickerVC.mainViewController = self
        colourPickerVC.thickness = self.drawView.thickness
        // Present the view controller (in a popover).
        self.present(colourPickerVC, animated: true) {
           // The popover is visible.
        }
    }
    
    func colourChange(_ sender: ColourPickerViewController) {
        let chosenColour = sender.selectedColor
        let chosenThickness = sender.thickness!
        drawView.colourChosen(chosenColour, chosenThickness)
        colourPicker.tintColor = chosenColour
    }
    

}


extension ViewController : BluetoothServiceDelegate {
    
    func receiveData(manager: BluetoothService, data: String) {
        DispatchQueue.main.async { [unowned self] in
            // Only do this if the change's user is not myself?
            print("** Recieving data via bluetooth")
            self.drawView.incomingChange(data)
            //Send to XMPP if master
            if (self.isMaster) {
                if self.xmppController!.isConnected(){
                    self.xmppController!.room!.sendMessage(withBody: data)
                }
            }
            
        }
    }
    

    func connectedDevicesChanged(manager: BluetoothService, connectedDevices: [String]) {
        OperationQueue.main.addOperation {
            print("** Connected devices via bluetooth changed")
            if (connectedDevices.count > 0) {
                if (connectedDevices.count > 1){
                    self.connectedDevices = connectedDevices.sorted{$0 < $1}
                } else {
                    self.connectedDevices = connectedDevices
                }
                print("** Connected Devices: ", connectedDevices)
                self.isMaster = !(connectedDevices[0] > self.peerID.displayName)
                print("** Is master: ", self.isMaster)
                
                //New person joined room, so send them all the changes
                
                self.drawView.sendPath(self.drawView.engine.getAllChanges())
            } else {
                self.connectedDevices = []
                self.isMaster = true
            }
        }
    }
    
    


}
