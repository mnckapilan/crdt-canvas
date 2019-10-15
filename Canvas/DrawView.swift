//
//  DrawView.swift
//  Canvas
//
//  Created by Hashan Punchihewa on 13/10/2019.
//  Copyright © 2019 Hashan Punchihewa. All rights reserved.
//

import UIKit

class DrawView: UIView {

    var lines: [UIBezierPath] = []
    var lastPath: UIBezierPath!
    var count: Int = 0
    var prevPoint: CGPoint!
    var pPrevPoint: CGPoint!
    
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
        print("move")
        count = count + 1
        let point = Array(touches)[0].location(in: self)
        if (count % 3 == 2) {
            lastPath.addCurve(to: point, controlPoint1: pPrevPoint, controlPoint2: prevPoint)
        } else if (count % 3 == 0) {
            pPrevPoint = point
        } else if (count % 3 == 1) {
            prevPoint = point
        }
                
        self.setNeedsDisplay()
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        print("end")
        lines.append(lastPath)
        lastPath = nil
        let vc = ViewController()
        print("here")
        guard let mcSession = vc.mcSession else { return }
        print("here2")
        if mcSession.connectedPeers.count > 0 {
            print("connected")
            do {
                let data = "hello".data(using: .utf8)!
                try mcSession.send(data, toPeers: mcSession.connectedPeers, with: .reliable)
                print("worked")
            } catch {
                print("failed")
                let ac = UIAlertController(title: "Send error", message: error.localizedDescription, preferredStyle: .alert)
                ac.addAction(UIAlertAction(title: "OK", style: .default))
            }
            
        } else {
            print("nothing connected")
        }
        
    }
    
    override func draw(_ rect: CGRect) {
        print("draw")

        let context = UIGraphicsGetCurrentContext()
        context?.beginPath()
        context?.setStrokeColor(UIColor.orange.cgColor)
        for line in lines {
            context?.addPath(line.cgPath)
        }
        if (lastPath != nil) {
            context?.addPath(lastPath.cgPath)
        }
        context?.strokePath()
    }

}
