//
//  Stroke.swift
//  Canvas
//
//  Created by Hashan Punchihewa on 21/10/2019.
//  Copyright © 2019 jackmorrison. All rights reserved.
//

import Foundation
import UIKit
import CoreGraphics

class Point: Codable, Equatable, CustomStringConvertible {
    static func == (lhs: Point, rhs: Point) -> Bool {
        return lhs.x == rhs.x && lhs.y == rhs.y
    }
    
    var x: Float
    var y: Float
    
    convenience init(fromCGPoint cgPoint: CGPoint) {
        self.init(x: Float(cgPoint.x), y: Float(cgPoint.y))
    }
    
    init(x: Float, y: Float) {
        self.x = x
        self.y = y
    }
    
    var cgPoint: CGPoint {
        get {
            return CGPoint(x: CGFloat(x), y: CGFloat(y))
        }
    }
    
    public var description: String { return "x: \(x) y: \(y)" }
}

enum Change: Encodable {
    enum CodingKeys: String, CodingKey {
        case type
        case stroke
        case point
        case identifier
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case let .addPoint(point, i):
            try container.encode("ADD_POINT", forKey: CodingKeys.type)
            try container.encode(point, forKey: CodingKeys.point)
            try container.encode(i, forKey: CodingKeys.identifier)
        case let .addStroke(stroke, i):
            try container.encode("ADD_STROKE", forKey: CodingKeys.type)
            try container.encode(stroke, forKey: CodingKeys.stroke)
            try container.encode(i, forKey: CodingKeys.identifier)
        case let .clearCanvas(i):
            try container.encode("CLEAR_CANVAS", forKey: CodingKeys.type)
            try container.encode(i, forKey: CodingKeys.identifier)
        case let .clearCanvas(i):
            try container.encode("UNDO_CHANGE", forKey: CodingKeys.type)
            try container.encode(i, forKey: CodingKeys.identifier)
        }
        case let .clearCanvas(i):
            try container.encode("REDO_CHANGE", forKey: CodingKeys.type)
            try container.encode(i, forKey: CodingKeys.identifier)
        }
    }
    
    case addStroke(Stroke, String)
    case addPoint([Point], String)
    case clearCanvas(String)
    case undoChange(String)
    case redoChange(String)
}

class Stroke: Codable {
    var points: [Point]
    var colour: UIColor

    enum ColourCodingKeys: String, CodingKey {
        case red
        case green
        case blue
        case alpha
    }
    
    enum CodingKeys: String, CodingKey {
        case points
        case colour
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        points = try container.decode([Point].self, forKey: CodingKeys.points)
        
        let nested = try container.nestedContainer(keyedBy: ColourCodingKeys.self, forKey: CodingKeys.colour)
        let red = try nested.decode(CGFloat.self, forKey: ColourCodingKeys.red)
        let green = try nested.decode(CGFloat.self, forKey: ColourCodingKeys.green)
        let blue = try nested.decode(CGFloat.self, forKey: ColourCodingKeys.blue)
        let alpha = try nested.decode(CGFloat.self, forKey: ColourCodingKeys.alpha)
        colour = UIColor(red: red, green: green, blue: blue, alpha: alpha)
    }
    
    init(points: [Point], colour: UIColor) {
        self.points = points
        self.colour = colour
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(points, forKey: CodingKeys.points)
        
        var nested = container.nestedContainer(keyedBy: ColourCodingKeys.self, forKey: CodingKeys.colour)
        
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        colour.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        try nested.encode(red, forKey: ColourCodingKeys.red)
        try nested.encode(green, forKey: ColourCodingKeys.green)
        try nested.encode(blue, forKey: ColourCodingKeys.blue)
        try nested.encode(alpha, forKey: ColourCodingKeys.alpha)
    }
    
    var cgPath: CGPath {
        get {
            var pPrevPoint: CGPoint!
            var prevPoint: CGPoint!
            var c = 0
            let path = UIBezierPath.init()
            path.lineCapStyle = CGLineCap.round
            path.lineWidth = 3
            for point in points {
                if c == 0 {
                    path.move(to: point.cgPoint)
                } else if c == 1 {
                    pPrevPoint = point.cgPoint
                } else if c == 2 {
                    prevPoint = point.cgPoint
                } else  if c == 3 {
                    path.addCurve(to: point.cgPoint, controlPoint1: pPrevPoint, controlPoint2: prevPoint)
                    c = 0
                }
                c += 1
            }
            return path.cgPath
        }
    }
}
