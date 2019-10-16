//
//  DrawView.swift
//  Canvas
//
//  Created by Hashan Punchihewa on 13/10/2019.
//  Copyright © 2019 Hashan Punchihewa. All rights reserved.
//

import UIKit
import SwiftyJSON

class DrawView: UIView {

    var lines:[(bzPath: UIBezierPath, colour: CGColor)] = []
    var lastPath: UIBezierPath!
    var count: Int = 0
    var prevPoint: CGPoint!
    var pPrevPoint: CGPoint!
    var drawColour = UIColor.white.cgColor
    var stroke:[(x: Float, y: Float)] = []
    
//    struct tempStroke: Codable {
//        var stroke: [CGPoint]
//        var colour: CGColor
//
//        enum CodingKeys: String, CodingKey {
//            case stroke = "stroke"
//            case colour = "colour"
//        }
//    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.backgroundColor = UIColor.black
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
        
        stroke.append((Float(point.x), Float(point.y)))

        self.setNeedsDisplay()
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        lines.append((bzPath: lastPath, colour: drawColour))
        lastPath = nil
    
        let jsonObject: JSON = [
            "stroke": stroke.map({ (arg0) -> JSON in
                let (x, y) = arg0
                return ["x": x, "y": y]
            })
        ]

        stroke = []
        AutomergeJavaScript.shared.javascript_func(jsonObject) { (randomNumber) in
            print(randomNumber)
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

}
