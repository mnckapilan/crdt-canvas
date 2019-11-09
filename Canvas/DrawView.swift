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
        case .COMPLETE_REMOVE:
            break
        }
        
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        let currentLine = lines[currentIdentifier]!
        
        if (shapeRecognition) {
            let isStraight = isStraightLine(currentLine.points)
            if (isStraight) {
                print("found straight line")
                redrawStraightLine(currentIdentifier)
            } else {
                let rectangle = isRectangle(currentLine.points)
                if (rectangle) {
                    print("found rectangle")
                }
            }
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
        
        let (_, t) = lookUpStroke(start)
        handleChange(change: Change.removeStroke(id, t))
        var new_points = [start, start, end, end]
        
        if (start.cgPoint.x - end.cgPoint.x != 0) {
            let grad = calc_gradient(line.points)
            let nextX1 = (start.cgPoint.x + end.cgPoint.x) / 3
            let nextX2 = (start.cgPoint.x + end.cgPoint.x) * 2 / 3
            let nextY1 = (grad * (nextX1 - start.cgPoint.x)) + start.cgPoint.y
            let nextY2 = (grad * (nextX2 - start.cgPoint.x)) + start.cgPoint.y
            let nextPt1 = Point(x: Float(nextX1), y: Float(nextY1))
            let nextPt2 = Point(x: Float(nextX2), y: Float(nextY2))
            
            new_points = [start, nextPt1, nextPt2, end]
        }

        let stroke = Stroke(points: new_points, colour: line.colour)
        handleChange(change: Change.addStroke(stroke, id))
        
        undoStack.append((id, line, Stroke.ActionType.redraw))
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
    
    func isRectangle(_ points: [Point?]) -> Bool {
        var i = 0
        var sides : [[Point?]] = []
        for _ in (1...4) {
            // maybe try arbitrarily splitting the list of points into 4 sets and then removing points from the end of the set until it forms a striahgt line?
            
            var curSegment : [Point?] = [points[i]]

            while(isStraightLine(curSegment)) {
                if (i >= points.count - 1) {
                    break
                }
                i = i + 1
                curSegment.append(points[i])
            }
            
            sides.append(curSegment)
        }
        
        print(sides)
        print("Num points vs num points we looped through", points.count, i)
        
        // Haven't got 4 sides
        if (i < points.count - 10) {
            return false
        }
        
        var gradients : [CGFloat] = []
        for side in sides {
            gradients.append(calc_gradient(side))
        }
        print(gradients)
        
        if (is_perpendicular(gradients[0], gradients[1]) && is_perpendicular(gradients[2], gradients[3])) {
            return true
        }
        
        return false
    }
    
    func is_perpendicular(_ grad1: CGFloat, _ grad2: CGFloat) -> Bool {
        let mult = abs(grad1 * grad2)
        print(mult)
        
        if (mult > 0.6 && mult < 1.4) {
            return true
        }
        return false
    }
    
    func calc_gradient(_ points: [Point?]) -> CGFloat {
        let startPt = points[0]!.cgPoint
        let endPt = points[points.count - 1]!.cgPoint
        
        let grad = (startPt.y - endPt.y) / (startPt.x - endPt.x)
        return grad
    }
    
    func isInLine(_ coords: CGPoint, _ startPt: CGPoint, _ endPt: CGPoint) -> Bool {
        if (endPt.x <= startPt.x + 25 && endPt.x >= startPt.x - 25) {
            let verticalLineEqn = startPt.x
            return coords.x <= verticalLineEqn + 25 && coords.x >= verticalLineEqn - 25
        } else {
            let grad = (startPt.y - endPt.y) / (startPt.x - endPt.x)
            let yOnLineForGivenX = (grad * (coords.x - startPt.x)) + startPt.y
            return coords.y <= yOnLineForGivenX + 25 && coords.y >= yOnLineForGivenX - 25
        }
    }
    
    @IBAction func toggleShapeRecognition(_ sender: UIBarButtonItem) {
        shapeRecognition = !shapeRecognition
        print("shape recognition = ", shapeRecognition)
    }

    func colourChosen(_ chosenColour: UIColor) {
        drawColour = chosenColour
        mode = .DRAWING
    }
    
    @IBAction func eraserChosen(_ sender: UIBarButtonItem) {
        let chosen = sender.tag
        mode = chosen == 20 ? .COMPLETE_REMOVE : .DRAWING
    }
  
    @IBAction func partialChosen(_ sender: UIBarButtonItem) {
          let chosen = sender.tag
          mode = chosen == 21 ? .PARTIAL_REMOVE : .DRAWING
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
        
    }
}
