//
//  ProtocolMessage.swift
//  Canvas
//
//  Created by Kapilan M on 28/11/2019.
//  Copyright © 2019 jackmorrison. All rights reserved.
//

import Foundation
import SwiftyJSON

class ProtocolMessage {
    struct AddStrokeProtocol : Codable {
        var type: String
        var identifier: String
        var weight: Float
        var colour: [Int]
        var start: [Int]
    }

    struct AddPointProtocol: Codable {
        var type: String
        var identifier: String
        var points: [[Int]]
    }

    func protocolAddStroke(_ changeJson: JSON) -> String {
        // We don't set weight for the time being
        var dict = AddStrokeProtocol(type: "ADD", identifier: "", weight: 5.0, colour: [0,0,0], start: [0,0])
        let ops = changeJson["ops"]
        dict.identifier = ops[1]["obj"].stringValue
        dict.start[0] = ops[4]["value"].int!
        dict.start[1] = ops[5]["value"].int!
        dict.colour[0] = ops[10]["value"].int!
        dict.colour[1] = ops[13]["value"].int!
        dict.colour[2] = ops[12]["value"].int!
    
        do {
            let protocolJson = try JSONEncoder().encode(dict)
            let jsonString = String(data: protocolJson, encoding: .utf8)
            return jsonString!
        } catch {print(error)}
        // var protocolJson =JSON(dict)
        
        return "ERROR: Couldn't translate add_stroke to protocol"
    }

    /*Points are added in multiples of 5 operations. so (ops - 1) % 5  == 0
        theres an extra op at the end for setting 'end' which we can ignore.*/

        /* op1: is insert and contains the id of the point list.
                 this is what we can use as a stroke id.
            op2: irrelevant
            op3: contains x coord
            op4: contains y coord
            op5: irrelevant
            */
    func protocolAddPoint(_ changeJson: JSON) -> String {
        // We don't set weight for the time being
        let dict = AddPointProtocol(type: "APPEND", identifier: "", points: [[0,0]])
        let ops = changeJson["ops"]
        var identifier = ops[0]["obj"].stringValue

        for (indexStr: String, subJson: JSON) in ops {
           let i = Int(indexStr) 
            if (i % 5 == 0) {
                dict.identifier = subJson["obj"].strinValue
            }
            /


        }

        do {
            let protocolJson = try JSONEncoder().encode(dict)
            let jsonString = String(data: protocolJson, encoding: .utf8)
            return jsonString!
        } catch {print(error)}
        // var protocolJson =JSON(dict)
        
        return "ERROR: Couldn't translate add_stroke to protocol"
    }

    func getProtocolMessage(_ change: String) -> String {
        let json = JSON.init(parseJSON:change)[0]
        let type = json["message"].stringValue
            var protocolJson = ""

            if (type == "ADD_STROKE") {
                print("type is addstroke")
                protocolJson = protocolAddStroke(json)
            }
            return protocolJson
        }


}
