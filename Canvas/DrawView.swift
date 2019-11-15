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
    
    
    var drawColour = UIColor.white
    var currentIdentifier: String!
    var pointsToWrite: [Point] = []
    var shapeRecognition = false
    @IBOutlet var tracker: UIImageView!
    var xmppController : XMPPController?
    
    @IBOutlet var shapeRecognitionButton: UIBarButtonItem!
    
    var undoStack: [(String, Stroke, Stroke.ActionType)] = []
    var redoStack: [(String, Stroke, Stroke.ActionType)] = []
    
    var mode = Mode.DRAWING
    
    public var mcSession: MCSession?

    
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.backgroundColor = UIColor.black
    }
    
    func getIdentifier() -> String {
        return UUID().uuidString
    }
    
    func lookUpStroke(_ point: Point) -> (String, Int) {
        for (str, stroke) in lines {
            if let t = stroke.indexOf(givenPoint: point) {
                return (str, t);
            }
        }
        return ("", -1)
    }
    
    func partialRemove(_ point: Point) {
        for (str, stroke) in lines {
            let p = stroke.indexOf(givenPoint: point)
            if let t = p {
                handleChange(change: Change.partialRemoveStroke(str, t))
            }
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let point = Point(fromCGPoint: Array(touches)[0].location(in: self))
        
        switch mode {
        case .DRAWING:
            let stroke = Stroke(points: [point], colour: drawColour)
            currentIdentifier = getIdentifier()
            pointsToWrite = [point]
            handleChange(change: Change.addStroke(stroke, currentIdentifier))
            undoStack.append((currentIdentifier, stroke, Stroke.ActionType.add))
            redoStack = []
        case .COMPLETE_REMOVE:
            let (strokeId, t) = lookUpStroke(point)
            if (strokeId != "") {
                let stroke = lines[strokeId]!
                handleChange(change: Change.removeStroke(strokeId, t))
                undoStack.append((strokeId, stroke, Stroke.ActionType.remove))
            }
        case .PARTIAL_REMOVE:
            partialRemove(point)
            tracker.isHidden = false
            tracker.layer.borderWidth = 1
            tracker.layer.masksToBounds = false
            tracker.layer.borderColor = UIColor.black.cgColor
            tracker.layer.cornerRadius = tracker.frame.height/2
            tracker.clipsToBounds = true
            tracker.center = point.cgPoint
        case .SHAPE_RECOGNITION:
            let stroke = Stroke(points: [point], colour: drawColour)
            currentIdentifier = getIdentifier()
            pointsToWrite = [point]
            handleChange(change: Change.addStroke(stroke, currentIdentifier))
            undoStack.append((currentIdentifier, stroke, Stroke.ActionType.add))
            redoStack = []
        }
    }
    
    func handleChange(change: Change) {
        AutomergeJavaScript.shared.addChange(change) { (returnValue) in
            self.lines = returnValue.0
            self.sendPath(returnValue.1)
            self.setNeedsDisplay()
        }
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
                    redrawRectangle(currentIdentifier, corners)
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
                
        for (_, stroke) in lines {
            context.setStrokeColor(stroke.colour.cgColor)
            context.addPath(stroke.cgPath)
            context.strokePath()
        }
    }
    
    func redrawStraightLine(_ id: String) {
        let line = lines[id]!
        let count = line.points.count
        let start = line.points[0]
        let end = line.points[count - 1]
        handleChange(change: Change.removeStroke(id, 0))
        let stroke = Stroke(points: [start, end], colour: line.colour, isShape: true)
        print("stroke to be redrawn:", stroke.points)
        currentIdentifier = getIdentifier()
        handleChange(change: Change.addStroke(stroke, currentIdentifier))
        undoStack.append((currentIdentifier, line, Stroke.ActionType.redraw))
    }
    
    func redrawRectangle(_ id: String, _ points: [Point]) {
        let line = lines[id]!
        
        print("corners: ", points)
        handleChange(change: Change.removeStroke(id, 0))
        
        let x1 = points[0].x
        let y1 = points[0].y
        let x2 = points[2].x
        let y2 = points[2].y
        
        // User drew a rectangle at an angle (not relative to x, y axis)
        var corners = points
        
        if (points[0].x <= points[1].x + 20 && points[0].x >= points[1].x - 20) {
            // User drew a vertical line first
            print("User drew a vertical line first")
            corners = [points[0], Point(x: x1, y: y2), Point(x: x2, y: y2), Point(x: x2, y: y1)]
        } else if (points[0].y <= points[1].y + 20 && points[0].y >= points[1].y - 20) {
            // User drew a horizontal line first
            print("User drew a horizontal line first")
            corners = [points[0], Point(x: x2, y: y1), Point(x: x2, y: y2), Point(x: x1, y: y2)]
        }

        let stroke = Stroke(points: corners, colour: line.colour, isShape: true)
        print("rectangle to be redrawn:", stroke.points)
        currentIdentifier = getIdentifier()
        handleChange(change: Change.addStroke(stroke, currentIdentifier))
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
        shapeRecognition = !shapeRecognition
        if (shapeRecognition) {
            mode = .SHAPE_RECOGNITION
            shapeRecognitionButton.tintColor = UIColor.red
        } else {
            mode = .DRAWING
            shapeRecognitionButton.tintColor = UIColor.white
        }
    }

    func colourChosen(_ chosenColour: UIColor) {
        drawColour = chosenColour
        mode = mode == .SHAPE_RECOGNITION ? .SHAPE_RECOGNITION : .DRAWING
    }
    
    @IBAction func eraserChosen(_ sender: UIBarButtonItem) {
        let chosen = sender.tag
        mode = chosen == 20 ? .COMPLETE_REMOVE : .DRAWING
        shapeRecognition = false
        shapeRecognitionButton.tintColor = UIColor.white
    }
  
    @IBAction func partialChosen(_ sender: UIBarButtonItem) {
        let chosen = sender.tag
        mode = chosen == 21 ? .PARTIAL_REMOVE : .DRAWING
        shapeRecognition = false
        shapeRecognitionButton.tintColor = UIColor.white
    }
    
    @IBAction func clearCanvas(_ sender: Any) {
        // TODO: be able to undo a clear
        lines = [:]
        undoStack = []
        redoStack = []
        handleChange(change: Change.clearCanvas)
        self.setNeedsDisplay()
        
    }

    @IBAction func undoLastStroke(_ sender: Any) {
        if let (id, stroke, actionType) = undoStack.popLast() {
            if (actionType == Stroke.ActionType.add) {
                //handleChange(change: Change.removeStroke(id))
                redoStack.append((id, lines[id]!, actionType))
            } else if (actionType == Stroke.ActionType.remove) {
                handleChange(change: Change.addStroke(stroke, id))
                redoStack.append((id, stroke, actionType))
            } else if (actionType == Stroke.ActionType.redraw) {
                let s = lines[id]
//                handleChange(change: Change.removeStroke(id))
                handleChange(change: Change.addStroke(stroke, id))
                redoStack.append((id, s!, actionType))
            }
            
        }
    }
    
    @IBAction func redoLastStroke(_ sender: Any) {
        if let (id, stroke, actionType) = redoStack.popLast() {
            if (actionType == Stroke.ActionType.add) {
                handleChange(change: Change.addStroke(stroke, id))
                undoStack.append((id, stroke, actionType))
            }
            else if (actionType == Stroke.ActionType.remove) {
                //handleChange(change: Change.removeStroke(id))
                undoStack.append((id, stroke, actionType))
            } else if (actionType == Stroke.ActionType.redraw) {
                 redrawStraightLine(id)
            }
        }
    }

    func incomingChange(_ change: String) {
        AutomergeJavaScript.shared.applyExternalChanges(change) { (returnValue) in
            self.lines = returnValue
            self.setNeedsDisplay()
        }
    }
    
    func sendPath(_ change: String) {
        if let m = self.mcSession {
            if m.connectedPeers.count > 0 {
                do {
                    try m.send(change.data(using: .utf8)!, toPeers: m.connectedPeers, with: .reliable)
                } catch _ as NSError {
                }
            }
        }
        if xmppController!.isConnected(){
            xmppController!.room!.sendMessage(withBody: change)
        }
        
    }
}
