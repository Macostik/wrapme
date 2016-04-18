//
//  ChatViewController.swift
//  meWrap
//
//  Created by Sergey Maximenko on 2/18/16.
//  Copyright © 2016 Ravenpod. All rights reserved.
//

import UIKit

final class ChatViewController: WrapSegmentViewController {
    
    weak var badge: BadgeLabel?
    
    @IBOutlet weak var streamView: StreamView!
    @IBOutlet weak var composeBar: ComposeBar!
    
    lazy var chat: Chat = Chat(wrap: self.wrap)
    
    private var messageMetrics = StreamMetrics(loader: StreamLoader<MessageCell>()).change({ $0.selectable = false })
    private var messageWithNameMetrics = StreamMetrics(loader: StreamLoader<MessageWithNameCell>()).change({ $0.selectable = false })
    private var myMessageMetrics = StreamMetrics(loader: StreamLoader<MyMessageCell>()).change({ $0.selectable = false })
    private var dateMetrics = StreamMetrics(loader: StreamLoader<MessageDateView>(), size: 33).change({ $0.selectable = false })
    
    private lazy var placeholderMetrics: StreamMetrics = StreamMetrics(loader: PlaceholderView.chatPlaceholderLoader()).change { [weak self] metrics -> Void in
        metrics.prepareAppearing = { item, view in
            (view as! PlaceholderView).textLabel.text = String(format:"no_chat_message".ls, self?.wrap?.name ?? "")
        }
        metrics.selectable = false
    }
    
    private var unreadMessagesMetrics = StreamMetrics(loader: StreamLoader<StreamReusableView>(layoutBlock: { view in
        let label = Label(preset: .Normal, weight: .Regular , textColor: Color.orange)
        label.text = "unread_messages".ls
        label.textAlignment = .Center
        label.backgroundColor = Color.orangeLightest
        view.addSubview(label)
        label.snp_makeConstraints(closure: { (make) -> Void in
            make.leading.trailing.equalTo(view)
            make.top.bottom.equalTo(view).inset(6)
        })
    }), size: 46).change({ $0.selectable = false })
    
    private var dragged = false
    
    private var runQueue = RunQueue(limit: 1)
    
