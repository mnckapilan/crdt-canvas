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
    @IBOutlet var slider: UISlider!
    
    var mainViewController:ViewController?
    var thickness : Float?
    
    @IBAction func sliderValueChanged(_ sender: Any) {
        thickness = slider.value
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        slider.setValue(thickness!, animated: true)
        super.selectedColor = UIColor.blue
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        mainViewController?.colourChange(self)
    }
    
}
