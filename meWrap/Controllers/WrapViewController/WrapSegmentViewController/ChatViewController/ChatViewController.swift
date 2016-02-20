//
//  ChatViewController.swift
//  meWrap
//
//  Created by Sergey Maximenko on 2/18/16.
//  Copyright © 2016 Ravenpod. All rights reserved.
//

import UIKit

final class ChatViewController: WrapSegmentViewController {
    
    @IBOutlet weak var streamView: StreamView!
    @IBOutlet weak var composeBar: ComposeBar!
    
    lazy var chat: Chat = Chat(wrap: self.wrap)
    
    private var messageMetrics = StreamMetrics(identifier: "MessageCell").change({ $0.selectable = false })
    private var messageWithNameMetrics = StreamMetrics(identifier: "MessageWithNameCell").change({ $0.selectable = false })
    private var myMessageMetrics = StreamMetrics(identifier: "MyMessageCell").change({ $0.selectable = false })
    private var dateMetrics = StreamMetrics(loader: LayoutStreamLoader<MessageDateView>(), size: 33).change({ $0.selectable = false })
    
    private lazy var placeholderMetrics: StreamMetrics = StreamMetrics(loader: PlaceholderView.chatPlaceholderLoader()).change { [unowned self] metrics -> Void in
        metrics.prepareAppearing = { item, view in
            (view as! PlaceholderView).textLabel.text = String(format:"no_chat_message".ls, self.wrap?.name ?? "")
        }
        metrics.selectable = false
    }
    
    private var unreadMessagesMetrics = StreamMetrics(identifier: "WLUnreadMessagesView", size: 46).change({ $0.selectable = false })
    
    private var dragged = false
    
    private var runQueue = RunQueue(limit: 1)
    
    var showKeyboard = false {
        willSet {
            if isViewLoaded() && newValue {
                composeBar.becomeFirstResponder()
            }
        }
    }
    
