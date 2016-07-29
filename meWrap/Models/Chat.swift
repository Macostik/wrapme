//
//  Chat.swift
//  meWrap
//
//  Created by Sergey Maximenko on 12/9/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit
import PubNub

class Chat: PaginatedList<Message> {
    
    let wrap: Wrap
        
    var unreadMessages = [Message]()
    
    var messageFont = UIFont.fontNormal()
    
    var nameFont = UIFont.lightFontSmall()
    
    static let MaxWidth: CGFloat = Constants.screenWidth - 2*LeadingBubbleIndentWithAvatar - 2*MessageHorizontalInset
    static let MinWidth: CGFloat = Constants.screenWidth - LeadingBubbleIndentWithAvatar - 2*MessageHorizontalInset - BubbleIndent
    
    static let MessageVerticalInset: CGFloat = 12.0
    static let MessageHorizontalInset: CGFloat = 16.0
    static let MessageWithNameMinimumCellHeight: CGFloat = 40.0
    static let MessageWithoutNameMinimumCellHeight: CGFloat = 24.0
    static let LeadingBubbleIndentWithAvatar: CGFloat = 64.0
    static let BubbleIndent: CGFloat = 16.0
    static let MessageGroupSpacing: CGFloat = 8.0
    static let MessageSpacing: CGFloat = 2.0
    static let NameVerticalInset: CGFloat = 12 + 8
    
    required init(wrap: Wrap) {
        self.wrap = wrap
        super.init()
        newerThen = { $0.last?.createdAt }
        olderThen = { $0.first?.createdAt }
        request = API.messages(wrap)
        sorter = { $0.createdAt < $1.createdAt }
        entries = wrap.messages.sort(sorter)
        FontPresetter.presetter.subscribe(self) { [unowned self] (value) in
            for message in wrap.messages {
                message.chatMetadata.height = nil
            }
            self.messageFont = UIFont.fontNormal()
            self.nameFont = UIFont.lightFontSmall()
            self.didChangeNotifier.notify(self)
        }
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
                isGroup = true
            } else {
                if previousMessage?.contributor != message.contributor {
                    containsName = !(message.contributor?.current ?? true)
                    isGroup = true
                }
            }
            
            previousMessage?.chatMetadata.isGroupEnd = isGroup
            message.chatMetadata.isGroup = isGroup
            if index == messages.count - 1 {
                message.chatMetadata.isGroupEnd = true
            }
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
            let calculateWight = (message.contributor?.current ?? false) ? Chat.MinWidth : Chat.MaxWidth
            let containsName = message.chatMetadata.containsName
            let topInset = containsName ? nameFont.lineHeight + Chat.NameVerticalInset : Chat.MessageVerticalInset
            let commentHeight = text.heightWithFont(messageFont, width: calculateWight) + topInset + Chat.MessageVerticalInset
            message.chatMetadata.height = commentHeight
            return commentHeight
        }
    }
}
