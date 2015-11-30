//
//  PlainEntry.swift
//  meWrap
//
//  Created by Sergey Maximenko on 11/29/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import Foundation

class ExtensionEntry: ExtensionMessage {
    var uid = ""
    override func fromDictionary(dictionary: [String : AnyObject]) {
        super.fromDictionary(dictionary)
        uid = (dictionary["uid"] as? String) ?? ""
    }
    override func toDictionary() -> [String : AnyObject] {
        var dictionary = super.toDictionary()
        dictionary["uid"] = uid
        return dictionary
    }
}

class ExtensionUser: ExtensionEntry {
    var name: String?
    var avatar: String?
    override func fromDictionary(dictionary: [String : AnyObject]) {
        super.fromDictionary(dictionary)
        name = dictionary["name"] as? String
        avatar = dictionary["avatar"] as? String
    }
    override func toDictionary() -> [String : AnyObject] {
        var dictionary = super.toDictionary()
        dictionary["name"] = name ?? ""
        dictionary["avatar"] = avatar ?? ""
        return dictionary
    }
}

class ExtensionContribution: ExtensionEntry {
    var createdAt: NSDate?
    var updatedAt: NSDate?
    var contributor: ExtensionUser?
    override func fromDictionary(dictionary: [String : AnyObject]) {
        super.fromDictionary(dictionary)
        createdAt = dictionary.dateForKey("createdAt")
        updatedAt = dictionary.dateForKey("updatedAt")
        if let contributor = dictionary["contributor"] as? [String : AnyObject] {
            self.contributor = ExtensionUser.fromDictionary(contributor)
        }
    }
    override func toDictionary() -> [String : AnyObject] {
        var dictionary = super.toDictionary()
        dictionary["createdAt"] = createdAt?.timestamp ?? 0
        dictionary["updatedAt"] = updatedAt?.timestamp ?? 0
        dictionary["contributor"] = contributor?.toDictionary() ?? []
        return dictionary
    }
}

class ExtensionWrap: ExtensionContribution {
    var name: String?
    override func fromDictionary(dictionary: [String : AnyObject]) {
        super.fromDictionary(dictionary)
        name = dictionary["name"] as? String
    }
    override func toDictionary() -> [String : AnyObject] {
        var dictionary = super.toDictionary()
        dictionary["name"] = name ?? ""
        return dictionary
    }
}

class ExtensionCandy: ExtensionContribution {
    var comments = [ExtensionComment]()
    var asset: String?
    var wrap: ExtensionWrap?
    var type: MediaType = .Photo
    override func fromDictionary(dictionary: [String : AnyObject]) {
        super.fromDictionary(dictionary)
        if let comments = dictionary["comments"] as? [[String : AnyObject]] {
            self.comments = comments.map({ (dictionary) -> ExtensionComment in
                return ExtensionComment.fromDictionary(dictionary)
            })
        }
        asset = dictionary["asset"] as? String
        if let wrap = dictionary["wrap"] as? [String : AnyObject] {
            self.wrap = ExtensionWrap.fromDictionary(wrap)
        }
        if let type = dictionary["type"] as? Int, let mediaType = MediaType(rawValue: Int16(type)) {
            self.type = mediaType
        }
    }
    override func toDictionary() -> [String : AnyObject] {
        var dictionary = super.toDictionary()
        dictionary["comments"] = comments.map({ (comment) -> [String : AnyObject] in
            return comment.toDictionary()
        })
        dictionary["asset"] = asset ?? ""
        dictionary["wrap"] = wrap?.toDictionary() ?? []
        dictionary["type"] = Int(type.rawValue)
        return dictionary
    }
    var isVideo: Bool {
        return type == .Video
    }
}

class ExtensionComment: ExtensionContribution {
    var text: String?
    override func fromDictionary(dictionary: [String : AnyObject]) {
        super.fromDictionary(dictionary)
        text = dictionary["text"] as? String
    }
    override func toDictionary() -> [String : AnyObject] {
        var dictionary = super.toDictionary()
        dictionary["text"] = text ?? ""
        return dictionary
    }
}

class ExtensionUpdate: ExtensionEntry {
    var type: String?
    var candy: ExtensionCandy?
    var comment: ExtensionComment?
    override func fromDictionary(dictionary: [String : AnyObject]) {
        super.fromDictionary(dictionary)
        type = dictionary["type"] as? String
        if let candy = dictionary["candy"] as? [String : AnyObject] {
            self.candy = ExtensionCandy.fromDictionary(candy)
        }
    }
    override func toDictionary() -> [String : AnyObject] {
        var dictionary = super.toDictionary()
        dictionary["type"] = type ?? ""
        dictionary["candy"] = candy?.toDictionary() ?? []
        dictionary["comment"] = comment?.toDictionary() ?? []
        return dictionary
    }
}