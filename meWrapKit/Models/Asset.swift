//
//  Asset.swift
//  meWrap
//
//  Created by Sergey Maximenko on 10/26/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit

class Asset: Archive {
    var original: String?
    var large: String?
    var medium: String?
    var small: String?
    var justUploaded = false
    var type: MediaType = .Photo
    
    override class func archivableProperties() -> Set<String> {
        return ["type","original","large","medium","small"]
    }
    
    override var description: String {
        return "asset:\noriginal: \(original)\nlarge: \(large)\nmedium: \(medium)\nsmall: \(small)"
    }
    
    convenience init(json: NSData) throws {
        self.init()
        let data = try NSJSONSerialization.JSONObjectWithData(json, options: NSJSONReadingOptions())
        for property in self.dynamicType.archivableProperties() {
            setValue(data[property], forKey: property)
        }
    }
    
    func JSONValue() -> NSData? {
        var dictionary = Dictionary<String, AnyObject>()
        for property in self.dynamicType.archivableProperties() {
            if let value = valueForKey(property) {
                dictionary[property] = value
            }
        }
        do {
            return try NSJSONSerialization.dataWithJSONObject(dictionary, options: NSJSONWritingOptions())
        } catch {
            return nil
        }
    }
}

class AssetTransformer: NSValueTransformer {
    override class func transformedValueClass() -> AnyClass {
        return NSData.self
    }
    override class func allowsReverseTransformation() -> Bool {
        return true
    }
    override func transformedValue(value: AnyObject?) -> AnyObject? {
        return (value as? Asset)?.JSONValue()
    }
    override func reverseTransformedValue(value: AnyObject?) -> AnyObject? {
        if let data = value as? NSData {
            do {
                return try Asset(json: data)
            } catch {
                return Asset.unarchive(data)
            }
        } else {
            return nil
        }
        
    }
}
