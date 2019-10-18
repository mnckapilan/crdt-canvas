//
//  AutomergeJavaScript.swift
//  Canvas
//
//  Created by Kapilan M on 10/10/2019.
//  Copyright © 2019 Apple. All rights reserved.
//

import JavaScriptCore
import SwiftyJSON

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
       
    func addStroke(_ stroke: JSON, _ currentDocument: String, completion: @escaping (_ returnValue: [String]) -> Void) {
        // Run this asynchronously in the background
        
        let strokeJsonString = stroke.rawString([.castNilToNSNull: true])
                
        DispatchQueue.global(qos: .userInitiated).async {
            var returnValue: [String] = []
            let jsModule = self.context.objectForKeyedSubscript("Canvas")
            let jsAutomerger = jsModule?.objectForKeyedSubscript("Automerger")
           
            // In the JSContext global values can be accessed through `objectForKeyedSubscript`.
            if let result = jsAutomerger?.objectForKeyedSubscript("addStroke").call(withArguments: [currentDocument, strokeJsonString!]) {
                returnValue = result.toArray() as! [String]
               }
            
               // Call the completion block on the main thread
               DispatchQueue.main.async {
                   completion(returnValue)
               }
       }
    }
    
    func initDocument(completion: @escaping (_ randomNumber: String) -> Void) {
        // Run this asynchronously in the background
        DispatchQueue.global(qos: .userInitiated).async {
            var returnString = "failed"
            let jsModule = self.context.objectForKeyedSubscript("Canvas")
            let jsAutomerger = jsModule?.objectForKeyedSubscript("Automerger")
           
            // In the JSContext global values can be accessed through `objectForKeyedSubscript`.
            if let result = jsAutomerger?.objectForKeyedSubscript("initDocument").call(withArguments: []) {
                returnString = String(result.toString())
               }
               // Call the completion block on the main thread
               DispatchQueue.main.async {
                   completion(returnString)
               }
       }
    }
}
