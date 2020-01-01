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
    var mcAdvertiserAssistant: MCAdvertiserAssistant!
    var mainViewController:ViewController?
    @IBOutlet var textField: UITextField!
    
    var datasourceArray : [String]?
    static let CELL_RESUE_ID = "POPOVER_CELL_REUSE_ID"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        textField.text = mainViewController!.currentRoom
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    @IBAction func changeRoom(sender: UITextField) {
        if (sender.text != nil) {
            mainViewController!.currentRoom = sender.text!
            print("** Disconnect XMPP")
            mainViewController!.xmppController!.disconnect()
            print("** Connect XMPP to room: ", sender.text!)
            mainViewController!.xmppController!.connect(sender.text!)
            
            mainViewController!.connectedDevices = []
            //Then update bluetooth room
            print("** Disconnect Bluetooth")
            mainViewController!.bluetoothService.disconnect()
            print("** Connect Bluetooth to room: ", sender.text!)
            mainViewController!.bluetoothService = BluetoothService(withRoomName: sender.text!)
            mainViewController!.bluetoothService.delegate = mainViewController!
            self.mainViewController!.drawView.sendPath(AutomergeJavaScript.shared.getAllChanges())
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

// A class for Text Fields which makes keyboards disappear when return is clicked
class TextFieldWithReturn: UITextField, UITextFieldDelegate
{

    required init?(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder)
        self.delegate = self
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool
    {
        textField.resignFirstResponder()
        return true
    }

}
