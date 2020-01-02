//
//  CRDTEngine.swift
//  Canvas
//
//  Created by Hashan Punchihewa on 31/12/2019.
//  Copyright © 2019 jackmorrison. All rights reserved.
//

import Foundation

typealias CRDTDocument = [String: Stroke]
typealias CRDTResult = (CRDTDocument, String)
typealias CRDTCallback<T> =  (_ returnValue: T) -> Void

protocol CRDTEngine {
    func addChange(_ change: Change) -> CRDTResult
    func applyExternalChanges(_ changes: String) -> CRDTDocument
    func getAllChanges() -> String
}
