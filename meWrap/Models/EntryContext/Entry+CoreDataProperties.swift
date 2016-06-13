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
    @NSManaged var contributions: Set<Contribution>
    @NSManaged var devices: Set<Device>
    @NSManaged var editings: Set<Contribution>
    @NSManaged var wraps: Set<Wrap>
    @NSManaged var avatar: Asset?
    @NSManaged var invitedAt: NSDate
    @NSManaged var invitees: Set<Invitee>?
}

extension Device {
    
    @NSManaged var activated: Bool
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
    @NSManaged var isCommentNotifiable: Bool
    @NSManaged var isChatNotifiable: Bool
    @NSManaged var isRestrictedInvite: Bool
    @NSManaged var name: String?
    @NSManaged var candies: Set<Candy>
    @NSManaged var contributors: Set<User>
    @NSManaged var messages: Set<Message>
    @NSManaged var candiesPaginationDate: NSDate?
    @NSManaged var invitees: Set<Invitee>
    @NSManaged var invitationMessage: String?
    
}

extension Invitee {
    
    @NSManaged var name: String?
    @NSManaged var phone: String?
    @NSManaged var user: User?
    @NSManaged var wrap: Wrap?
    
}

extension Candy {
    
    @NSManaged var commentCount: Int16
    @NSManaged var type: Int16
    @NSManaged var comments: Set<Comment>
    @NSManaged var wrap: Wrap?
    @NSManaged var updateUnread: Bool
    
}

extension Comment {
    
    @NSManaged var text: String?
    @NSManaged var candy: Candy?
    @NSManaged var type: Int16
    
}

extension Message {
    
    @NSManaged var text: String?
    @NSManaged var wrap: Wrap?
    
}
