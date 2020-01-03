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

enum Change: Encodable, Decodable {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: CodingKeys.type)
        switch type {
        case "APPEND":
            let point = try container.decode([Point].self, forKey: CodingKeys.points)
            let identifier = try container.decode(String.self, forKey: CodingKeys.identifier)
            let index = try container.decode(Int.self, forKey: CodingKeys.index)
            self = .addPoint(point, identifier, index)
        case "ADD":
            let stroke = try container.decode(Stroke.self, forKey: CodingKeys.stroke)
            let identifier = try container.decode(String.self, forKey: CodingKeys.identifier)
            self = .addStroke(stroke, identifier)
        case "CLEAR_CANVAS":
            self = .clearCanvas
        case "REMOVE_STROKE":
            let identifier = try container.decode(String.self, forKey: CodingKeys.identifier)
            self = .removeStroke(identifier)
        case "BETTER_PARTIAL":
            let identifier = try container.decode(String.self, forKey: CodingKeys.identifier)
            let lower = try container.decode(Double.self, forKey: CodingKeys.lower)
            let upper = try container.decode(Double.self, forKey: CodingKeys.upper)
            self = .betterPartial(identifier, lower, upper)
        default:
            self = .clearCanvas
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case type
        case stroke
        case points
        case identifier
        case index
        case lower
        case upper
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case let .addPoint(point, i, index):
<<<<<<< HEAD
            try container.encode("APPEND", forKey: CodingKeys.type)
            try container.encode(point, forKey: CodingKeys.points)
=======
            try container.encode("ADD_POINT", forKey: CodingKeys.type)
            try container.encode(point, forKey: CodingKeys.point)
>>>>>>> 7e8f1bc9b8fa9f70b8a38404b974b1f5265a81d8
            try container.encode(i, forKey: CodingKeys.identifier)
            try container.encode(index, forKey: CodingKeys.index)
        case let .addStroke(stroke, i):
            try container.encode("ADD", forKey: CodingKeys.type)
            try container.encode(stroke, forKey: CodingKeys.stroke)
            try container.encode(i, forKey: CodingKeys.identifier)
        case .clearCanvas:
            try container.encode("CLEAR_CANVAS", forKey: CodingKeys.type)
        case let .removeStroke(str):
            try container.encode("REMOVE_STROKE", forKey: CodingKeys.type)
            try container.encode(str, forKey: CodingKeys.identifier)
        case let .betterPartial(str, i, j):
            try container.encode("BETTER_PARTIAL", forKey: CodingKeys.type)
            try container.encode(str, forKey: CodingKeys.identifier)
            try container.encode(i, forKey: CodingKeys.lower)
            try container.encode(j, forKey: CodingKeys.upper)
        }
    }
    
    case addStroke(Stroke, String)
    case removeStroke(String)
    case addPoint([Point], String, Int)
    case clearCanvas
    case betterPartial(String, Double, Double)
}

enum Mode {
    case DRAWING
    case COMPLETE_REMOVE
    case PARTIAL_REMOVE
    case SHAPE_RECOGNITION
}

class Segment: Codable {
    var start: Double
    var end: Double
    
    enum CodingKeys: String, CodingKey {
        case start
        case end
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        start = try container.decode(Double.self, forKey: CodingKeys.start)
        end = try container.decode(Double.self, forKey: CodingKeys.end)
    }
    
    init(_ start: Double, _ end: Double) {
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
    var isShape: Bool
    var thickness: Float

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
        case isShape
        case thickness
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
        isShape = try container.decode(Bool.self, forKey: CodingKeys.isShape)
        thickness = try container.decode(Float.self, forKey: CodingKeys.thickness)
        
        let components = try container.decode([CGFloat].self, forKey: CodingKeys.colour)
        colour = UIColor(red: components[0], green: components[1], blue: components[2], alpha: 0)
    }
    
    init(points: [Point], colour: UIColor, isShape: Bool = false, thickness: Float) {
        self.points = points
        self.colour = colour
        self.segments = [Segment(0.0, Double(self.points.count - 1))]
        self.isShape = isShape
        self.thickness = thickness
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(points, forKey: CodingKeys.points)
        try container.encode(segments, forKey: CodingKeys.segments)
        try container.encode(isShape, forKey: CodingKeys.isShape)
        try container.encode(thickness, forKey: CodingKeys.thickness)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        colour.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        try container.encode([red, green, blue], forKey: CodingKeys.colour)
    }
    
    func contains(givenPoint: Point) -> Bool {
        return indexOf(givenPoint: givenPoint) != nil
    }
    
    let ERROR_BOUND = Float(20)
    
    func indexOf(givenPoint: Point) -> (Double, Double)? {
        for segment in segments {
            let start = Int(floor(segment.start))
            let end = Int(ceil(segment.end))
            let curves = getPoints(start, end)
        
            if curves.count == 0 {
                continue
            }
            
            for i in 0...(curves.count - 1) {
                let curve = curves[i]
                
                let (t, n) = Geometry.getClosest(curve, givenPoint)
                
                let k = Double(start + i) + t

                if Point.dist(n, givenPoint) < ERROR_BOUND
                    && k > segment.start
                    && k < segment.end {
                    return (segment.start, segment.end)
                }
            }
        }
        return nil;
    }
        
    func getPoints(_ start: Int, _ end: Int) -> [Shape] {
        var returnValue: [Shape] = []
        if isShape {
            for i in start...(end - 1) {
                returnValue.append(.Line(points[i], points[i + 1]))
            }
        } else {
            var pPrevPoint: Point!
            var prevPoint: Point!
            var s = 0
            
            var last = points[start]
            
            for i in start...end {
                let point = points[i]
                
                if s >= 2 {
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

                    //returnValue.append((cp1, cp2, end))
                    returnValue.append(.Curve(last, cp1, cp2, end))
                    last = end
                }
                
                pPrevPoint = prevPoint
                prevPoint = point
                s += 1
            }
        }
        return returnValue
    }
        
    var cgPath: CGPath {
        get {
            let path = UIBezierPath.init()
            path.lineCapStyle = CGLineCap.round
            path.lineWidth = 3

            for segment in segments {
                if segment.start > segment.end {
                    continue
                }
                
                let start = Int(floor(segment.start))
                let startDist = segment.start - floor(segment.start)
                let end = Int(ceil(segment.end))
                let endDist = segment.end - floor(segment.end)
                let curves = getPoints(start, end)
                
                if curves.count == 0 {
                    continue
                }
                
                for i in 0...(curves.count - 1) {
                    var curve = curves[i]
                    
                    if i == 0 && i == curves.count - 1 && endDist != 0 {
                        curve = Geometry.trim(curve, Float(startDist), Float(endDist))
                    } else if i == 0 {
                        curve = Geometry.trim(curve, Float(startDist), 1)
                    } else if i == curves.count - 1 && endDist != 0 {
                        curve = Geometry.trim(curve, 1, Float(endDist))
                    }
                    
                    if case let .Line(cp0, cp3) = curve {
                        path.move(to: cp0.cgPoint)
                        path.addLine(to: cp3.cgPoint)
                    } else if case let .Curve(cp0, cp1, cp2, cp3) = curve {
                        path.move(to: cp0.cgPoint)
                        path.addCurve(to: cp3.cgPoint, controlPoint1: cp1.cgPoint, controlPoint2: cp2.cgPoint)
                    }
                }
            }
            return path.cgPath
        }
    }
}
