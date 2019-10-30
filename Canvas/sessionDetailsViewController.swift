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
    
    var datasourceArray : [MCPeerID]?
    static let CELL_RESUE_ID = "POPOVER_CELL_REUSE_ID"
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
}
extension sessionDetailsViewController:UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Active Users"
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print(datasourceArray)
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
