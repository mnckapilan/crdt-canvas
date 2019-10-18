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

    var lines:[(bzPath: UIBezierPath, colour: CGColor)] = []
    var lastPath: UIBezierPath!
    var count: Int = 0
    var prevPoint: CGPoint!
    var pPrevPoint: CGPoint!
    var drawColour = UIColor.white.cgColor
    var stroke: [[String:Float]] = []
    
    var documentString = ""
    public var mcSession: MCSession?
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.backgroundColor = UIColor.black
        AutomergeJavaScript.shared.initDocument() { (returnString) in
            self.documentString = returnString
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        print("start")
        lastPath = UIBezierPath.init()
        lastPath.move(to: Array(touches)[0].location(in: self))
        lastPath.lineCapStyle = CGLineCap.round
        lastPath.lineWidth = 3
        count = -1
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        count = count + 1
        let point = Array(touches)[0].location(in: self)
        if (count % 3 == 2) {
            lastPath.addCurve(to: point, controlPoint1: pPrevPoint, controlPoint2: prevPoint)
        } else if (count % 3 == 0) {
            pPrevPoint = point
        } else if (count % 3 == 1) {
            prevPoint = point
        }
        
        stroke.append(["x": Float(point.x), "y": Float(point.y)])

        self.setNeedsDisplay()
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        lines.append((bzPath: lastPath, colour: drawColour))
        sendPath(lastPath)
        lastPath = nil
        
        let strokeObject: JSON = [
            "stroke": stroke
        ]
            
        stroke = []
        
        AutomergeJavaScript.shared.addStroke(strokeObject, documentString) { (returnValue) in
            self.documentString = returnValue[0]
    }
    }
    
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else {
            return
        }
        context.beginPath()
        for (bPath, colour) in lines {
            context.setStrokeColor(colour)
            context.addPath(bPath.cgPath)
            context.strokePath()
        }
        if (lastPath != nil) {
            context.addPath(lastPath.cgPath)
        }
        context.strokePath()
    }
    
    @IBAction func colourChosen(_ sender: UIButton) {
        guard let chosen = Colour(tag: sender.tag) else {
            return
        }
        drawColour = chosen.colour.cgColor
    }
    
    @IBAction func clearCanvas(_ sender: Any) {
        lines = []
        self.setNeedsDisplay()
    }
    
    public func addPath(_ path: UIBezierPath) {
        // Need to pass in the colour of the path here too, currently default set to red
        lines.append((path, UIColor.red.cgColor))
        self.setNeedsDisplay()
    }
    
    func sendPath(_ path: UIBezierPath) {
        let data = try NSKeyedArchiver.archivedData(withRootObject: path)
        
        if let m = mcSession {
            if m.connectedPeers.count > 0 {
                do {
                    try m.send(data, toPeers: m.connectedPeers, with: .reliable)
                } catch _ as NSError {
                }
            }
        }
        
    }

}
