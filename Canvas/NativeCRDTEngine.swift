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
        case let .addPoint(point, i, index):
            if doc[i] != nil && doc[i]!.points.count <= index {
                doc[i]?.points.append(contentsOf: point)
                doc[i]?.segments[0].end += Double(point.count)
            }
        case let .addStroke(stroke, i):
            if doc[i] == nil {
                doc[i] = stroke
            }
        case let .betterPartial(id, lower, upper):
            let stroke = doc[id]!
            var end = stroke.segments.count
            var j = 0
            while j < end {
                let segment = stroke.segments[j]
                if segment.start < lower && lower <= segment.end {
                    if segment.start <= upper && upper < segment.end {
                        stroke.segments.append(Segment.init(upper, segment.end))
                        segment.end = lower
                    }
                    segment.end = lower
                } else if segment.start <= upper && upper <= segment.end {
                    segment.start = upper
                } else if lower <= segment.start && segment.end <= upper {
                    stroke.segments.remove(at: j)
                    j -= 1
                    end -= 1
                }
                j += 1
            }
            print(stroke.segments)
        case let .removeStroke(str):
            doc.removeValue(forKey: str)
        case .clearCanvas:
            doc = [:]
        }
    }
    
    func addChange(_ change: Change) -> CRDTResult {
        handleChange(change)
        let encoder = JSONEncoder()
        let value = try! encoder.encode([change])
        return (doc, NativeCRDTEngine.dataToString(value))
    }
    
    func applyExternalChanges(_ changes: String) -> CRDTDocument {
        let decoder = JSONDecoder()
        let value = try! decoder.decode([Change].self, from: NativeCRDTEngine.stringToData(changes))
        for v in value {
            handleChange(v)
        }
        return doc
    }
    
    func getAllChanges() -> String {
        return "[]"
    }
    
    static func dataToString(_ data: Data) -> String {
        return String(data: data, encoding: .utf8)!
    }
    
    static func stringToData(_ str: String) -> Data {
        return str.data(using: .utf8)!
    }
}
