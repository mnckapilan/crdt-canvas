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
        case index
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
        case let .removeStroke(str, i):
            try container.encode("REMOVE_STROKE", forKey: CodingKeys.type)
            try container.encode(str, forKey: CodingKeys.identifier)
            try container.encode(i, forKey: CodingKeys.index)
        case let .partialRemoveStroke(str, i):
            try container.encode("PARTIAL_REMOVE_STROKE", forKey: CodingKeys.type)
            try container.encode(str, forKey: CodingKeys.identifier)
            try container.encode(i, forKey: CodingKeys.index)
        }
    }
    
    case addStroke(Stroke, String)
    case removeStroke(String, Int)
    case addPoint([Point], String)
    case clearCanvas
    case partialRemoveStroke(String, Int)
}

enum Mode {
    case DRAWING
    case COMPLETE_REMOVE
    case PARTIAL_REMOVE
}

class Segment: Codable {
    var start: Int
    var end: Int
    
    enum CodingKeys: String, CodingKey {
        case start
        case end
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        start = try container.decode(Int.self, forKey: CodingKeys.start)
        end = try container.decode(Int.self, forKey: CodingKeys.end)
    }
    
    init(_ start: Int, _ end: Int) {
        self.start = start
        self.end = end
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(start, forKey: CodingKeys.start)
        try container.encode(end, forKey: CodingKeys.end)
    }

}

class Stroke: Codable {
    var points: [Point]
    var colour: UIColor
    var segments: [Segment]

    enum ColourCodingKeys: String, CodingKey {
        case red
        case green
        case blue
        case alpha
    }
    
    enum CodingKeys: String, CodingKey {
        case points
        case colour
        case segments
    }
    
    enum ActionType: String {
        case add
        case remove
        case redraw
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        points = try container.decode([Point].self, forKey: CodingKeys.points)
        segments = try container.decode([Segment].self, forKey: CodingKeys.segments)
        
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
        self.segments = [Segment(0, self.points.count - 1)]
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(points, forKey: CodingKeys.points)
        try container.encode(segments, forKey: CodingKeys.segments)
        
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
        return indexOf(givenPoint: givenPoint) != nil
    }
    
    func indexOf(givenPoint: Point) -> Int? {
        for segment in segments {
            for i in segment.start...segment.end {
                let point = points[i]
                if ((givenPoint.x <= point.x + 10 && givenPoint.x >= point.x - 10) && (givenPoint.y <= point.y + 10 && givenPoint.y >= point.y - 10)) {
                    return i;
                }
            }
        }
        return nil;
    }
    
    var cgPath: CGPath {
        get {
            var pPrevPoint: Point!
            var prevPoint: Point!
            let path = UIBezierPath.init()
            path.lineCapStyle = CGLineCap.round
            path.lineWidth = 3
            
            for segment in segments {
                print(segment.start, " ", segment.end)
                var s = 0
                
                if segment.start > segment.end {
                    continue
                }
                
                for i in segment.start...segment.end {
                    let point = points[i]
                    
                    if s == 0 {
                        path.move(to: point.cgPoint)
                    } else if s >= 2 {
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
                    s += 1

                }
            }
            
            return path.cgPath
        }
    }
}
