//
//  DrawView.swift
//  Canvas
//
//  Created by Hashan Punchihewa on 13/10/2019.
//  Copyright © 2019 Hashan Punchihewa. All rights reserved.
//

import UIKit
import SwiftyJSON
import MultipeerConnectivity

class DrawView: UIView {

    var lines: [String: Stroke] = [:]
    
    var drawColour = UIColor.white
    var currentIdentifier: String!
    var pointsToWrite: [Point] = []
    var shapeRecognition = false
    
    var undoStack: [(String, Stroke, Stroke.ActionType)] = []
    var redoStack: [(String, Stroke, Stroke.ActionType)] = []
    
    var rubberActive = false
    
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
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let point = Point(fromCGPoint: Array(touches)[0].location(in: self))
        
        if (rubberActive) {
            let strokeId = lookUpStroke(point)
            if (strokeId != "") {
                let stroke = lines[strokeId]!
                handleChange(change: Change.removeStroke(strokeId))
                undoStack.append((strokeId, stroke, Stroke.ActionType.remove))
            }
        } else {
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
        if pointsToWrite.count > 0 && pointsToWrite.last! != point {
            pointsToWrite.append(point)
        }
        if pointsToWrite.count >= 5 {
            pointsToWrite.remove(at: 0)
            handleChange(change: Change.addPoint(pointsToWrite, currentIdentifier))
            pointsToWrite = [pointsToWrite.last!]
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        let currentLine = lines[currentIdentifier]!
        if (shapeRecognition) {
            let isStraight = isStraightLine(currentLine.points)
            if (isStraight) {
                print("redrawing")
                redrawStraightLine(currentLine)
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
    
    func redrawStraightLine(_ line: Stroke) {
        let count = line.points.count
        let start = line.points[0]
        let end = line.points[count - 1]
        
        handleChange(change: Change.removeStroke(currentIdentifier))
        let new_points = [start, end, end, end]
        let stroke = Stroke(points: new_points, colour: line.colour)
        currentIdentifier = getIdentifier()
        handleChange(change: Change.addStroke(stroke, currentIdentifier))
    }
    
    func isStraightLine(_ points: [Point]) -> Bool {
        let startPt = points[0].cgPoint
        let endPt = points[points.count - 1].cgPoint
        print(startPt, endPt, points.count)
        
        var almostStraightLine = true
        for point in points {
            let res = isInLine(point.cgPoint, startPt, endPt)
            if (!res) {
                almostStraightLine = res
                break
            }
        }
        
        return almostStraightLine
    }
    
    func isInLine(_ coords: CGPoint, _ startPt: CGPoint, _ endPt: CGPoint) -> Bool {
        let grad = (startPt.y - endPt.y) / (startPt.x - endPt.x)
        let yOnLineForGivenX = (grad * (coords.x - startPt.x)) + startPt.y
        
        if (coords.y <= yOnLineForGivenX + 15 && coords.y >= yOnLineForGivenX - 15) {
            return true
        } else {
            return false
        }
    }
    
    @IBAction func toggleShapeRecognition(_ sender: UIBarButtonItem) {
        shapeRecognition = !shapeRecognition
        print("shape recognition = ", shapeRecognition)
    }
    
    @IBAction func colourChosen(_ sender: UIBarButtonItem) {
        guard let chosen = Colour(tag: sender.tag) else {
            return
        }
        drawColour = chosen.colour
        rubberActive = false
    }
    
    @IBAction func eraserChosen(_ sender: UIBarButtonItem) {
        let chosen = sender.tag
        rubberActive = chosen == 20
    }
    
    @IBAction func clearCanvas(_ sender: Any) {
        // TODO FIX THIS
        lines = [:]
        undoStack = []
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
