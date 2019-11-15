//
//  sessionDetailsViewController.swift
//  Canvas
//
//  Created by Jack Morrison on 30/10/2019.
//  Copyright © 2019 jackmorrison. All rights reserved.
//

import Foundation
import MultipeerConnectivity
import UIKit

class sessionDetailsViewController: UIViewController {
    @IBOutlet var tableView: UITableView!
    @IBOutlet var connectButton: UIButton!
    @IBOutlet var disconnectButton: UIButton!
    @IBOutlet var connectionTypeButton: UIButton!
    var mcAdvertiserAssistant: MCAdvertiserAssistant!
    var mainViewController:ViewController?
    
    var datasourceArray : [String]?
    static let CELL_RESUE_ID = "POPOVER_CELL_REUSE_ID"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if (((mainViewController!.isBluetooth)&&(mainViewController?.mcSession.connectedPeers.count == 0)) || (!mainViewController!.isBluetooth) && (!(mainViewController?.xmppController?.isConnected())!)) {
            disconnectButton.tintColor = UIColor.red
            disconnectButton.setBackgroundImage(UIImage(systemName: "wifi.slash"), for: .normal)
        } else {
            disconnectButton.tintColor = UIColor.green
            disconnectButton.setBackgroundImage(UIImage(systemName: "wifi"), for: .normal)
        }
        if mainViewController!.isBluetooth {
            print("** Connection type is Bluetooth")
            connectionTypeButton.setTitle("Bluetooth", for: UIControl.State.normal)
        } else {
            print("** Connection type is XMPP")
            connectionTypeButton.setTitle("XMPP", for: UIControl.State.normal)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    @IBAction func showConnectionPrompt() {
        if (mainViewController!.isBluetooth){
            print("** Connect Bluetooth")
            self.dismiss(animated: true, completion: nil)
            mainViewController?.showConnectionPrompt()
        } else {
            print("** Connect XMPP")
            //XMPP Join Room
            mainViewController!.xmppController!.connect()
        }
    }
    
    @IBAction func disconnectSession() {
        if (mainViewController!.isBluetooth){
            print("** Disconnect Bluetooth")
            mainViewController?.disconnectSession();
            disconnectButton.tintColor = UIColor.red
            disconnectButton.setBackgroundImage(UIImage(systemName: "wifi.slash"), for: .normal)
        } else {
            //XMPP Leave Room
            print("** Disconnect XMPP")
            mainViewController!.xmppController!.disconnect()
            disconnectButton.tintColor = UIColor.red
            disconnectButton.setBackgroundImage(UIImage(systemName: "wifi.slash"), for: .normal)
        }
    }
    
    @IBAction func changeConnectionType() {
        if mainViewController!.isBluetooth {
            print("** Connection type set to XMPP")
            disconnectSession()
            mainViewController!.isBluetooth = false
            connectionTypeButton.setTitle("XMPP", for: UIControl.State.normal)
        } else {
            print("** Connection type set to Bluetooth")
            disconnectSession()
            mainViewController!.isBluetooth = true
            connectionTypeButton.setTitle("Bluetooth", for: UIControl.State.normal)
            //Disconnect XMPP
        }
    }

    
}
extension sessionDetailsViewController:UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Active Users"
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return datasourceArray!.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: sessionDetailsViewController.CELL_RESUE_ID)
        if cell == nil {
            cell = UITableViewCell(style: .default, reuseIdentifier: sessionDetailsViewController.CELL_RESUE_ID)
        }
        cell?.textLabel?.text = datasourceArray![indexPath.row]
        return cell ?? UITableViewCell()
    }
    
}
