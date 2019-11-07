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
    var mcAdvertiserAssistant: MCAdvertiserAssistant!
    var mainViewController:ViewController?
    
    var datasourceArray : [MCPeerID]?
    static let CELL_RESUE_ID = "POPOVER_CELL_REUSE_ID"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if (mainViewController?.mcSession.connectedPeers.count == 0) {
            disconnectButton.tintColor = UIColor.red
            disconnectButton.setBackgroundImage(UIImage(systemName: "wifi.slash"), for: .normal)
        } else {
            disconnectButton.tintColor = UIColor.green
            disconnectButton.setBackgroundImage(UIImage(systemName: "wifi"), for: .normal)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    @IBAction func showConnectionPrompt() {
        self.dismiss(animated: true, completion: nil)
        mainViewController?.showConnectionPrompt()
    }
    
    @IBAction func disconnectSession() {
        mainViewController?.disconnectSession();
        disconnectButton.tintColor = UIColor.red
        disconnectButton.setBackgroundImage(UIImage(systemName: "wifi.slash"), for: .normal)
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
        cell?.textLabel?.text = datasourceArray![indexPath.row].displayName
        return cell ?? UITableViewCell()
    }
    
}
