//
//  DrawView.swift
//  Canvas
//
//  Created by Hashan Punchihewa on 13/10/2019.
//  Copyright © 2019 Hashan Punchihewa. All rights reserved.
//

import UIKit
import MultipeerConnectivity
import XMPPFrameworkSwift

class DrawView: UIView {
    
    var lines: [String: Stroke] = [:]
    var cache: [String: CGPath] = [:]
    let engine: CRDTEngine = NativeCRDTEngine() //AutomergeJavaScript.shared
    
    var drawColour = UIColor.blue
    var thickness: Float = 1.0
    var currentIdentifier: String!
    var pointsToWrite: [Point] = []
    var xmppController: XMPPController?
    var mainViewController: ViewController?
    var bluetoothService: BluetoothService?
    
    @IBOutlet var tracker: UIImageView!
    @IBOutlet var shapeRecognitionButton: UIBarButtonItem!
    @IBOutlet var eraserButton: UIBarButtonItem!
    @IBOutlet var partialButton: UIBarButtonItem!

    var undoStack: [Change] = []
    var redoStack: [Change] = []
    
    var mode = Mode.DRAWING
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.backgroundColor = UIColor.white
    }
    
    func getIdentifier() -> String {
        return UUID().uuidString
    }
    
    func lookUpStroke(_ point: Point) -> (String, Double, Double)? {
        for (str, stroke) in lines {
            if let (t1, t2) = stroke.indexOf(givenPoint: point) {
                return (str, t1, t2);
            }
        }
        return nil
    }
    
    func partialRemove(_ point: Point) {
        var changes: [Change] = []
        for (str, stroke) in lines {
            for segment in stroke.segments {
                let start = Int(floor(segment.start))
                let end = Int(ceil(segment.end))
                
                if start >= end {
                    continue
                }
                
                let shapes = stroke.getPoints(start, end)
                
                if shapes.count == 0 {
                    continue
                }
                
                for i in 0...(shapes.count - 1) {
                    let shape = shapes[i]
                    let z = i + start
                    //print(shape)
                    //print(point)
                    let result = Geometry.findIntersectionPoints(shape: shape, circle: point, radius: 15, depth: 0)
                    //print(i, result)
                    switch result {
                    case let .LEFT_OPEN(t):
                        print(i, result)
                        changes.append(Change.betterPartial(str, Double(z) + Double(t), Double(z + 1)))
                        //handleChange(change: Change.betterPartial(str, Double(z) + Double(t), Double(z + 1)))
                        //print(t)
                        //return
                    case let .RIGHT_OPEN(t):
                        print(i, result)
                        changes.append(Change.betterPartial(str, Double(z), Double(z) + Double(t)))
                        //handleChange(change: )
                        //print(t)
                        //return
                    case let .MIDDLE_OPEN(t1, t2):
                        //print(t1, t2)
                        print(i, result)
                        changes.append(Change.betterPartial(str, Double(z) + Double(t1), Double(z) + Double(t2)))
                        //handleChange(change: )
                        //return
                    case .CLOSED:
                        print(i, result)
                        changes.append(Change.betterPartial(str, Double(z), Double(z + 1)))
                        //handleChange(change: )
                        //return
                    default:
                        break
                    }
                }
            }
        }
        for change in changes {
            handleChange(change: change)
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let point = Point(fromCGPoint: Array(touches)[0].location(in: self))
        
        switch mode {
        case .SHAPE_RECOGNITION, .DRAWING:
            let stroke = Stroke(points: [point], colour: drawColour, thickness: thickness)
            currentIdentifier = getIdentifier()
            pointsToWrite = [point]
            let change = Change.addStroke(stroke, currentIdentifier)
            undoStack.append(getInverseChange(change: change)!)
            handleChange(change: change)
            redoStack = []
        case .COMPLETE_REMOVE:
            if let (strokeId, t, t2) = lookUpStroke(point) {
                handleChange(change: Change.betterPartial(strokeId, t, t2))
            }
            redoStack = []
        case .PARTIAL_REMOVE:
            partialRemove(point)
            tracker.isHidden = false
            tracker.layer.borderWidth = 1
            tracker.layer.masksToBounds = false
            tracker.layer.borderColor = UIColor.black.cgColor
            tracker.layer.cornerRadius = tracker.frame.height/2
            tracker.clipsToBounds = true
            tracker.center = point.cgPoint
            redoStack = []
        }
    }
    
    func handleChange(change: Change) {
        let returnValue = engine.addChange(change)
        self.lines = returnValue.0
        self.sendPath(returnValue.1)
        updateCache(change)
        self.setNeedsDisplay()
    }
    
    func refreshDisplay() {
        undoStack = []
        redoStack = []
        for (key, value) in lines {
            if value.segments.count > 0 {
                let change = Change.betterPartial(key, 0, Double(value.points.count))
                let returnValue = engine.addChange(change)
                self.lines = returnValue.0
                updateCache(change)
                self.setNeedsDisplay()
            }
        }
        //handleChange(change: Change.clearCanvas)
        self.setNeedsDisplay()
    }
    
    func updateCache(_ change: Change) {
        /*switch change {
        case let .addPoint(_, i):
            cache.removeValue(forKey: i)
        case let .addStroke(_, i):
            cache.removeValue(forKey: i)
        case let .removeStroke(i):
            cache.removeValue(forKey: i)
        case .clearCanvas:
            cache = [:]
        case let .betterPartial(i, _, _):
            cache.removeValue(forKey: i)
        }*/
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        let point = Point(fromCGPoint: Array(touches)[0].location(in: self))
        switch mode {
        case .DRAWING, .SHAPE_RECOGNITION:
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
        }
    }
        
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if (mode == Mode.SHAPE_RECOGNITION) {
            let currentLine = lines[currentIdentifier]!
            let isStraight = Geometry.isStraightLine(currentLine.points)
            if (isStraight) {
                // If your rectangle gets corrected to a straight line, it's because you drew a rectangle that was too small
                print("found straight line")
                redrawStraightLine(currentIdentifier)
            } else {
                let (rectangle, corners) = Geometry.isRectangle(currentLine.points)
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
        
        //print(lines.count)
        for (id, stroke) in lines {
            //print(id)
            context.setStrokeColor(stroke.colour.cgColor)
            context.setLineWidth(CGFloat(stroke.thickness))
            context.setLineCap(CGLineCap.round)
            /*if cache[id] == nil {
                cache[id] = stroke.cgPath
            }
            context.addPath(cache[id]!)*/
            context.addPath(stroke.cgPath)
            context.strokePath()
        }
    }
    
    func redrawStraightLine(_ id: String) {
        let line = lines[id]!
        let count = line.points.count
        let start = line.points[0]
        let end = line.points[count - 1]
        handleChange(change: Change.removeStroke(id))
        let stroke = Stroke(points: [start], colour: line.colour, isShape: true, thickness: line.thickness)
        print("stroke to be redrawn:", stroke.points)
        currentIdentifier = getIdentifier()
        handleChange(change: Change.addStroke(stroke, currentIdentifier))
        handleChange(change: Change.addPoint([end], currentIdentifier))
        //undoStack.append((currentIdentifier, line, Stroke.ActionType.redraw))
    }
    
    func redrawRectangle(_ id: String, _ points: [Point]) {
        let line = lines[id]!
        handleChange(change: Change.betterPartial(id, 0, Double(lines[id]!.points.count)))
        //handleChange(change: Change.removeStroke(id))
        let stroke = Stroke(points: [points[0]], colour: line.colour, isShape: true, thickness: line.thickness)
        currentIdentifier = getIdentifier()
        handleChange(change: Change.addStroke(stroke, currentIdentifier))
        handleChange(change: Change.addPoint(Array(points[1...]), currentIdentifier))
    }
    
    @IBAction func toggleShapeRecognition(_ sender: UIBarButtonItem) {
        if (mode == .SHAPE_RECOGNITION) {
            mode = .DRAWING
        } else {
            mode = .SHAPE_RECOGNITION
        }
        setButtonColour()
    }
    
    @IBAction func share(_ send: UIBarButtonItem) {
        UIGraphicsBeginImageContext(self.frame.size)
        self.layer.render(in: UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        let activityVC = UIActivityViewController(activityItems: [image as Any], applicationActivities: nil)
        activityVC.popoverPresentationController?.sourceView = self
        activityVC.popoverPresentationController?.barButtonItem = send
        self.mainViewController?.present(activityVC, animated: true, completion: nil)
    }

    func colourChosen(_ chosenColour: UIColor, _ chosenThickness: Float) {
        drawColour = chosenColour
        thickness = chosenThickness
        mode = mode == .SHAPE_RECOGNITION ? .SHAPE_RECOGNITION : .DRAWING
        setButtonColour()
    }
    
    @IBAction func eraserChosen(_ sender: UIBarButtonItem) {
        mode = .COMPLETE_REMOVE
        setButtonColour()
    }

    @IBAction func partialChosen(_ sender: UIBarButtonItem) {
        mode = .PARTIAL_REMOVE
        setButtonColour()
    }
    
    @IBAction func clearCanvas(_ sender: Any) {
        undoStack = []
        redoStack = []
        for (key, value) in lines {
            if value.segments.count > 0 {
                handleChange(change: Change.betterPartial(key, 0, Double(value.points.count)))
            }
        }
        //handleChange(change: Change.clearCanvas)
        self.setNeedsDisplay()
    }
    
    func getInverseChange(change: Change) -> Change? {
        switch change {
        case .addPoint(_, _):
            return nil
        case let .addStroke(_, str):
            return Change.removeStroke(str)
        case let .removeStroke(str):
            //return Change.addStroke(lines[str]!, getIdentifier())
            return Change.megaAction([str:lines[str]!])
        //case .clearCanvas:
        //    return nil
        case let .megaAction(t):
            return Change.removeStroke(t.keys.first!)
        default:
            return nil
        }
    }

    @IBAction func undoLastStroke(_ sender: Any) {
        if let change = undoStack.popLast() {
            let inverse = getInverseChange(change: change)!
            redoStack.append(inverse)
            handleChange(change: change)
        }
    }
    
    @IBAction func redoLastStroke(_ sender: Any) {
        if let change = redoStack.popLast() {
            let inverse = getInverseChange(change: change)!
            undoStack.append(inverse)
            print("***" , change)
            handleChange(change: change)
        }
    }

    func incomingChange(_ change: String) {
        print("** incoming:" + change)
        self.lines = engine.applyExternalChanges(change)
        let decoder = JSONDecoder()
        //let value = try! decoder.decode(Change.self, from: NativeCRDTEngine.stringToData(change))
        //value.forEach { self.updateCache($0) }
        self.setNeedsDisplay()
    }
    
    func sendPath(_ change: String) {
        print("** sending change: " + change)
        if (mainViewController!.isMaster) {
            if xmppController!.isConnected() {
                let t = XMPPMessage.init(type: XMPPMessage.MessageType.groupchat.rawValue, elementID: UIDevice.current.identifierForVendor!.uuidString)
                t.addBody(change)
                xmppController!.room!.send(t)
            }
        }
        bluetoothService!.send(data: change)
    }
    
    func setButtonColour() {
        let MAPPING = [
            Mode.COMPLETE_REMOVE: eraserButton,
            Mode.SHAPE_RECOGNITION: shapeRecognitionButton,
            Mode.PARTIAL_REMOVE: partialButton,
        ]
        for (k, v) in MAPPING {
            v?.tintColor = k == mode ? UIColor.red : UIColor.label
        }
    }
}
