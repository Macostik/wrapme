//
//  Chat.swift
//  meWrap
//
//  Created by Sergey Maximenko on 12/9/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit
import PubNub

class Chat: PaginatedList<Message>, FontPresetting {
    
    let wrap: Wrap
        
    lazy var unreadMessages = [Message]()
    
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
        
    required init(wrap: Wrap) {
        self.wrap = wrap
        super.init()
        newerThen = { $0.last?.createdAt }
        olderThen = { $0.first?.createdAt }
        request = API.messages(wrap)
        sorter = { $0.createdAt < $1.createdAt }
        addEntries(wrap.messages)
        FontPresetter.defaultPresetter.addReceiver(self)
    }
    
    func resetMessages() {
        entries = wrap.messages.sort({ $0.createdAt < $1.createdAt })
        didChange()
    }
    
    func markAsRead() {
        for message in unreadMessages {
            message.markAsUnread(false)
        }
        unreadMessages.removeAll()
    }
    
    override func didChange() {
        unreadMessages.removeAll()
        let messages = entries
        for (index, message) in messages.enumerate() {
            
            if message.unread {
                unreadMessages.append(message)
            }
            
            let previousMessage: Message? = index == 0 ? nil : messages[index - 1]
            
            var containsDate = true
            if let previousMessage = previousMessage {
                containsDate = !previousMessage.createdAt.isSameDay(message.createdAt)
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
                message.chatMetadata.height = nil
                message.chatMetadata.containsName = containsName
            }
        }
        super.didChange()
    }
    
    func heightOfMessageCell(message: Message) -> CGFloat {
        if let cachedHeight = message.chatMetadata.height {
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
            message.chatMetadata.height = commentHeight
            return commentHeight
        }
    }
    
    func presetterDidChangeContentSizeCategory(presetter: FontPresetter) {
        for message in wrap.messages {
            message.chatMetadata.height = nil
        }
        messageFont = UIFont.fontNormal()
        nameFont = UIFont.lightFontSmaller()
        super.didChange()
    }
}
