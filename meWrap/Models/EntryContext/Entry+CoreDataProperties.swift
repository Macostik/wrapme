//
//  Entry+CoreDataProperties.swift
//  
//
//  Created by Sergey Maximenko on 10/26/15.
//
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Entry {

    @NSManaged var createdAt: NSDate
    @NSManaged var uid: String
    @NSManaged var unread: Bool
    @NSManaged var updatedAt: NSDate
    @NSManaged var locuid: String?

}

extension User {
    
    @NSManaged var current: Bool
    @NSManaged var firstTimeUse: Bool
    @NSManaged var name: String?
    @NSManaged var contributions: NSSet?
    @NSManaged var devices: NSSet?
    @NSManaged var editings: NSSet?
    @NSManaged var wraps: NSSet?
    @NSManaged var avatar: Asset?
    
}

extension Device {
    
    @NSManaged var activated: Bool
    @NSManaged var invitedAt: NSDate
    @NSManaged var invitedBy: String?
    @NSManaged var name: String?
    @NSManaged var phone: String?
    @NSManaged var owner: User?
    
}

extension Uploading {
    
    @NSManaged var type: Int16
    @NSManaged var contribution: Contribution?
    
}

extension Contribution {
    
    @NSManaged var editedAt: NSDate
    @NSManaged var contributor: User?
    @NSManaged var editor: User?
    @NSManaged var uploading: Uploading?
    @NSManaged var asset: Asset?
    
}

extension Wrap {
    
    @NSManaged var isCandyNotifiable: Bool
    @NSManaged var isChatNotifiable: Bool
    @NSManaged var isPublic: Bool
    @NSManaged var isRestrictedInvite: Bool
    @NSManaged var name: String?
    @NSManaged var candies: NSSet?
    @NSManaged var contributors: NSSet?
    @NSManaged var messages: NSSet?
    
}

extension Candy {
    
    @NSManaged var commentCount: Int16
    @NSManaged var type: Int16
    @NSManaged var comments: NSSet?
    @NSManaged var wrap: Wrap?
    
}

extension Comment {
    
    @NSManaged var text: String?
    @NSManaged var candy: Candy?
    
}

extension Message {
    
    @NSManaged var text: String?
    @NSManaged var wrap: Wrap?
    
}
