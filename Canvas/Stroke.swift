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
    
    static func -(a: Point, b: Point) -> Point {
        return Point(x: a.x - b.x, y: a.y - b.y)
    }
    
    var cgPoint: CGPoint {
        get {
            return CGPoint(x: CGFloat(x), y: CGFloat(y))
        }
    }
    
    public var description: String { return "x: \(x) y: \(y)" }
}

enum Change: Encodable, Decodable {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: CodingKeys.type)
        switch type {
        case "ADD_POINT":
            let point = try container.decode([Point].self, forKey: CodingKeys.point)
            let identifier = try container.decode(String.self, forKey: CodingKeys.identifier)
            self = .addPoint(point, identifier)
        case "ADD_STROKE":
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
        case point
        case identifier
        case index
        case lower
        case upper
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
    case addPoint([Point], String)
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

enum IntersectionResult {
    case OPEN
    case CLOSED
    case LEFT_OPEN(Float)
    case RIGHT_OPEN(Float)
    case MIDDLE_OPEN(Float, Float)
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
        
        let nested = try container.nestedContainer(keyedBy: ColourCodingKeys.self, forKey: CodingKeys.colour)
        let red = try nested.decode(CGFloat.self, forKey: ColourCodingKeys.red)
        let green = try nested.decode(CGFloat.self, forKey: ColourCodingKeys.green)
        let blue = try nested.decode(CGFloat.self, forKey: ColourCodingKeys.blue)
        let alpha = try nested.decode(CGFloat.self, forKey: ColourCodingKeys.alpha)
        colour = UIColor(red: red, green: green, blue: blue, alpha: alpha)
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
    
    let ERROR_BOUND = Float(20)
    
    func getClosestPoint(_ a: Point, _ b: Point, _ p: Point) -> Double? {
        let a_to_p = (
            p.x - a.x,
            p.y - a.y
        )
        let a_to_b = (
            b.x - a.x,
            b.y - a.y
        )
        let atb_2 = pow(a_to_b.0, 2) + pow(a_to_b.1, 2)
        let atb_dot_atp = a_to_p.0 * a_to_b.0 + a_to_p.1 * a_to_b.1
        let t = atb_dot_atp / atb_2
        
        let nPoint = (a.x + a_to_b.0 * t, a.y + a_to_b.1 * t)
        
        if sqrt(pow(p.x - nPoint.0, 2) + pow(p.y - nPoint.1, 2)) > ERROR_BOUND {
            return nil
        }
        
        return Double(t)
    }
    
    func isInLine(_ lPoint: Point, _ uPoint: Point, _ givenPoint: Point) -> Double? {
        if lPoint.x == uPoint.x {
            if abs(givenPoint.x - lPoint.x) > ERROR_BOUND {
                return nil
            }
            let ratio = (givenPoint.y - lPoint.y) / (uPoint.y - lPoint.y)
            //print("ratio 2: ", ratio)
            if ratio < 0 || ratio > 1 {
                return nil
            }
            return Double(ratio)
        } else {
            let ratio = (givenPoint.x - lPoint.x) / (uPoint.x - lPoint.x)
            print("ratio 1: ", ratio)
            if ratio < 0 || ratio > 1 {
                return nil
            }
            let interpolatedY = (uPoint.y - lPoint.y) * ratio + lPoint.y
            print("ys: ", interpolatedY, givenPoint.y)
            if abs(interpolatedY - givenPoint.y) > ERROR_BOUND {
                return nil
            }
            return Double(ratio)
        }
    }
    
    func indexOf(givenPoint: Point) -> (Double, Double)? {
        if isShape {
            for segment in segments {
                var i = segment.start // 1, 1.5
                while i < segment.end {
                    let l = Int(floor(i)) // 1, 1
                    let u = Int(floor(i + 1)) // 2, 2
                    
                    let lPoint = points[l]
                    let uPoint = points[u]
                    
                    let t = getClosestPoint(lPoint, uPoint, givenPoint)
                    if let tNotNil = t {
                        let k = Double(l) + tNotNil
                        if k > i && k < segment.end {
                            return (segment.start, segment.end)
                        }
                    }
                    
                    
                    i += 1
                    i = floor(i)
                }
            }
        } else {
            for segment in segments {
                for i in Int(ceil(segment.start))...Int(floor(segment.end)) {
                    let point = points[i]
                    if ((givenPoint.x <= point.x + 10 && givenPoint.x >= point.x - 10) && (givenPoint.y <= point.y + 10 && givenPoint.y >= point.y - 10)) {
                        //return Double(i)
                        return (segment.start, segment.end)
                    }
                }
            }
        }
        return nil;
    }
    
    func getPoint(_ i: Double) -> Point {
        let lower = Int(floor(i))
        let upper = Int(ceil(i))
        let lPoint = points[lower]
        let uPoint = points[upper]
        let uWeight = Float(i - floor(i))
        let lWeight = 1 - uWeight
        let p = Point(x: lWeight * lPoint.x + uWeight * uPoint.x, y: lWeight * lPoint.y + uWeight * uPoint.y)
        return p
    }
    
    func getPoints(_ start: Int, _ end: Int) -> [(Point, Point, Point)] {
        var returnValue: [(Point, Point, Point)] = []
        
        var pPrevPoint: Point!
        var prevPoint: Point!
        var s = 0
        
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

                returnValue.append((cp1, cp2, end))
            }
            
            pPrevPoint = prevPoint
            prevPoint = point
            s += 1
        }
        
        return returnValue
    }
    
    static func dotProduct(_ a: Point, _ b: Point) -> Float {
        return a.x * b.x + a.y * b.y
    }
    
    static func abs2(_ a: Point) -> Float {
        return sqrt(dotProduct(a, a))
    }
    
    static func dist(_ a: Point, _ b: Point) -> Float {
        return abs2(a - b)
    }
            
    static func findIntersectionsLine(line: (Point, Point), circle: Point, radius: Float) -> [Float] {
        //print("centre ", circle)
        let m = (line.1.y - line.0.y) / (line.1.x - line.0.x)
        let n = line.1.y - m * line.1.x
        //print("m ", m)
        //print("n ", n)
        let a = 1 + m * m
        let b = -circle.x * 2 + (m * (n - circle.y)) * 2
        let c = circle.x * circle.x + (n - circle.y) * (n - circle.y) - (radius * radius)
        //print("a b c ", a, b, c)
        let d = b * b - 4 * a * c
        //print("d ", d)
        var results: [Float] = []
        if d == 0 {
            results.append((-b + sqrt(d)) / (2 * a))
        } else if d >= 0 {
            results.append((-b + sqrt(d)) / (2 * a))
            results.append((-b - sqrt(d)) / (2 * a))
        }
        results = results.map { ($0 - line.0.x) / (line.1.x - line.0.x) }
        results = results.filter { $0 >= 0 && $0 <= 1 }
        return results
    }
    
    static func findIntersectionPoints(curve: (Point, Point, Point, Point), circle: Point, radius: Float, depth: Int) -> [Float] {
        let (cp0, _, _, cp3) = curve
        if depth == 0 {
            return findIntersectionsLine(line: (cp0, cp3), circle: circle, radius: radius)
        } else {
            let (curve1, curve2) = split(0.5, curve)
            let results1 = findIntersectionPoints(curve: curve1, circle: circle, radius: radius, depth: depth - 1)
            let results2 = findIntersectionPoints(curve: curve2, circle: circle, radius: radius, depth: depth - 1)
            return results1.map { $0 / 2 } + results2.map { 0.5 + $0 / 2 }
        }
    }
    
    static func findIntersectionsPoint(line: (Point, Point), circle: Point, radius: Float) -> IntersectionResult {
        let results = Stroke.findIntersectionsLine(line: line, circle: circle, radius: radius)
        if results.count == 0 {
            return .OPEN
        } else if results.count == 1 {
            let (cp0, cp3) = line
            let distA = dist(cp0, circle)
            let distB = dist(cp3, circle)
            if distA < radius && distB > radius {
                return .RIGHT_OPEN(results[0])
            } else if distB < radius && distA > radius {
                return .LEFT_OPEN(results[0])
            } else {
                // WTF
                // Like seriously, WTF
                return .OPEN
            }
        } else {
            let smallest = results.min()!
            let biggest = results.max()!
            return .MIDDLE_OPEN(smallest, biggest)
        }
    }
    
    static func findIntersectionsAdvanced(curve: (Point, Point, Point, Point), circle: Point, radius: Float) -> IntersectionResult {
        let results = findIntersectionPoints(curve: curve, circle: circle, radius: radius, depth: 0)
        if results.count == 0 {
            return .OPEN
        } else if results.count == 1 {
            let (cp0, _, _, cp3) = curve
            let distA = dist(cp0, circle)
            let distB = dist(cp3, circle)
            if distA < radius && distB > radius {
                return .RIGHT_OPEN(results[0])
            } else if distB < radius && distA > radius {
                return .LEFT_OPEN(results[0])
            } else {
                // WTF
                // Like seriously, WTF
                return .OPEN
            }
        } else {
            let smallest = results.min()!
            let biggest = results.max()!
            return .MIDDLE_OPEN(smallest, biggest)
        }
    }
    
    private static func lerp(_ t: Float, _ a: Point, _ b: Point) -> Point {
        return Point(x: (1 - t) * a.x + t * b.x, y: (1 - t) * a.y + t * b.y)
    }
    
    static func split(_ t: Float, _ curve: (Point, Point, Point, Point)) -> ((Point, Point, Point, Point), (Point, Point, Point, Point)) {
        let (cp0, cp1, cp2, cp3) = curve
        let e = Stroke.lerp(t, cp0, cp1)
        let f = Stroke.lerp(t, cp1, cp2)
        let g = Stroke.lerp(t, cp2, cp3)
        let h = Stroke.lerp(t, e, f)
        let j = Stroke.lerp(t, f, g)
        let k = Stroke.lerp(t, h, j)
        return ((cp0, e, h, k), (k, j, g, cp3))
    }
    
    var cgPath: CGPath {
        get {
            if (isShape) {
                let path = UIBezierPath.init()
                path.lineCapStyle = CGLineCap.round
                path.lineWidth = 3

                for segment in segments {
                    path.move(to: getPoint(segment.start).cgPoint)
                    
                    var i = segment.start
                    while i < segment.end {
                        i += 1
                        i = floor(i)
                        i = min(i, segment.end)
                        
                        path.addLine(to: getPoint(i).cgPoint)
                    }
                    
                    print("draw: ", segment.start, segment.end)
                }
                
                return path.cgPath

            } else {
                let path = UIBezierPath.init()
                path.lineCapStyle = CGLineCap.round
                path.lineWidth = 3
                
                for segment in segments {
                    if segment.start > segment.end {
                        continue
                    }
                    
                    let start = Int(floor(segment.start))
                    let end = Int(ceil(segment.end))
                    let curve = getPoints(start, end)
                    
                    if curve.count == 0 {
                        continue
                    }
                    
                    var last = points[start]
                    //path.move(to: last)
                    
                    for i in 0...(curve.count - 1) {
                        let (cp1, cp2, end) = curve[i]
                        var (last_, cp1_, cp2_, end_) = (last, cp1, cp2, end)

                        if i == 0 {
                            (last_, cp1_, cp2_, end_) = Stroke.split(Float(segment.start - floor(segment.start)), (last, cp1, cp2, end)).1
                            if segment.start - floor(segment.start) != 0 {
                                print("srender ", segment.start, segment.start - floor(segment.start))
                            }
                        } else if i == curve.count - 1 {
                            (last_, cp1_, cp2_, end_) = Stroke.split(Float(segment.end - floor(segment.end)), (last, cp1, cp2, end)).0
                            if ceil(segment.end) - segment.end != 0 {
                                print("erender ", segment.end, segment.end - floor(segment.end))
                            }
                        }
               
                        path.move(to: last_.cgPoint)
                        //path.addCurve(to: end.cgPoint, controlPoint1: cp1.cgPoint, controlPoint2: cp2.cgPoint)
                        path.addCurve(to: end_.cgPoint, controlPoint1: cp1_.cgPoint, controlPoint2: cp2_.cgPoint)
                        last = end
                    }
                    
                    
                }
                
                return path.cgPath
            }
        }
    }
}
