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
    var c = 0
    
    var undoStack: [(String, Stroke.StrokeType)] = []
    var redoStack: [(Stroke, Stroke.StrokeType)] = []
    var removedLines: [String: Stroke] = [:]
    
    var isEraser = false
    
    public var mcSession: MCSession?
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.backgroundColor = UIColor.black
    }
    
    func getIdentifier() -> String {
        return UUID().uuidString
    }
    
    func lookUpStroke(_ point: Point) -> String{
        for (str, stroke) in lines {
            if (stroke.contains(givenPoint: point)) {
                return str;
            }
        }
        return ""
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
//        print("start")
        let point = Point(fromCGPoint: Array(touches)[0].location(in: self))
        
        if (isEraser) {
            let strokeId = lookUpStroke(point)
            let change = Change.removeStroke(strokeId)
            removedLines[strokeId] = lines[strokeId]
            handleChange(change: change)
            undoStack.append((strokeId, Stroke.StrokeType.remove))
        } else {
            let stroke = Stroke(points: [point], colour: drawColour)
            currentIdentifier = getIdentifier()
            pointsToWrite = [point]
            let change = Change.addStroke(stroke, currentIdentifier)
            handleChange(change: change)
            undoStack.append((currentIdentifier, Stroke.StrokeType.add))
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
        } else {
            //print(pointsToWrite.last!)
            //print(point)
        }
        if pointsToWrite.count >= 10 {
            pointsToWrite.remove(at: 0)
            handleChange(change: Change.addPoint(pointsToWrite, currentIdentifier))
            pointsToWrite = [pointsToWrite.last!]
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        currentIdentifier = nil
//        print(pointsToWrite.count)
        pointsToWrite = []
        c = 0
    }
    
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else {
            return
        }
                
        for (_, stroke) in lines {
            context.setStrokeColor(stroke.colour.cgColor)
//            print(stroke.points.count)
            context.addPath(stroke.cgPath)
            context.strokePath()
        }
    }
    
    @IBAction func colourChosen(_ sender: UIButton) {
        guard let chosen = Colour(tag: sender.tag) else {
            return
        }
        drawColour = chosen.colour
        isEraser = false
    }
    
    @IBAction func eraserChosen(_ sender: UIButton) {
        let chosen = sender.tag
        isEraser = chosen == 20
    }
    
    @IBAction func clearCanvas(_ sender: Any) {
        // TODO FIX THIS
        lines = [:]
        handleChange(change: Change.clearCanvas)
        self.setNeedsDisplay()
        
    }

    @IBAction func undoLastStroke(_ sender: Any) {
        if let (id, strokeType) = undoStack.popLast() {
            if (strokeType == Stroke.StrokeType.add) {
                let stroke = lines[id]!
                handleChange(change: Change.removeStroke(id))
                redoStack.append((stroke, strokeType))
            } else if (strokeType == Stroke.StrokeType.remove) {
                let stroke = removedLines[id]!
                handleChange(change: Change.addStroke(stroke, id))
                redoStack.append((stroke, strokeType))
            }
            
        }
    }
    
    @IBAction func redoLastStroke(_ sender: Any) {
        if let (stroke, strokeType) = redoStack.popLast() {
            let id = getIdentifier()
            handleChange(change: Change.addStroke(stroke, id))
            undoStack.append((id, strokeType))
        }
    }

    func incomingChange(_ change: String) {
        AutomergeJavaScript.shared.applyExternalChanges(change) { (returnValue) in
            self.lines = returnValue
            self.setNeedsDisplay()
        }
    }
    
    func sendPath(_ change: String) {
//        print(change)
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
