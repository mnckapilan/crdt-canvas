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
    
    /// Singleton instance. Much more resource-friendly than creating multiple new instances.
    static let shared = AutomergeJavaScript()
    private let vm = JSVirtualMachine()
    private let context: JSContext
   
    private override init() {
        let jsCode = try? String.init(contentsOf: Bundle.main.url(forResource: "Canvas.bundle", withExtension: "js")!)
        
        // Create a new JavaScript context that will contain the state of our evaluated JS code.
        self.context = JSContext(virtualMachine: self.vm)
       
        self.context.evaluateScript("var console = { log: function(message) { _consoleLog(message) } }")
        let consoleLog: @convention(block) (String) -> Void = { message in
            print("console.log: " + message)
        }
        
        self.context.setObject(unsafeBitCast(consoleLog, to: AnyObject.self), forKeyedSubscript: "_consoleLog" as (NSCopying & NSObjectProtocol)?)
        
        
        
        // Evaluate the JS code that defines the functions to be used later on.
        self.context.evaluateScript(jsCode)
    }
       
    func javascript_func(_ json: JSON, completion: @escaping (_ randomNumber: String) -> Void) {
        // Run this asynchronously in the background
        
        let jsonString = json.rawString([.castNilToNSNull: true])
        print (jsonString!)
        
        DispatchQueue.global(qos: .userInitiated).async {
            var randomNumber = "this failed"
            let jsModule = self.context.objectForKeyedSubscript("Canvas")
            let jsSynchronizer = jsModule?.objectForKeyedSubscript("Synchronizer")
           
            // In the JSContext global values can be accessed through `objectForKeyedSubscript`.
            if let result = jsSynchronizer?.objectForKeyedSubscript("randomNumber").call(withArguments: [jsonString!]) {
                print(result)
                randomNumber = String(result.toString())
               }
            
               // Call the completion block on the main thread
               DispatchQueue.main.async {
                   completion(randomNumber)
               }
       }
    }
}
