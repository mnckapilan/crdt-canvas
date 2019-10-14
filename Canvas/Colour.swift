//
//  Colour.swift
//  Canvas
//
//  Created by Serene Chongtrakul on 14/10/2019.
//  Copyright © 2019 jackmorrison. All rights reserved.
//

import SwiftUI
import Foundation
import UIKit

enum Colour {
    case pink
    case blue
    case yellow
    case green
  
    init?(tag: Int) {
        print(tag)
        switch tag {
            case 1:
                self = .blue
            case 2:
                self = .green
            case 3:
                self = .yellow
            case 4:
                self = .pink
            default:
                return nil
            }
    }
    
    var colour: UIColor {
        switch self {
            case .pink:
              return .systemPink
            case .blue:
                return .blue
            case .yellow:
                return .yellow
            case .green:
                return .green
        }
    }
}
