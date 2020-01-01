//
//  DrawView.swift
//  Canvas
//
//  Created by Hashan Punchihewa on 13/10/2019.
//  Copyright © 2019 Hashan Punchihewa. All rights reserved.
//

import UIKit
import MultipeerConnectivity

class DrawView: UIView {
    
    var lines: [String: Stroke] = [:]
    var cache: [String: CGPath] = [:]
    let engine: CRDTEngine = NativeCRDTEngine() //AutomergeJavaScript.shared
    
    var drawColour = UIColor.blue
    var thickness: Float = 1.0
    var currentIdentifier: String!
    var pointsToWrite: [Point] = []
    var xmppController: XMPPController?
    var mainViewController: ViewController?
    var bluetoothService: BluetoothService?
    
    @IBOutlet var tracker: UIImageView!
    @IBOutlet var shapeRecognitionButton: UIBarButtonItem!
    @IBOutlet var eraserButton: UIBarButtonItem!
    @IBOutlet var partialButton: UIBarButtonItem!

    var undoStack: [Change] = []
    var redoStack: [Change] = []
    
    var mode = Mode.DRAWING
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.backgroundColor = UIColor.white
    }
    
    func getIdentifier() -> String {
        return UUID().uuidString
    }
    
    func lookUpStroke(_ point: Point) -> (String, Double, Double)? {
        for (str, stroke) in lines {
            if let (t1, t2) = stroke.indexOf(givenPoint: point) {
                return (str, t1, t2);
            }
        }
        return nil
    }
    
    func partialRemove(_ point: Point) {
        for (str, stroke) in lines {
            for segment in stroke.segments {
                let start = Int(floor(segment.start))
                let end = Int(ceil(segment.end))
                
                if start >= end {
                    continue
                }
                
                let shapes = stroke.getPoints(start, end)
                
                if shapes.count == 0 {
                    continue
                }
                
                for i in 0...(shapes.count - 1) {
                    let shape = shapes[i]
                    let z = i + start
                    let result = Geometry.findIntersectionPoints(shape: shape, circle: point, radius: 15, depth: 0)
                    print(result)
                    switch result {
                    case let .LEFT_OPEN(t):
                        handleChange(change: Change.betterPartial(str, Double(z) + Double(t), Double(z + 1)))
                        print(t)
                        return
                    case let .RIGHT_OPEN(t):
                        handleChange(change: Change.betterPartial(str, Double(z), Double(z) + Double(t)))
                        print(t)
                        return
                    case let .MIDDLE_OPEN(t1, t2):
                        //print(t1, t2)
                        handleChange(change: Change.betterPartial(str, Double(z) + Double(t1), Double(z) + Double(t2)))
                        return
                    case .CLOSED:
                        handleChange(change: Change.betterPartial(str, Double(z), Double(z + 1)))
                        return
                    default:
                        break
                    }
                }
            }
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let point = Point(fromCGPoint: Array(touches)[0].location(in: self))
        
        switch mode {
        case .SHAPE_RECOGNITION, .DRAWING:
            let stroke = Stroke(points: [point], colour: drawColour, thickness: thickness)
            currentIdentifier = getIdentifier()
            pointsToWrite = [point]
            let change = Change.addStroke(stroke, currentIdentifier)
            undoStack.append(getInverseChange(change: change)!)
            handleChange(change: change)
            redoStack = []
        case .COMPLETE_REMOVE:
            if let (strokeId, t, t2) = lookUpStroke(point) {
                handleChange(change: Change.betterPartial(strokeId, t, t2))
            }
            redoStack = []
        case .PARTIAL_REMOVE:
            partialRemove(point)
            tracker.isHidden = false
            tracker.layer.borderWidth = 1
            tracker.layer.masksToBounds = false
            tracker.layer.borderColor = UIColor.black.cgColor
            tracker.layer.cornerRadius = tracker.frame.height/2
            tracker.clipsToBounds = true
            tracker.center = point.cgPoint
            redoStack = []
        }
    }
    
    func handleChange(change: Change) {
        let returnValue = engine.addChange(change)
        self.lines = returnValue.0
        //self.sendPath(returnValue.1)
        switch change {
        case let .addPoint(_, i):
            self.setStale(i)
        case let .addStroke(_, i):
            self.setStale(i)
        case let .removeStroke(i):
            cache.removeValue(forKey: i)
        case .clearCanvas:
            cache = [:]
        case let .betterPartial(i, _, _):
            self.setStale(i)
        }
        self.setNeedsDisplay()
    }
    
    func setStale(_ id: String) {
        cache[id] = lines[id]?.cgPath
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        let point = Point(fromCGPoint: Array(touches)[0].location(in: self))
        switch mode {
        case .DRAWING:
            if pointsToWrite.count > 0 && pointsToWrite.last! != point {
                pointsToWrite.append(point)
            }
            if pointsToWrite.count >= 5 {
                pointsToWrite.remove(at: 0)
                handleChange(change: Change.addPoint(pointsToWrite, currentIdentifier))
                pointsToWrite = [pointsToWrite.last!]
            }
    
        case .PARTIAL_REMOVE:
            partialRemove(point)
            tracker.center = point.cgPoint
        case .COMPLETE_REMOVE:
            break
        case .SHAPE_RECOGNITION:
            if pointsToWrite.count > 0 && pointsToWrite.last! != point {
                pointsToWrite.append(point)
            }
            if pointsToWrite.count >= 5 {
                pointsToWrite.remove(at: 0)
                handleChange(change: Change.addPoint(pointsToWrite, currentIdentifier))
                pointsToWrite = [pointsToWrite.last!]
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if (mode == Mode.SHAPE_RECOGNITION) {
            let currentLine = lines[currentIdentifier]!
            let isStraight = isStraightLine(currentLine.points)
            if (isStraight) {
                // If your rectangle gets corrected to a straight line, it's because you drew a rectangle that was too small
                print("found straight line")
                redrawStraightLine(currentIdentifier)
            } else {
                let (rectangle, corners) = isRectangle(currentLine.points)
                if (rectangle) {
                    print("found rectangle")
                    redrawRectangle(currentIdentifier, corners, currentLine.points)
                }
            }
        }
        
        if (mode == .PARTIAL_REMOVE) {
            tracker.isHidden = true
        }
       
        currentIdentifier = nil
        pointsToWrite = []
    }
    
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else {
            return
        }
                
        for (id, stroke) in lines {
            context.setStrokeColor(stroke.colour.cgColor)
            context.setLineWidth(CGFloat(stroke.thickness))
            context.setLineCap(CGLineCap.round)
            context.addPath(cache[id]!)
            context.strokePath()
        }
    }
    
    func redrawStraightLine(_ id: String) {
        let line = lines[id]!
        let count = line.points.count
        let start = line.points[0]
        let end = line.points[count - 1]
        handleChange(change: Change.removeStroke(id))
        let stroke = Stroke(points: [start, end], colour: line.colour, isShape: true, thickness: line.thickness)
        print("stroke to be redrawn:", stroke.points)
        currentIdentifier = getIdentifier()
        handleChange(change: Change.addStroke(stroke, currentIdentifier))
        //undoStack.append((currentIdentifier, line, Stroke.ActionType.redraw))
    }
    
    func redrawRectangle(_ id: String, _ points: [Point], _ full_points: [Point]) {
        let line = lines[id]!
        
        print("corners: ", points)
        
        let x1 = points[0].x
        let y1 = points[0].y
        let x2 = points[2].x
        let y2 = points[2].y
        
        // User drew a rectangle at an angle (not relative to x, y axis) so do not correct to a shape, leave as is
        var corners : [Point] = []
        let drewVerticalLine = points[0].x <= points[1].x + 20 && points[0].x >= points[1].x - 20
        let drewHorizontalLine = points[0].y <= points[1].y + 20 && points[0].y >= points[1].y - 20
        
        if (drewVerticalLine || drewHorizontalLine) {
            if (drewVerticalLine) {
                // User drew a vertical line first
                print("User drew a vertical line first")
                corners = [points[0], Point(x: x1, y: y2), Point(x: x2, y: y2), Point(x: x2, y: y1), points[0]]
            } else if (drewHorizontalLine) {
                // User drew a horizontal line first
                print("User drew a horizontal line first")
                corners = [points[0], Point(x: x2, y: y1), Point(x: x2, y: y2), Point(x: x1, y: y2), points[0]]
            }
            
            handleChange(change: Change.removeStroke(id))
              
            let stroke = Stroke(points: corners, colour: line.colour, isShape: true, thickness: line.thickness)
            currentIdentifier = getIdentifier()
            handleChange(change: Change.addStroke(stroke, currentIdentifier))
        } else {
           // User drew a rectangle at an angle, so do not correct to a shape, leave as is
        }
        
    }
    
    func isStraightLine(_ points: [Point?]) -> Bool {
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
    
    func atan3(_ a: Point, _ b: Point) -> Float {
        return atan2(a.y - b.y, a.x - b.x)
    }
    
    func attemptToBunchLines(_ points: [Point]) -> [Int] {
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
    
    func isRectangle(_ points: [Point?]) -> (Bool, [Point]) {
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
    
    func isInLine(_ coords: CGPoint, _ startPt: CGPoint, _ endPt: CGPoint) -> Bool {
        if (endPt.x <= startPt.x + 20 && endPt.x >= startPt.x - 20) {
            let verticalLineEqn = startPt.x
            return coords.x <= verticalLineEqn + 20 && coords.x >= verticalLineEqn - 20
        } else {
            let grad = (startPt.y - endPt.y) / (startPt.x - endPt.x)
            let yOnLineForGivenX = (grad * (coords.x - startPt.x)) + startPt.y
            return coords.y <= yOnLineForGivenX + 20 && coords.y >= yOnLineForGivenX - 20
        }
    }
    
    @IBAction func toggleShapeRecognition(_ sender: UIBarButtonItem) {
        if (mode == .SHAPE_RECOGNITION) {
            mode = .DRAWING
        } else {
            mode = .SHAPE_RECOGNITION
        }
        setButtonColour()
    }

    func colourChosen(_ chosenColour: UIColor, _ chosenThickness: Float) {
        drawColour = chosenColour
        thickness = chosenThickness
        mode = mode == .SHAPE_RECOGNITION ? .SHAPE_RECOGNITION : .DRAWING
        setButtonColour()
    }
    
    @IBAction func eraserChosen(_ sender: UIBarButtonItem) {
        mode = .COMPLETE_REMOVE
        setButtonColour()
    }

    @IBAction func partialChosen(_ sender: UIBarButtonItem) {
        mode = .PARTIAL_REMOVE
        setButtonColour()
    }
    
    @IBAction func clearCanvas(_ sender: Any) {
        undoStack = []
        redoStack = []
        handleChange(change: Change.clearCanvas)
        self.setNeedsDisplay()
    }
    
    func getInverseChange(change: Change) -> Change? {
        switch change {
        case .addPoint(_, _):
            return nil
        case let .addStroke(_, str):
            return Change.removeStroke(str)
        case let .removeStroke(str):
            return Change.addStroke(lines[str]!, getIdentifier())
        case .clearCanvas:
            return nil
        case .betterPartial(_, _, _):
            return nil
        }
    }

    @IBAction func undoLastStroke(_ sender: Any) {
        if let change = undoStack.popLast() {
            let inverse = getInverseChange(change: change)!
            redoStack.append(inverse)
            handleChange(change: change)
        }
    }
    
    @IBAction func redoLastStroke(_ sender: Any) {
        if let change = redoStack.popLast() {
            let inverse = getInverseChange(change: change)!
            undoStack.append(inverse)
            handleChange(change: change)
        }
    }

    func incomingChange(_ change: String) {
        self.lines = engine.applyExternalChanges(change)
        self.setNeedsDisplay()
    }
    
    func sendPath(_ change: String) {
        if (mainViewController!.isMaster) {
            if xmppController!.isConnected(){
                xmppController!.room!.sendMessage(withBody: change)
            }
        }
        bluetoothService!.send(data: change)
    }
    
    func setButtonColour() {
        switch mode {
        case .DRAWING:
            shapeRecognitionButton.tintColor = UIColor.white
            partialButton.tintColor = UIColor.white
            eraserButton.tintColor = UIColor.white
        case .COMPLETE_REMOVE:
            shapeRecognitionButton.tintColor = UIColor.white
            partialButton.tintColor = UIColor.white
            eraserButton.tintColor = UIColor.red
        case .PARTIAL_REMOVE:
            shapeRecognitionButton.tintColor = UIColor.white
            partialButton.tintColor = UIColor.red
            eraserButton.tintColor = UIColor.white
        case .SHAPE_RECOGNITION:
            shapeRecognitionButton.tintColor = UIColor.red
            partialButton.tintColor = UIColor.white
            eraserButton.tintColor = UIColor.white
        }
    }
}
