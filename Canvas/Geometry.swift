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
    
    static func *(a: Point, b: Point) -> Float {
        return a.x * b.x + a.y * b.y
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

class Geometry {
    static func findIntersectionPoints(shape: Shape, circle: Point, radius: Float, depth: Int) -> IntersectionResult {
        let (results, cp0, cp3) = Geometry.helperFunction(shape, circle, radius, depth)
        if results.count == 0 {
            return .OPEN
        } else if results.count == 1 {
            let distA = Point.dist(cp0, circle)
            let distB = Point.dist(cp3, circle)
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
    
    private static func split(_ t: Float, _ curve: (Point, Point, Point, Point)) -> ((Point, Point, Point, Point), (Point, Point, Point, Point)) {
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
            let points = Geometry.findIntersectionPointsLine(line: (cp0, cp3), circle: circle, radius: radius)
            return (points, cp0, cp3)
        case let .Curve(cp0, cp1, cp2, cp3):
            let points = Geometry.findIntersectionPointsCurve(curve: (cp0, cp1, cp2, cp3), circle: circle, radius: radius, depth: depth)
            return (points, cp0, cp3)
        }
    }
    
    private static func findIntersectionPointsCurve(curve: (Point, Point, Point, Point), circle: Point, radius: Float, depth: Int) -> [Float] {
        let (cp0, _, _, cp3) = curve
        if depth == 0 {
            return Geometry.findIntersectionPointsLine(line: (cp0, cp3), circle: circle, radius: radius)
        } else {
            let (curve1, curve2) = Geometry.split(0.5, curve)
            let results1 = Geometry.findIntersectionPointsCurve(curve: curve1, circle: circle, radius: radius, depth: depth - 1)
            let results2 = Geometry.findIntersectionPointsCurve(curve: curve2, circle: circle, radius: radius, depth: depth - 1)
            return results1.map { $0 / 2 } + results2.map { 0.5 + $0 / 2 }
        }
    }

    private static func findIntersectionPointsLine(line: (Point, Point), circle: Point, radius: Float) -> [Float] {
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
}
