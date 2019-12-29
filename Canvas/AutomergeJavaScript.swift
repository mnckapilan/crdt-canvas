//
//  AutomergeJavaScript.swift
//  Canvas
//
//  Created by Kapilan M on 10/10/2019.
//  Copyright © 2019 Apple. All rights reserved.
//

import JavaScriptCore

class AutomergeJavaScript: NSObject {
    
    // Singleton instance. More resource-friendly than creating multiple new instances.
    static let shared = AutomergeJavaScript()
    private let vm = JSVirtualMachine()
    private let context: JSContext
   
    private override init() {
        let jsCode = try? String.init(contentsOf: Bundle.main.url(forResource: "Canvas.bundle", withExtension: "js")!)
        
        // Create a new JavaScript context that will contain the state of our evaluated JS code.
        self.context = JSContext(virtualMachine: self.vm)
       context.evaluateScript("var console = { log: function(message) { _consoleLog(message) } }")
       let consoleLog: @convention(block) (String) -> Void = { message in
           print("JavaScript console.log: " + message)
       }
        context.setObject(unsafeBitCast(consoleLog, to: AnyObject.self), forKeyedSubscript: "_consoleLog" as (NSCopying & NSObjectProtocol)?)

        context.exceptionHandler = { context, exception in
            print(exception!.toString()!)
        }
        
        // Evaluate the JS code that defines the functions to be used later on.
        self.context.evaluateScript(jsCode)
    }
    
    func applyExternalChanges(_ changes: String, completion: @escaping (_ returnValue: [String: Stroke]) -> Void) {
        // Run this asynchronously in the background
        
        DispatchQueue.global(qos: .userInitiated).async {
            var returnString: [String: Stroke]!
            let jsModule = self.context.objectForKeyedSubscript("Canvas")
            let jsAutomerger = jsModule?.objectForKeyedSubscript("Automerger")
           
            // In the JSContext global values can be accessed through `objectForKeyedSubscript`.
            if let result = jsAutomerger?.objectForKeyedSubscript("mergeIncomingChanges").call(withArguments: [changes]) {
                do {
                    let s = String(result.toString())
                    let decoder = JSONDecoder()
                    returnString = try decoder.decode([String: Stroke].self, from: s.data(using: .utf8)!)

                } catch {
                
                }

                }
            
               // Call the completion block on the main thread
               DispatchQueue.main.async {
                   completion(returnString)
               }
       }
    }
       
    func addChange(_ change: Change, completion: @escaping (_ returnValue: ([String: Stroke], String)) -> Void) {
        // Run this asynchronously in the background
        do {
            let jsonEncoder = JSONEncoder()
            let jsonData = try jsonEncoder.encode(change)
            let jsonString = String(data: jsonData, encoding: .utf8)
            
            DispatchQueue.global(qos: .userInitiated).async {
                var returnValue: ([String: Stroke], String)!
                 let jsModule = self.context.objectForKeyedSubscript("Canvas")
                 let jsAutomerger = jsModule?.objectForKeyedSubscript("Automerger")
                
                 // In the JSContext global values can be accessed through `objectForKeyedSubscript`.
                 if let result = jsAutomerger?.objectForKeyedSubscript("addChange").call(withArguments: [jsonString!]) {
                        do {
                            let t = result.toArray() as! [String]
                            let decoder = JSONDecoder()
                            let strokes = try decoder.decode([String: Stroke].self, from: t[0].data(using: .utf8)!)
                            returnValue = (strokes, t[1])
                        } catch {

                        }
                    }
                 
                    // Call the completion block on the main thread
                    DispatchQueue.main.async {
                        completion(returnValue)
                    }
            }
        } catch {
            
        }
                
        
    }
    
    func getAllChanges(completion: @escaping (_ returnValue: String) -> Void) {
        // Run this asynchronously in the background
        DispatchQueue.global(qos: .userInitiated).async {
             var returnValue: String!
             let jsModule = self.context.objectForKeyedSubscript("Canvas")
             let jsAutomerger = jsModule?.objectForKeyedSubscript("Automerger")
            
             // In the JSContext global values can be accessed through `objectForKeyedSubscript`.
             if let result = jsAutomerger?.objectForKeyedSubscript("getAllChanges").call(withArguments: []) {
                    
                    returnValue = String(result.toString())

                }
             
                // Call the completion block on the main thread
                DispatchQueue.main.async {
                    completion(returnValue)
                }
        }
                
        
    }
}
