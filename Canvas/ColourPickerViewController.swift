//
//  ColourPickerViewController.swift
//  Canvas
//
//  Created by Jack Morrison on 06/11/2019.
//  Copyright © 2019 jackmorrison. All rights reserved.
//

import Foundation
import UIKit
import FlexColorPicker

class ColourPickerViewController: DefaultColorPickerViewController {
    
    var mainViewController:ViewController?
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        mainViewController?.colourChange(self)
    }
    
}
