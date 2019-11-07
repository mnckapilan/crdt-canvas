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
    
    func lookUpStroke(_ point: Point) -> String {
        for (str, stroke) in lines {
            if (stroke.contains(givenPoint: point)) {
                return str;
            }
        }
        return ""
    }
    
    func lookUpStroke2(_ point: Point) -> (String, Int)? {
        for (str, stroke) in lines {
            let p = stroke.indexOf(givenPoint: point)
            if let t = p {
                return (str, t)
            }
        }
        return nil
    }

    func partialRemove(_ point: Point) {
        let t = lookUpStroke2(point)
        if let (strokeId, index) = t {
            handleChange(change: Change.partialRemoveStroke(strokeId, index))
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
            let strokeId = lookUpStroke(point)
            if (strokeId != "") {
                let stroke = lines[strokeId]!
                handleChange(change: Change.removeStroke(strokeId))
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
                  print("redrawing")
                  redrawStraightLine(currentIdentifier)
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
        let start = line.points[0]!
        let end = line.points[count - 1]!
        
        handleChange(change: Change.removeStroke(id))
        var new_points = [start, start, end, end]
        
        if (start.cgPoint.x - end.cgPoint.x != 0) {
            let grad = (start.cgPoint.y - end.cgPoint.y) / (start.cgPoint.x - end.cgPoint.x)
            let nextX1 = (start.cgPoint.x + end.cgPoint.x) / 3
            let nextX2 = (start.cgPoint.x + end.cgPoint.x) * 2 / 3
            let nextY1 = (grad * (nextX1 - start.cgPoint.x)) + start.cgPoint.y
            let nextY2 = (grad * (nextX2 - start.cgPoint.x)) + start.cgPoint.y
            let nextPt1 = Point(x: Float(nextX1), y: Float(nextY1))
            let nextPt2 = Point(x: Float(nextX2), y: Float(nextY2))
            
            new_points = [start, nextPt1, nextPt2, end]
        }
        
        print(new_points)

        let stroke = Stroke(points: new_points, colour: line.colour)
        handleChange(change: Change.addStroke(stroke, id))
        let test = lines[id]!
        print(test.cgPath)
        
        undoStack.append((id, line, Stroke.ActionType.redraw))

    }
    
    func isStraightLine(_ points: [Point?]) -> Bool {
        let startPt = points[0]!.cgPoint
        let endPt = points[points.count - 1]!.cgPoint
        print(startPt, endPt)
        
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
    
    func isInLine(_ coords: CGPoint, _ startPt: CGPoint, _ endPt: CGPoint) -> Bool {
        if (endPt.x <= startPt.x + 15 && endPt.x >= startPt.x - 15) {
            let verticalLineEqn = startPt.x
            return coords.x <= verticalLineEqn + 15 && coords.x >= verticalLineEqn - 15
        } else {
            let grad = (startPt.y - endPt.y) / (startPt.x - endPt.x)
            let yOnLineForGivenX = (grad * (coords.x - startPt.x)) + startPt.y
            
            return coords.y <= yOnLineForGivenX + 15 && coords.y >= yOnLineForGivenX - 15
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
                handleChange(change: Change.removeStroke(id))
                redoStack.append((id, lines[id]!, actionType))
            } else if (actionType == Stroke.ActionType.remove) {
                handleChange(change: Change.addStroke(stroke, id))
                redoStack.append((id, stroke, actionType))
            } else if (actionType == Stroke.ActionType.redraw) {
                let s = lines[id]
                handleChange(change: Change.removeStroke(id))
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
                handleChange(change: Change.removeStroke(id))
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