    deinit {
        streamView?.delegate = nil
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func applicationDidBecomeActive() {
        badge?.value = chat.unreadMessages.count
        streamView.unlock()
        chat.resetMessages()
        scrollToLastUnreadMessage()
        NSNotificationCenter.defaultCenter().removeObserver(self, name:UIApplicationDidBecomeActiveNotification, object:nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector:#selector(ChatViewController.applicationWillResignActive), name:UIApplicationWillResignActiveNotification, object:nil)
    }
    
    func applicationWillResignActive() {
        streamView.lock()
        NSNotificationCenter.defaultCenter().removeObserver(self, name:UIApplicationWillResignActiveNotification, object:nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector:#selector(ChatViewController.applicationDidBecomeActive), name:UIApplicationDidBecomeActiveNotification, object:nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if wrap == nil {
            Dispatch.mainQueue.after(0.5) { self.navigationController?.popViewControllerAnimated(false) }
            return
        }
        
        messageWithNameMetrics.modifyItem = { [weak self] item in
            guard let message = item.entry as? Message else { return }
            item.size = self?.chat.heightOfMessageCell(message) ?? 0.0
            item.insets = CGRectMake(0, message.chatMetadata.containsDate ? 0 : message.chatMetadata.isGroup ? Chat.MessageGroupSpacing : Chat.MessageSpacing, 0, 0)
        }
        messageMetrics.modifyItem = messageWithNameMetrics.modifyItem
        myMessageMetrics.modifyItem = messageWithNameMetrics.modifyItem
        
        chat.addReceiver(self)
        
        if !wrap.messages.isEmpty {
            chat.newer(nil, failure: { $0?.showNonNetworkError() })
        }
        
        Message.notifier().addReceiver(self)
        Keyboard.keyboard.addReceiver(self)
        composeBar.text = wrap.typedMessage
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        streamView.unlock()
        chat.sort()
        scrollToLastUnreadMessage()
        NSNotificationCenter.defaultCenter().addObserver(self, selector:#selector(ChatViewController.applicationWillResignActive), name:UIApplicationWillResignActiveNotification, object:nil)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        streamView.lock()
        chat.markAsRead()
        NSNotificationCenter.defaultCenter().removeObserver(self, name:UIApplicationWillResignActiveNotification, object:nil)
    }
    
    func scrollToLastUnreadMessage() {
        streamView.scrollToItemPassingTest({ $0.metrics === unreadMessagesMetrics }, animated:false)
    }
    
    var typing = false {
        didSet {
            if typing != oldValue {
                enqueueSelector(#selector(self.sendTypingStateChange), delay: 1)
            }
        }
    }
    
    func sendTypingStateChange() {
        if let wrap = wrap {
            NotificationCenter.defaultCenter.sendTyping(typing, wrap: wrap)
        }
    }
    
    override func keyboardWillShow(keyboard: Keyboard) {
        streamView.keepContentOffset {
            super.keyboardWillShow(keyboard)
        }
    }
    
    override func keyboardWillHide(keyboard: Keyboard) {
        streamView.keepContentOffset {
            super.keyboardWillHide(keyboard)
        }
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
                streamView.layoutIfNeeded()
                _self.chat.add(message)
                let offset = streamView.contentOffset
                let maximumOffset = streamView.maximumContentOffset
                if message.contributor != User.currentUser {
                    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
                }
                if !streamView.scrollable || offset.y < maximumOffset.y {
                    finish()
                } else {
                    streamView.reload()
                    streamView.contentOffset = streamView.maximumContentOffset.offset(0, y: -_self.chat.heightOfMessageCell(message))
                    streamView.setMaximumContentOffsetAnimated(true)
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

extension ChatViewController: ListNotifying {
    
    func listChanged(list: List) {
        streamView.reload()
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
            Sound.play()
        } else {
            navigationController?.popToRootViewControllerAnimated(false)
        }
    }
    
    func composeBar(composeBar: ComposeBar, didFinishWithText text: String) {
        self.typing = false
        wrap.typedMessage = nil
        composeBar.text = ""
        sendMessageWithText(text)
    }
    
    func composeBarDidChangeText(composeBar: ComposeBar) {
        wrap.typedMessage = composeBar.text
        typing = composeBar.text?.isEmpty == false
        enqueueSelector(#selector(self.typingIdled), argument: nil, delay: 3)
    }
    
    func composeBarDidBeginEditing(composeBar: ComposeBar) {
        if chat.unreadMessages.count > 0 {
            chat.markAsRead()
            badge?.value = 0
            streamView.reload()
        }
    }
    
    func typingIdled() {
        typing = false
    }
    
    func composeBar(composeBar: ComposeBar, didChangeHeight oldHeight: CGFloat) {
        if composeBar.text?.isEmpty == true { return }
        streamView.contentOffset.y += (composeBar.height - oldHeight)
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
        return chat.entries.count
    }
    
    func streamView(streamView: StreamView, entryBlockForItem item: StreamItem) -> (StreamItem -> AnyObject?)? {
        return { [weak self] item in
            return self?.chat.entries[safe: item.position.index]
        }
    }
    
    func streamView(streamView: StreamView, metricsAt position: StreamPosition) -> [StreamMetrics] {
        var metrics = [StreamMetrics]()
        guard let message = chat.entries[safe: position.index] as? Message else { return metrics }
        if chat.unreadMessages.first == message && badge?.value != 0 {
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
                let offset = streamView.contentSize.height - oldContentSize.height
                if offset > 0 {
                    streamView.contentOffset.y += offset
                }
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