    deinit {
        streamView.delegate = nil
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func applicationDidBecomeActive() {
        streamView.unlock()
        chat.resetMessages()
        scrollToLastUnreadMessage()
        NSNotificationCenter.defaultCenter().removeObserver(self, name:UIApplicationDidBecomeActiveNotification, object:nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector:"applicationWillResignActive", name:UIApplicationWillResignActiveNotification, object:nil)
    }
    
    func applicationWillResignActive() {
        streamView.lock()
        NSNotificationCenter.defaultCenter().removeObserver(self, name:UIApplicationWillResignActiveNotification, object:nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector:"applicationDidBecomeActive", name:UIApplicationDidBecomeActiveNotification, object:nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateInsets()
        
        if wrap == nil {
            Dispatch.mainQueue.after(0.5) { self.navigationController?.popViewControllerAnimated(false) }
            return
        }
        
        messageWithNameMetrics.sizeAt = { [unowned self] item in
            return self.chat.heightOfMessageCell((item.entry as! Message))
        }
        messageMetrics.sizeAt = messageWithNameMetrics.sizeAt
        myMessageMetrics.sizeAt = messageWithNameMetrics.sizeAt
        
        messageWithNameMetrics.insetsAt = { item in
            let message = item.entry as! Message
            return CGRectMake(0, message.chatMetadata.containsDate ? 0 : message.chatMetadata.isGroup ? Chat.MessageGroupSpacing : Chat.MessageSpacing, 0, 0);
        };
        messageMetrics.insetsAt = messageWithNameMetrics.insetsAt
        myMessageMetrics.insetsAt = messageWithNameMetrics.insetsAt
        
        chat.addReceiver(self)
        
        if !wrap.messages.isEmpty {
            chat.newer(nil, failure: { $0?.showNonNetworkError() })
        }
        
        Message.notifier().addReceiver(self)
        FontPresetter.defaultPresetter.addReceiver(self)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        streamView.unlock()
        chat.sort()
        scrollToLastUnreadMessage()
        NSNotificationCenter.defaultCenter().addObserver(self, selector:"applicationWillResignActive", name:UIApplicationWillResignActiveNotification, object:nil)
        if showKeyboard {
            composeBar.becomeFirstResponder()
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        streamView.lock()
        chat.markAsRead()
        updateBadge()
        NSNotificationCenter.defaultCenter().removeObserver(self, name:UIApplicationWillResignActiveNotification, object:nil)
    }
    
    func updateBadge() {
        badge?.value = chat.unreadMessages.count
    }
    
    func scrollToLastUnreadMessage() {
        streamView.scrollToItemPassingTest({ $0.metrics == unreadMessagesMetrics }, animated:false)
    }
    
    func updateInsets() {
        streamView.contentInset.bottom = composeBar.height + Keyboard.keyboard.height + Chat.BubbleIndent
        streamView.scrollIndicatorInsets = streamView.contentInset
    }
    
    var typing = false {
        didSet {
            if typing != oldValue {
                enqueueSelector("sendTypingStateChange", delay: 1)
            }
        }
    }
    
    func sendTypingStateChange() {
        chat.sendTyping(typing)
    }
    
    override func keyboardWillShow(keyboard: Keyboard) {
        super.keyboardWillShow(keyboard)
        if streamView.contentInset.bottom > composeBar.height + Chat.BubbleIndent {
            return
        }
        keyboard.performAnimation { streamView.transform = CGAffineTransformMakeTranslation(0, -keyboard.height) }
    }
    
    override func keyboardDidShow(keyboard: Keyboard) {
        super.keyboardDidShow(keyboard)
        UIView.performWithoutAnimation {
            self.streamView.transform = CGAffineTransformIdentity
            self.updateInsets()
            self.streamView.contentOffset = CGPointMake(0, min(self.streamView.maximumContentOffset.y, self.streamView.contentOffset.y + keyboard.height))
        }
    }
    
    override func keyboardWillHide(keyboard: Keyboard) {
        super.keyboardWillHide(keyboard)
        UIView.performWithoutAnimation {
            let height = max(0, self.streamView.contentOffset.y - keyboard.height)
            self.streamView.transform = CGAffineTransformMakeTranslation(0, height - self.streamView.contentOffset.y)
            self.streamView.trySetContentOffset(CGPointMake(0, height))
        }
        keyboard.performAnimation { streamView.transform = CGAffineTransformIdentity }
    }
    
    override func keyboardDidHide(keyboard: Keyboard) {
        super.keyboardDidHide(keyboard)
        UIView.performWithoutAnimation { self.updateInsets() }
    }
    
    func insertMessage(message: Message) {
        if streamView.locks > 0 {
            chat.add(message)
            return
        }
        
        runQueue.run { [weak self] (finish) -> Void in
            
            guard let _self = self else {
                finish()
                return
            }
            
            let streamView = _self.streamView
            
            if _self.chat.entries.contains({ $0 === message }) {
                finish()
            } else {
                _self.chat.add(message)
                let offset = streamView.contentOffset
                let maximumOffset = streamView.maximumContentOffset
                if !streamView.scrollable || offset.y < maximumOffset.y {
                    finish()
                } else {
                    if streamView.height/2 < _self.chat.heightOfMessageCell(message) && _self.chat.unreadMessages.count == 1 {
                        _self.scrollToLastUnreadMessage()
                    } else {
                        streamView.reload()
                        streamView.contentOffset = CGPointOffset(streamView.maximumContentOffset, 0, -_self.chat.heightOfMessageCell(message))
                        streamView.setMaximumContentOffsetAnimated(true)
                    }
                    Dispatch.mainQueue.after(0.5, block:finish)
                }
            }
        }
    }
    
    override func back(sender: UIButton) {
        composeBar.resignFirstResponder()
        self.typing = false
        if wrap.valid {
            navigationController?.popViewControllerAnimated(false)
        } else {
            navigationController?.popToRootViewControllerAnimated(false)
        }
    }
}

extension ChatViewController: ChatNotifying {
    
    func listChanged(list: List) {
        streamView.reload()
    }
    
    func chat(chat: Chat, didBeginTyping user: User) {
        
    }
    
    func chat(chat: Chat, didEndTyping user: User) {
        
    }
}

extension ChatViewController: EntryNotifying {
    
    func notifier(notifier: EntryNotifier, didAddEntry entry: Entry) {
        insertMessage(entry as! Message)
    }
    
    func notifier(notifier: EntryNotifier, didUpdateEntry entry: Entry, event: EntryUpdateEvent) {
        streamView.reload()
    }
    
    func notifier(notifier: EntryNotifier, willDeleteEntry entry: Entry) {
        chat.remove(entry)
        if entry.unread {
            updateBadge()
        }
    }
    
    func notifier(notifier: EntryNotifier, shouldNotifyOnEntry entry: Entry) -> Bool {
        return wrap == entry.container
    }
}

extension ChatViewController: ComposeBarDelegate {
    
    private func sendMessageWithText(text: String) {
        if wrap.valid {
            streamView.contentOffset = streamView.maximumContentOffset
            wrap.uploadMessage(text)
            SoundPlayer.player.play(.s04)
            chat.markAsRead()
        } else {
            navigationController?.popToRootViewControllerAnimated(false)
        }
    }
    
    func composeBar(composeBar: ComposeBar, didFinishWithText text: String) {
        self.typing = false
        sendMessageWithText(text)
    }
    
    func composeBarDidShouldResignOnFinish(composeBar: ComposeBar) -> Bool {
        return false
    }
    
    func composeBarDidChangeText(composeBar: ComposeBar) {
        typing = composeBar.text?.isEmpty == false
    }
    
    func composeBarDidChangeHeight(composeBar: ComposeBar) {
        updateInsets()
        streamView.setContentOffset(streamView.maximumContentOffset, animated:true)
    }
}

extension ChatViewController: StreamViewDelegate {
    
    private func appendItemsIfNeededWithTargetContentOffset(targetContentOffset: CGPoint) {
        let sv = self.streamView
        let reachedRequiredOffset = (targetContentOffset.y - sv.minimumContentOffset.y) < sv.fittingContentHeight
        if reachedRequiredOffset && Network.sharedNetwork.reachable && !chat.completed {
            if wrap != nil {
                chat.older(nil, failure: { $0?.showNonNetworkError() })
            }
        }
    }
    
    func streamView(streamView: StreamView, numberOfItemsInSection section: Int) -> Int {
        updateBadge()
        return chat.entries.count
    }
    
    func streamView(streamView: StreamView, entryBlockForItem item: StreamItem) -> (StreamItem -> AnyObject?)? {
        return { [unowned self] item in
            return self.chat.entries[safe: item.position.index]
        }
    }
    
    func streamView(streamView: StreamView, metricsAt position: StreamPosition) -> [StreamMetrics] {
        var metrics = [StreamMetrics]()
        guard let message = chat.entries[safe: position.index] as? Message else { return metrics }
        if chat.unreadMessages.first == message {
            metrics.append(unreadMessagesMetrics)
        }
        if message.chatMetadata.containsDate {
            metrics.append(dateMetrics)
        }
        if message.contributor?.current == true {
            metrics.append(myMessageMetrics)
        } else if message.chatMetadata.containsName {
            metrics.append(messageWithNameMetrics)
        } else {
            metrics.append(messageMetrics)
        }
        return metrics
    }
    
    func streamViewDidChangeContentSize(streamView: StreamView, oldContentSize: CGSize) {
        if streamView.scrollable {
            if dragged {
                let unreadContentOffset = chat.unreadMessages.count == 0 ? unreadMessagesMetrics.size : 0
                streamView.contentOffset.y += streamView.contentSize.height - oldContentSize.height + unreadContentOffset
            } else {
                streamView.contentOffset = streamView.maximumContentOffset
            }
        }
        appendItemsIfNeededWithTargetContentOffset(streamView.contentOffset)
    }
    
    func streamViewPlaceholderMetrics(streamView: StreamView) -> StreamMetrics? {
        return placeholderMetrics
    }
    
    func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        dragged = true
    }
    
    func scrollViewWillEndDragging(scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        appendItemsIfNeededWithTargetContentOffset(targetContentOffset.memory)
    }
}
