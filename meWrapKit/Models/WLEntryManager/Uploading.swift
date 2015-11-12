//
//  Uploading.swift
//  
//
//  Created by Sergey Maximenko on 10/26/15.
//
//

import Foundation
import CoreData

@objc(Uploading)
class Uploading: Entry {
    
    override class func entityName() -> String {
        return "Uploading"
    }
    
    var inProgress = false

}
