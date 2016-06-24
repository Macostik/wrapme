//
//  Asset.swift
//  meWrap
//
//  Created by Sergey Maximenko on 10/26/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit

func ==(lhs: Asset, rhs: Asset) -> Bool {
    return lhs.type == rhs.type && lhs.original == rhs.original && lhs.large == rhs.large && lhs.medium == rhs.medium && lhs.small == rhs.small && lhs.lowDef == rhs.lowDef
}

func !=(lhs: Asset, rhs: Asset) -> Bool {
    return !(lhs == rhs)
}

func !=(lhs: Asset?, rhs: Asset?) -> Bool {
    return !(lhs == rhs)
}

func ==(lhs: Asset?, rhs: Asset?) -> Bool {
    if let lhs = lhs {
        if let rhs = rhs {
            return lhs == rhs
        } else {
            return false
        }
    } else if let rhs = rhs {
        if let lhs = lhs {
            return lhs == rhs
        } else {
            return false
        }
    } else {
        return true
    }
}

class Asset: NSObject, NSCopying {
    var original: String?
    var large: String?
    var medium: String?
    var small: String?
    var lowDef: String?
    var type: MediaType = .Photo
    
    override var description: String {
        return "type: \(type.rawValue)\noriginal: \(original)\nlarge: \(large)\nmedium: \(medium)\nsmall: \(lowDef)\nsmall: \(lowDef)"
    }
    
    convenience init(json: NSData) {
        self.init()
        if let data = (try? NSJSONSerialization.JSONObjectWithData(json, options: .AllowFragments)) as? [String : AnyObject] {
            type = MediaType(rawValue: Int16((data["type"] as? Int) ?? 0)) ?? .Photo
            original = data["original"] as? String
            large = data["large"] as? String
            medium = data["medium"] as? String
            small = data["small"] as? String
            lowDef = data["lowDef"] as? String
        }
    }
    
    func JSONValue() -> NSData? {
        let dictionary = ["type": Int(type.rawValue),
                          "original": original ?? "",
                          "large": large ?? "",
                          "medium": medium ?? "",
                          "small": small ?? "",
                          "lowDef": lowDef ?? ""]
        return try? NSJSONSerialization.dataWithJSONObject(dictionary, options: [])
    }
    
    func copyWithZone(zone: NSZone) -> AnyObject {
        let asset = Asset()
        asset.type = type
        asset.original = original
        asset.large = large
        asset.medium = medium
        asset.small = small
        asset.lowDef = lowDef
        return asset
    }
    
    func contentType() -> String {
        if type == .Video {
            return "video/mp4"
        } else {
            return "image/jpeg"
        }
    }
    
    func videoURL() -> NSURL? {
        guard let original = original else { return nil }
        if original.isExistingFilePath {
            return original.fileURL
        } else {
            let path = ImageCache.defaultCache.getPath(ImageCache.uidFromURL(original, ext: "mp4"))
            if path.isExistingFilePath {
                return path.fileURL
            } else {
                return original.URL
            }
        }
    }
    
    func smallVideoURL() -> NSURL? {
        if let original = original where original.isExistingFilePath {
            return original.fileURL
        } else if let lowDef = lowDef {
            return lowDef.URL
        } else {
            return videoURL()
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
            return Asset(json: data)
        } else {
            return nil
        }
    }
}
