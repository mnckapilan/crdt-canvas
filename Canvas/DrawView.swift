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
    
    public var mcSession: MCSession?
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.backgroundColor = UIColor.black
    }
    
    func getIdentifier() -> String {
        return UUID().uuidString
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        print("start")
        
        let point = Point(fromCGPoint: Array(touches)[0].location(in: self))
        let stroke = Stroke(points: [point], colour: drawColour)
        currentIdentifier = getIdentifier()
        pointsToWrite = [point]
        let change = Change.addStroke(stroke, currentIdentifier)
        handleChange(change: change)
    }
    
    func handleChange(change: Change) {
        AutomergeJavaScript.shared.addChange(change) { (returnValue) in
            self.lines = returnValue.0
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
        if pointsToWrite.count >= 15 {
            pointsToWrite.remove(at: 0)
            handleChange(change: Change.addPoint(pointsToWrite, currentIdentifier))
            pointsToWrite = [pointsToWrite.last!]
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        currentIdentifier = nil
        print(pointsToWrite.count)
        pointsToWrite = []
        c = 0
    }
    
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else {
            return
        }
                
        for (_, stroke) in lines {
            context.setStrokeColor(stroke.colour.cgColor)
            print(stroke.points.count)
            context.addPath(stroke.cgPath)
            context.strokePath()
        }
    }
    
    @IBAction func colourChosen(_ sender: UIButton) {
        guard let chosen = Colour(tag: sender.tag) else {
            return
        }
        drawColour = chosen.colour
    }
    
    @IBAction func clearCanvas(_ sender: Any) {
        // TODO FIX THIS
    }

    
    func incomingChange(_ change: String) {
        AutomergeJavaScript.shared.applyExternalChanges(change) { (returnValue) in
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
