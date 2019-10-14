//
//  DrawView.swift
//  Canvas
//
//  Created by Hashan Punchihewa on 13/10/2019.
//  Copyright © 2019 Hashan Punchihewa. All rights reserved.
//

import UIKit

class DrawView: UIView {

    var lines: [Line] = []
    var lastPoint: CGPoint!
    var drawColour = UIColor.white.cgColor
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.backgroundColor = UIColor.black
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        lastPoint = Array(touches)[0].location(in: self)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        let newPoint = Array(touches)[0].location(in: self)
        lines.append(Line(start: lastPoint, end: newPoint))
        lastPoint = newPoint
        
        self.setNeedsDisplay()
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        lastPoint = nil
    }
    
    override func draw(_ rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()
        context?.beginPath()
        for line in lines {
            context?.move(to: line.start)
            context?.addLine(to: line.end)
        }
        context?.setLineCap(CGLineCap.round)
        context?.setLineWidth(5)
        context?.setStrokeColor(drawColour)
        context?.strokePath()
    }
    
    @IBAction func colourChosen(_ sender: UIButton) {
        guard let chosen = Colour(tag: sender.tag) else {
            return
        }
        drawColour = chosen.colour.cgColor
    }

}
