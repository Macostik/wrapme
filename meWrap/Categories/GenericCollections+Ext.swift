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
        return (index >= 0 && index < count) ? self[index] : nil
    }
}

extension CollectionType {
    
    func all(@noescape enumerator: Generator.Element -> Void) {
        for element in self {
            enumerator(element)
        }
    }
    
    subscript (@noescape includeElement: Generator.Element -> Bool) -> Generator.Element? {
        for element in self where includeElement(element) == true {
            return element
        }
        return nil
    }
}