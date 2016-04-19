//
//  Asset.swift
//  meWrap
//
//  Created by Sergey Maximenko on 10/26/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit

func ==(lhs: Asset, rhs: Asset) -> Bool {
    return lhs.original == rhs.original && lhs.large == rhs.large && lhs.medium == rhs.medium && lhs.small == rhs.small
}

class Asset: NSObject, NSCopying {
    var original: String?
    var large: String?
    var medium: String?
    var small: String?
    var type: MediaType = .Photo
    
    override var description: String {
        return "urls \noriginal: \(original)\nlarge: \(large)\nmedium: \(medium)\nsmall: \(small)"
    }
    
    convenience init(json: NSData) {
        self.init()
        if let data = (try? NSJSONSerialization.JSONObjectWithData(json, options: .AllowFragments)) as? [String : AnyObject] {
            type = MediaType(rawValue: Int16((data["type"] as? Int) ?? 0)) ?? .Photo
            original = data["original"] as? String
            large = data["large"] as? String
            medium = data["medium"] as? String
            small = data["small"] as? String
        }
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
        return try? NSJSONSerialization.dataWithJSONObject(dictionary, options: [])
    }
    
    func copyWithZone(zone: NSZone) -> AnyObject {
        let asset = Asset()
        asset.type = type
        asset.original = original
        asset.large = large
        asset.medium = medium
        asset.small = small
        return asset
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
            return Asset(json: data)
        } else {
            return nil
        }
    }
}
