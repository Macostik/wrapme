//
//  Comment.swift
//  
//
//  Created by Sergey Maximenko on 10/26/15.
//
//

import Foundation
import CoreData

@objc(Comment)
class Comment: Contribution {

    override class func entityName() -> String { return "Comment" }
    
    override class func containerType() -> Entry.Type? { return Candy.self }
    
    override var container: Entry? {
        get { return candy }
        set {
            if let candy = newValue as? Candy {
                self.candy = candy
            }
        }
    }
    
    override var canBeUploaded: Bool { return candy?.uploading == nil }
    
    override var deletable: Bool { return super.deletable || (candy?.deletable ?? false) }
    
    override var asset: Asset? {
        get { return candy?.asset }
        set { }
    }
}
