//
//  GenericCollections+Ext.swift
//  meWrap
//
//  Created by Sergey Maximenko on 12/9/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import Foundation

extension Array {
    subscript (safe index: Int) -> Element? {
        return indices ~= index ? self[index] : nil
    }
    
    subscript (@noescape includeElement: Element -> Bool) -> Element? {
        for element in self where includeElement(element) == true {
            return element
        }
        return nil
    }
}