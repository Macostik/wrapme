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
    optional func chatDidChangeMessagesWithName(chat: Chat)
}

class Chat: PaginatedList {
    
    var wrap: Wrap
    
    var typingNames: String?
    
    var unreadMessages = [Message]()
    var readMessages = [Message]()
    var messagesWithDay = Set<Message>()
    var messagesWithName = Set<Message>()
    var typingUsers = [User]()
    var groupMessages = [Message]()
    
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
                    guard let user = User.entry(uuid["uuid"] as? String) where !user.current else {
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
            entries = messages.sort({ $0.createdAt > $1.createdAt })
        }
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
            message.markAsRead()
            if let index = unreadMessages.indexOf(message) {
                unreadMessages.removeAtIndex(index)
            }
        }
    }
    
    func addReadMessage(message: Message) {
        readMessages.append(message)
    }
    
    override func didChange() {
        var messagesWithName = Set<Message>()
        unreadMessages.removeAll()
        messagesWithDay.removeAll()
        groupMessages.removeAll()
        if let messages = entries as? [Message] {
            for (index, message) in messages.enumerate() {
                
                if message.unread {
                    unreadMessages.append(message)
                }
                
                let previousMessage: Message? = index == 0 ? nil : messages[index - 1]
                
                var withDay = false
                if let previousMessage = previousMessage {
                    withDay = !previousMessage.createdAt.isSameDay(message.createdAt)
                } else {
                    withDay = true
                }
                if withDay {
                    messagesWithDay.insert(message)
                    if !(message.contributor?.current ?? true) {
                        messagesWithName.insert(message)
                    }
                    groupMessages.append(message)
                    continue
                }
                
                if previousMessage?.contributor != message.contributor {
                    if !(message.contributor?.current ?? true) {
                        messagesWithName.insert(message)
                    }
                    groupMessages.append(message)
                }
            }
            
            if self.messagesWithName != messagesWithName {
                self.messagesWithName = messagesWithName;
                notify({ (receiver) -> Void in
                    receiver.chatDidChangeMessagesWithName?(self)
                })
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
        guard let user = User.entry(event.data.presence.uuid) where !user.current else {
            return
        }
        if event.data.presenceEvent == "state-change" {
            handleClientState(event.data.presence.state, user: user)
        } else if event.data.presenceEvent == "leave" || event.data.presenceEvent == "timeout" {
            if typingUsers.contains(user) {
                didEndTyping(user)
            }
        }
    }
}
