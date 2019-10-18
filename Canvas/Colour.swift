//
//  Colour.swift
//  Canvas
//
//  Created by Serene Chongtrakul on 14/10/2019.
//  Copyright © 2019 jackmorrison. All rights reserved.
//

import Foundation
import UIKit

enum Colour {
    case red
    case blue
    case yellow
    case green
    case white
  
    init?(tag: Int) {
        switch tag {
        case 1:
            self = .blue
        case 2:
            self = .green
        case 3:
            self = .yellow
        case 4:
            self = .red
        case 5:
            self = .white
        default:
            return nil
        }
    }
    
    var colour: UIColor {
        switch self {
        case .red:
            return .red
        case .blue:
            return .blue
        case .yellow:
            return .yellow
        case .green:
            return .green
        case .white:
            return .white
        }
    }
}
