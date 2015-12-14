//
//  Chat.swift
//  meWrap
//
//  Created by Sergey Maximenko on 12/9/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit
import PubNub

@objc protocol ChatNotifying: PaginatedListNotifying {
    optional func chat(chat: Chat, didBeginTyping user: User)
    optional func chat(chat: Chat, didEndTyping user: User)
}

class Chat: PaginatedList {
    
    let wrap: Wrap
    
    var typingNames: String?
    
    lazy var unreadMessages = [Message]()
    lazy var readMessages = [Message]()
    lazy var typingUsers = [User]()
    
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
    static var NameVerticalInset: CGFloat = 4.0
    
    private var subscription: NotificationSubscription?
    
    required init(wrap: Wrap) {
        self.wrap = wrap
        super.init()
        request = PaginatedRequest.messages(wrap)
        resetMessages()
        run_after_asap { [weak self] () -> Void in
            let subscription = NotificationSubscription(name: wrap.uid, isGroup: false, observePresence: true)
            self?.subscription = subscription
            subscription.delegate = self
            subscription.hereNow({ (uuids) -> Void in
                guard let uuids = uuids else {
                    return
                }
                for uuid in uuids {
                    guard let user = PubNub.userFromUUID(uuid["uuid"] as? String) where !user.current else {
                        continue
                    }
                    if let typing = uuid["state"]?["typing"] as? Bool where typing == true {
                        self?.didBeginTyping(user)
                    }
                }
            })
        }
    }
    
    func resetMessages() {
        if let messages = wrap.messages as? Set<Message> {
            entries = messages.sort({ $0.createdAt < $1.createdAt })
        }
    }
    
    override func sort() {
        self.entries = self.entries.sort({ $0.listSortDate() < $1.listSortDate() })
    }
    
    override func add(entry: ListEntry) {
        if let user = (entry as? Message)?.contributor, let index = typingUsers.indexOf(user) {
            typingUsers.removeAtIndex(index)
        }
        super.add(entry)
    }
    
    internal override func newerPaginationDate() -> NSDate? {
        return entries.last?.listSortDate()
    }
    
    internal override func olderPaginationDate() -> NSDate? {
        return entries.first?.listSortDate()
    }
    
    func markAsRead() {
        for message in readMessages {
            message.markAsUnread(false)
            if let index = unreadMessages.indexOf(message) {
                unreadMessages.removeAtIndex(index)
            }
        }
    }
    
    func addReadMessage(message: Message) {
        readMessages.append(message)
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
    
    private func addTypingUser(user: User) {
        if !typingUsers.contains(user) {
            typingUsers.append(user)
            typingNames = namesOfUsers(typingUsers)
        }
    }
    
    private func removeTypingUser(user: User) {
        if let index = typingUsers.indexOf(user) {
            typingUsers.removeAtIndex(index)
            typingNames = namesOfUsers(typingUsers)
        }
    }
    
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
    
    private func didBeginTyping(user: User) {
        user.fetchIfNeeded({ [weak self] (_) -> Void in
            guard let chat = self else {
                return
            }
            if let contributors = chat.wrap.contributors where !contributors.containsObject(user) {
                chat.wrap.mutableContributors.addObject(user)
            }
            chat.addTypingUser(user)
            chat.notify({ (receiver) -> Void in
                receiver.chat?(chat, didBeginTyping: user)
            })
            }) { (error) -> Void in
                error?.showNonNetworkError()
        }
        
        notify({ (receiver) -> Void in
            receiver.chat?(self, didBeginTyping: user)
        })
    }
    
    private func didEndTyping(user: User) {
        removeTypingUser(user)
        notify({ (receiver) -> Void in
            receiver.chat?(self, didEndTyping: user)
        })
    }
    
    func sendTyping(typing: Bool) {
        subscription?.changeState(["typing" : typing])
    }
    
    func beginTyping() {
        sendTyping(true)
    }
    
    func endTyping() {
        sendTyping(false)
    }
    
    private func handleClientState(state: [NSObject:AnyObject], user: User) {
        if let typing = state["typing"] as? Bool {
            if typing {
                didBeginTyping(user)
            } else {
                didEndTyping(user)
            }
        }
    }
    
    func notificationSubscription(subscription: NotificationSubscription, didReceivePresenceEvent event: PNPresenceEventResult) {
        guard let user = PubNub.userFromUUID(event.data?.presence?.uuid) where !user.current else {
            return
        }
        
        switch event.data.presenceEvent {
        case "state-change":
            handleClientState(event.data.presence.state, user: user)
            break
        case "leave", "timeout" where typingUsers.contains(user):
            didEndTyping(user)
            break
        default: break
        }
    }
}

extension Chat: FontPresetting {
    
    func heightOfMessageCell(message: Message) -> CGFloat {
        if let cachedHeight = cachedMessageHeights[message] {
            return cachedHeight
        } else {
            guard let messageFont = messageFont, let nameFont = nameFont, let text = message.text else {
                return 0
            }
            let containsName = message.chatMetadata.containsName
            let calculateWight = (message.contributor?.current ?? false) ? Chat.MaxWidth : Chat.MinWidth
            var commentHeight = text.heightWithFont(messageFont, width: calculateWight) ?? 0
            let topInset = containsName ? nameFont.lineHeight + Chat.NameVerticalInset : 0
            let bottomInset = nameFont.lineHeight + Chat.MessageVerticalInset
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
