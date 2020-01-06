//
//  NativeCRDTEngine.swift
//  Canvas
//
//  Created by Hashan Punchihewa on 31/12/2019.
//  Copyright © 2019 jackmorrison. All rights reserved.
//

import Foundation

class NativeCRDTEngine: CRDTEngine {    
    var doc: CRDTDocument = [:]
    
    private func handleChange(_ change: Change) {
        //print(doc)
        switch change {
        case let .addPoint(point, i):
            if doc[i] != nil {
                //print("add point")
                doc[i]?.points.append(contentsOf: point)
                if doc[i]!.segments.count == 0 {
                    var l = doc[i]!.points.count
                    doc[i]!.segments = [Segment(Double(l), Double(l + point.count))]
                } else {
                    doc[i]?.segments[0].end += Double(point.count)
                }
            }
        case let .addStroke(stroke, i):
            //print("add stroke \(i)")
            if doc[i] == nil {
                doc[i] = stroke
            }
        case let .betterPartial(id, lower, upper):
            if doc[id] != nil {
                let stroke = doc[id]!
                var end = stroke.segments.count
                var j = 0
                while j < end {
                    let segment = stroke.segments[j]
                    if segment.start < lower && lower <= segment.end {
                        if segment.start <= upper && upper < segment.end {
                            stroke.segments.insert(Segment.init(upper, segment.end), at: j + 1)
                            segment.end = lower
                            j += 1
                            end += 1
                        }
                        segment.end = lower
                    } else if lower <= segment.start && segment.end <= upper {
                        stroke.segments.remove(at: j)
                        j -= 1
                        end -= 1
                    } else if segment.start <= upper && upper <= segment.end {
                        segment.start = upper
                    }
                    j += 1
                }
                print(stroke.segments)
            }
        case let .removeStroke(str):
            doc.removeValue(forKey: str)
        case let .megaAction(strokes):
            for (key, value) in strokes {
                if doc[key] == nil {
                    doc[key] = value
                } else {
                    if value.points.count > doc[key]!.points.count {
                        doc[key]!.points = value.points
                    }
                    if value.segments.count == 0 {
                        doc[key]!.segments = []
                    } else {
                        for i in 0...(value.segments.count - 1) {
                            handleChange(Change.betterPartial(key, value.segments[i].end, value.segments[i].start))
                        }
                    }
                }
            }
        //case .clearCanvas:
        //    doc = [:]
        }
    }
    
    func clearCRDT() {
        doc = [:]
        return
    }
    
    func addChange(_ change: Change) -> CRDTResult {
        handleChange(change)
        let encoder = JSONEncoder()
        let value = try! encoder.encode(change)
        return (doc, NativeCRDTEngine.dataToString(value))
    }
    
    func applyExternalChanges(_ changes: String) -> CRDTDocument {
        let decoder = JSONDecoder()
        do {
            print(changes)
            let value = try decoder.decode(Change.self, from: NativeCRDTEngine.stringToData(changes))
            //for v in value {
            handleChange(value)
        } catch {
            print("WHOOPS")
            print("\(error)")
        }
        //}
        return doc
    }
    
    func getAllChanges() -> String {
        var toSend: CRDTDocument = [:]
        for (key, value) in doc {
            if value.segments.count > 0 {
                toSend[key] = value
            }
        }
        let encoder = JSONEncoder()
        return NativeCRDTEngine.dataToString(try! encoder.encode(Change.megaAction(toSend)))
    }
    
    static func dataToString(_ data: Data) -> String {
        return String(data: data, encoding: .utf8)!
    }
    
    static func stringToData(_ str: String) -> Data {
        return str.data(using: .utf8)!
    }
}
