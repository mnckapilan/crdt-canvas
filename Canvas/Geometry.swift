//
//  Geometry.swift
//  Canvas
//
//  Created by Hashan Punchihewa on 01/01/2020.
//  Copyright © 2020 jackmorrison. All rights reserved.
//

import Foundation
import CoreGraphics

class Point: Codable, Equatable, CustomStringConvertible {
    static func == (lhs: Point, rhs: Point) -> Bool {
        return lhs.x == rhs.x && lhs.y == rhs.y
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode([x, y])
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode([Float].self)
        self.x = value[0]
        self.y = value[1]
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
    
    static func +(a: Point, b: Point) -> Point {
        return Point(x: a.x + b.x, y: a.y + b.y)
    }
    
    static func -(a: Point, b: Point) -> Point {
        return Point(x: a.x - b.x, y: a.y - b.y)
    }
    
    static func *(a: Point, b: Point) -> Float {
        return a.x * b.x + a.y * b.y
    }
    
    static func *(a: Float, b: Point) -> Point {
        return Point(x: a * b.x, y: a * b.y)
    }
    
    var abs: Float {
        return sqrt(self * self)
    }
    
    static func dist(_ a: Point, _ b: Point) -> Float {
        return (a - b).abs
    }
    
    var cgPoint: CGPoint {
        get {
            return CGPoint(x: CGFloat(x), y: CGFloat(y))
        }
    }
    
    public var description: String { return "x: \(x) y: \(y)" }
}

enum Shape {
    case Line(Point, Point)
    case Curve(Point, Point, Point, Point)
}

enum IntersectionResult {
    case OPEN
    case CLOSED
    case LEFT_OPEN(Float)
    case RIGHT_OPEN(Float)
    case MIDDLE_OPEN(Float, Float)
}

typealias Curve = (Point, Point, Point, Point)

class Geometry {
    static func findIntersectionPoints(shape: Shape, circle: Point, radius: Float, depth: Int) -> IntersectionResult {
        let (results, cp0, cp3) = Geometry.helperFunction(shape, circle, radius, depth)
        let distA = Point.dist(cp0, circle)
        let distB = Point.dist(cp3, circle)
        if results.count == 0 {
            if distA < radius && distB < radius {
                return .CLOSED
            } else {
                return .OPEN
            }
        } else if results.count == 1 {
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
        
    static func trim(_ shape: Shape, _ lower: Float, _ upper: Float) -> Shape {
        switch shape {
        case let .Line(cp0, cp3):
            return .Line(Geometry.lerp(lower, cp0, cp3), Geometry.lerp(upper, cp0, cp3))
        case let .Curve(cp0, cp1, cp2, cp3):
            let (_, curve1) = Geometry.split(lower, (cp0, cp1, cp2, cp3))
            let ((cp0_, cp1_, cp2_, cp3_), _) = Geometry.split(lower + (upper * (1 - lower)), curve1)
            return .Curve(cp0_, cp1_, cp2_, cp3_)
        }
    }
    
    private static func lerp(_ t: Float, _ a: Point, _ b: Point) -> Point {
        return Point(x: (1 - t) * a.x + t * b.x, y: (1 - t) * a.y + t * b.y)
    }
    
    private static func split(_ t: Float, _ curve: Curve) -> (Curve, Curve) {
        let (cp0, cp1, cp2, cp3) = curve
        let e = Geometry.lerp(t, cp0, cp1)
        let f = Geometry.lerp(t, cp1, cp2)
        let g = Geometry.lerp(t, cp2, cp3)
        let h = Geometry.lerp(t, e, f)
        let j = Geometry.lerp(t, f, g)
        let k = Geometry.lerp(t, h, j)
        return ((cp0, e, h, k), (k, j, g, cp3))
    }
    
    private static func helperFunction(_ shape: Shape, _ circle: Point, _ radius: Float, _ depth: Int) -> ([Float], Point, Point) {
        switch shape {
        case let .Line(cp0, cp3):
            let points = Geometry.findIntersectionPointsLine((cp0, cp3), circle, radius)
            return (points, cp0, cp3)
        case let .Curve(cp0, cp1, cp2, cp3):
            let points = Geometry.findIntersectionPointsCurve((cp0, cp1, cp2, cp3), circle, radius, depth)
            return (points, cp0, cp3)
        }
    }
    
    private static func findIntersectionPointsCurve(_ curve: Curve, _ circle: Point, _ radius: Float, _ depth: Int) -> [Float] {
        let (cp0, _, _, cp3) = curve
        if depth == 0 {
            return findIntersectionPointsLine((cp0, cp3), circle, radius)
        } else {
            let (curve1, curve2) = Geometry.split(0.5, curve)
            let results1 = findIntersectionPointsCurve(curve1, circle, radius, depth - 1)
            let results2 = findIntersectionPointsCurve(curve2, circle, radius, depth - 1)
            return results1.map { $0 / 2 } + results2.map { 0.5 + $0 / 2 }
        }
    }

    private static func findIntersectionPointsLine(_ line: (Point, Point), _ circle: Point, _ radius: Float) -> [Float] {
        var results: [Float] = []
        if (abs(line.0.x - line.1.x) < 0.05) {
            let x = (line.0.x + line.1.x) / 2
            let q = (x - circle.x)
            let d = (radius * radius) - (q * q)
            if d == 0 {
                results.append(circle.y)
            } else if d >= 0 {
                results.append(circle.y + sqrt(d))
                results.append(circle.y - sqrt(d))
            }
            results = results.map { ($0 - line.0.y) / (line.1.y - line.0.y) }
        } else {
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
            if d == 0 {
                results.append((-b + sqrt(d)) / (2 * a))
            } else if d >= 0 {
                results.append((-b + sqrt(d)) / (2 * a))
                results.append((-b - sqrt(d)) / (2 * a))
            }
            results = results.map { ($0 - line.0.x) / (line.1.x - line.0.x) }
        }
        results = results.filter { $0 >= 0 && $0 <= 1 }
        return results
    }
    
    static func isStraightLine(_ points: [Point?]) -> Bool {
        let startPt = points[0]!.cgPoint
        let endPt = points[points.count - 1]!.cgPoint
        
        var almostStraightLine = true
        for point in points {
            let res = isInLine(point!.cgPoint, startPt, endPt)
            if (!res) {
                almostStraightLine = res
                break
            }
        }
        
        return almostStraightLine
    }
    
    static func atan3(_ a: Point, _ b: Point) -> Float {
        return atan2(a.y - b.y, a.x - b.x)
    }
    
    static func attemptToBunchLines(_ points: [Point]) -> [Int] {
        var retValue: [Int] = []
        
        let m = 10
        
        var initialAngle: Float? = nil
        var start = 0
        var i = 0
        retValue.append(0)
        while i < points.count - m {
            let angle = atan3(points[start], points[i + m])
            if let initialAngleNotNil = initialAngle {
                if abs(initialAngleNotNil - angle) > 0.4 {
                    retValue.append(i)
                    initialAngle = atan3(points[i + m - 1], points[i + m])
                    i += m
                    start = i
                    continue
                }
            } else {
                initialAngle = angle
            }
            i += 1
        }
        retValue.append(0)
        
        print("output from corner detection: ", retValue)
        return retValue
    }
    
    static func isRectangle(_ points: [Point?]) -> (Bool, [Point]) {
        let corners = attemptToBunchLines(points as! [Point])
        if (corners.count != 5) {
            print("Too many/few corners")
            return (false, [])
        }
        
        var rectanglePoints : [Point?] = []
        for i in 0...corners.count - 2 {
            let side = [points[i], points[i + 1]]
            if (!isStraightLine(side)) {
                print("side is not a straight line")
                return (false, [])
            }
            rectanglePoints.append(points[corners[i]])
        }
        return (true, rectanglePoints as! [Point])
    }
    
    static func isInLine(_ coords: CGPoint, _ startPt: CGPoint, _ endPt: CGPoint) -> Bool {
        if (endPt.x <= startPt.x + 20 && endPt.x >= startPt.x - 20) {
            let verticalLineEqn = startPt.x
            return coords.x <= verticalLineEqn + 20 && coords.x >= verticalLineEqn - 20
        } else {
            let grad = (startPt.y - endPt.y) / (startPt.x - endPt.x)
            let yOnLineForGivenX = (grad * (coords.x - startPt.x)) + startPt.y
            return coords.y <= yOnLineForGivenX + 20 && coords.y >= yOnLineForGivenX - 20
        }
    }
    
    static func getClosest(_ shape: Shape, _ p: Point) -> (Double, Point) {
        switch shape {
        case let .Line(cp0, cp3):
            return getClosestPoint(cp0, cp3, p)
        case let .Curve(cp0, _, _, cp3):
            return getClosestPoint(cp0, cp3, p)
        }
    }
    
    static func getClosestPoint(_ a: Point, _ b: Point, _ p: Point) -> (Double, Point) {
        let a_to_p = p - a
        let a_to_b = b - a
        let atb_dot_atp = a_to_b * a_to_p
        let atb_2 = a_to_b * a_to_b
        let t = atb_dot_atp / atb_2
        let nPoint = a + t * a_to_b
        
        return (Double(t), nPoint)
    }
}
