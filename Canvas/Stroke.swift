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
        case .clearCanvas:
            try container.encode("CLEAR_CANVAS", forKey: CodingKeys.type)
        case let .removeStroke(i):
            try container.encode("REMOVE_STROKE", forKey: CodingKeys.type)
            try container.encode(i, forKey: CodingKeys.identifier)
        }
    }
    
    case addStroke(Stroke, String)
    case removeStroke(String)
    case addPoint([Point], String)
    case clearCanvas
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
    
    enum ActionType: String {
        case add
        case remove
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
    
    func contains(givenPoint: Point) -> Bool {
        for point in points {
            if ((givenPoint.x <= point.x + 10 && givenPoint.x >= point.x - 10) && (givenPoint.y <= point.y + 10 && givenPoint.y >= point.y - 10)) {
                return true;
            }
        }
        return false;
    }
    
    var cgPath: CGPath {
        get {
            var pPrevPoint: Point!
            var prevPoint: Point!
            let path = UIBezierPath.init()
            path.lineCapStyle = CGLineCap.round
            path.lineWidth = 3
            for i in 0...points.count - 1 {
                let point = points[i]
                if i == 0 {
                    path.move(to: point.cgPoint)
                } else if i >= 2 {
                    let cp1 = Point(
                        x: (2 * pPrevPoint.x + prevPoint.x) / 3,
                        y: (2 * pPrevPoint.y + prevPoint.y) / 3
                    )
                    let cp2 = Point(
                        x: (pPrevPoint.x + 2 * prevPoint.x) / 3,
                        y: (pPrevPoint.y + 2 * prevPoint.y) / 3
                    )
                    let end = Point(
                        x: (pPrevPoint.x + 4 * prevPoint.x + point.x) / 6,
                        y: (pPrevPoint.y + 4 * prevPoint.y + point.y) / 6
                    )
                    path.addCurve(to: end.cgPoint, controlPoint1: cp1.cgPoint, controlPoint2: cp2.cgPoint)
                }
                
                pPrevPoint = prevPoint
                prevPoint = point
            }
            return path.cgPath
        }
    }
}
