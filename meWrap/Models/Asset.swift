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
        do {
            if let data = try NSJSONSerialization.JSONObjectWithData(json, options: .AllowFragments) as? [String : AnyObject] {
                type = MediaType(rawValue: Int16((data["type"] as? Int) ?? 0)) ?? .Photo
                original = data["original"] as? String
                large = data["large"] as? String
                medium = data["medium"] as? String
                small = data["small"] as? String
            }
        } catch {}
    }
    
    func JSONValue() -> NSData? {
        var dictionary = [String : AnyObject]()
        dictionary["type"] = Int(type.rawValue)
        if let original = original {
            dictionary["original"] = original
        }
        if let large = large {
            dictionary["large"] = large
        }
        if let medium = medium {
            dictionary["medium"] = medium
        }
        if let small = small {
            dictionary["small"] = small
        }
        do {
            return try NSJSONSerialization.dataWithJSONObject(dictionary, options: [])
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
