//
//  Chat.swift
//  meWrap
//
//  Created by Sergey Maximenko on 12/9/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit
import PubNub

class Chat: PaginatedList {
    
    let wrap: Wrap
    
    var typingNames: String?
    
    lazy var unreadMessages = [Message]()
    
    lazy var cachedMessageHeights = [Message : CGFloat]()
    
    var messageFont = UIFont.fontNormal()
    
    var nameFont = UIFont.lightFontSmaller()
    
    static var MaxWidth: CGFloat = Constants.screenWidth - LeadingBubbleIndentWithAvatar - 2*MessageHorizontalInset - BubbleIndent
    static var MinWidth: CGFloat = Constants.screenWidth - 2*BubbleIndent - 2*MessageHorizontalInset
    
    static var MessageVerticalInset: CGFloat = 6.0
    static var MessageHorizontalInset: CGFloat = 6.0
    static var MessageWithNameMinimumCellHeight: CGFloat = 40.0
    static var MessageWithoutNameMinimumCellHeight: CGFloat = 24.0
    static var LeadingBubbleIndentWithAvatar: CGFloat = 64.0
    static var BubbleIndent: CGFloat = 16.0
    static var MessageGroupSpacing: CGFloat = 6.0
    static var MessageSpacing: CGFloat = 2.0
    static var NameVerticalInset: CGFloat = 6.0
    
    private var subscription: NotificationSubscription?
    
    required init(wrap: Wrap) {
        self.wrap = wrap
        super.init()
        request = PaginatedRequest.messages(wrap)
        resetMessages()
    }
    
    func resetMessages() {
        entries = wrap.messages.sort({ $0.createdAt < $1.createdAt })
    }
    
    override func sort() {
        entries = entries.sort({ $0.listSortDate() < $1.listSortDate() })
    }
    
    internal override func newerPaginationDate() -> NSDate? {
        return entries.last?.listSortDate()
    }
    
    internal override func olderPaginationDate() -> NSDate? {
        return entries.first?.listSortDate()
    }
    
    func markAsRead() {
        for message in unreadMessages {
            message.markAsUnread(false)
        }
        unreadMessages.removeAll()
    }
    
    override func didChange() {
        unreadMessages.removeAll()
        if let messages = entries as? [Message] {
            var nameStateChanged = false
            for (index, message) in messages.enumerate() {
                
                if message.unread {
                    unreadMessages.append(message)
                }
                
                let previousMessage: Message? = index == 0 ? nil : messages[index - 1]
                
                var containsDate = false
                if let previousMessage = previousMessage {
                    containsDate = !previousMessage.createdAt.isSameDay(message.createdAt)
                } else {
                    containsDate = true
                }
                
                var containsName = false
                var isGroup = false
                
                message.chatMetadata.containsDate = containsDate
                
                if containsDate {
                    containsName = !(message.contributor?.current ?? true)
                    message.chatMetadata.isGroup = true
                } else {
                    if previousMessage?.contributor != message.contributor {
                        containsName = !(message.contributor?.current ?? true)
                        isGroup = true
                    }
                }
                
                message.chatMetadata.isGroup = isGroup
                if message.chatMetadata.containsName != containsName {
                    nameStateChanged = true
                    message.chatMetadata.containsName = containsName
                }
            }
            
            if nameStateChanged {
                cachedMessageHeights.removeAll()
            }
        }
        
        super.didChange()
    }
}

extension Chat: NotificationSubscriptionDelegate {
    
    private func namesOfUsers(users: [User]) -> String? {
        if users.isEmpty {
            return nil
        } else {
            if users.count == 1 {
                return String(format:"formatted_is_typing".ls, users.last?.name ?? "")
            } else if users.count == 2 {
                return String(format:"formatted_and_are_typing".ls, users[0].name ?? "", users[1].name ?? "")
            } else {
                let names = users.prefix(users.count - 1).map({ $0.name ?? "" }).joinWithSeparator(", ")
                return String(format:"formatted_and_are_typing".ls, names, users.last?.name ?? "")
            }
        }
    }
    
    func sendTyping(typing: Bool) {
        let state = [
            "activity" : [
                "type" : UserActivityType.Typing.rawValue,
                "in_progress" : typing
            ]
        ]
        PubNub.sharedInstance.setState(state, forUUID: User.channelName(), onChannel: wrap.uid, withCompletion: nil)
    }
    
    func beginTyping() {
        sendTyping(true)
    }
    
    func endTyping() {
        sendTyping(false)
    }
}

extension Chat: FontPresetting {
    
    func heightOfMessageCell(message: Message) -> CGFloat {
        if let cachedHeight = cachedMessageHeights[message] {
            return cachedHeight
        } else {
            guard let text = message.text else { return 0 }
            let containsName = message.chatMetadata.containsName
            let calculateWight = (message.contributor?.current ?? false) ? Chat.MinWidth : Chat.MaxWidth
            var commentHeight = text.heightWithFont(messageFont, width: calculateWight) ?? 0
            let topInset = containsName ? nameFont.lineHeight + Chat.NameVerticalInset : 0
            let bottomInset = nameFont.lineHeight + Chat.MessageVerticalInset + Chat.MessageSpacing
            commentHeight += topInset + bottomInset
            commentHeight = max(containsName ? Chat.MessageWithNameMinimumCellHeight : Chat.MessageWithoutNameMinimumCellHeight, commentHeight)
            cachedMessageHeights[message] = commentHeight
            return commentHeight
        }
    }
    
    func presetterDidChangeContentSizeCategory(presetter: FontPresetter) {
        cachedMessageHeights.removeAll()
        messageFont = UIFont.fontNormal()
        nameFont = UIFont.lightFontSmaller()
        super.didChange()
    }
}
