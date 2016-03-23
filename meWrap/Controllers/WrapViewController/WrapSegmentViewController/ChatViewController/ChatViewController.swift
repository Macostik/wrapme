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
    
    private var runQueue = RunQueue(limit: 1)
    
    var showKeyboard = false {
        willSet {
            if isViewLoaded() && newValue {
                composeBar.becomeFirstResponder()
            }
        }
    }
    
    var presentedText: String? {
        willSet {
            if let newValue = newValue where !newValue.isEmpty {
                composeBar?.text = newValue
            }
        }
    }
    
    deinit {
        streamView?.delegate = nil
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func applicationDidBecomeActive() {
        streamView.unlock()
        chat.resetMessages()
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
        FontPresetter.defaultPresetter.addReceiver(self)
        streamView.layoutIfNeeded()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        streamView.unlock()
        chat.sort()
        NSNotificationCenter.defaultCenter().addObserver(self, selector:#selector(ChatViewController.applicationWillResignActive), name:UIApplicationWillResignActiveNotification, object:nil)
        if showKeyboard {
            composeBar.becomeFirstResponder()
            if presentedText != nil {
                composeBar.text = presentedText
            }
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        streamView.lock()
        chat.markAsRead()
        NSNotificationCenter.defaultCenter().removeObserver(self, name:UIApplicationWillResignActiveNotification, object:nil)
    }
    
    var typing = false {
        didSet {
            if typing != oldValue {
                enqueueSelector(#selector(ChatViewController.sendTypingStateChange), delay: 1)
            }
        }
    }
    
    func sendTypingStateChange() {
        if let wrap = wrap {
            NotificationCenter.defaultCenter.sendTyping(typing, wrap: wrap)
        }
    }
    
    override func keyboardWillShow(keyboard: Keyboard) {
        super.keyboardWillShow(keyboard)
        keyboard.performAnimation {
            streamView.contentInset.bottom = 0
            streamView.contentInset.bottom = keyboard.height
            composeBar.transform = CGAffineTransformMakeTranslation(0, -keyboard.height)
            var offset = keyboard.height - (streamView.height - streamView.contentSize.height)
            offset = offset < 0 ? 0 : streamView.height - keyboard.height > offset || offset < streamView.height
                ? offset : streamView.contentOffset.y + keyboard.height
            streamView.setContentOffset(CGPointMake(0, offset), animated: false)
        }
    }
    
    override func keyboardWillHide(keyboard: Keyboard) {
        super.keyboardWillHide(keyboard)
        keyboard.performAnimation {
            streamView.contentInset = UIEdgeInsetsZero
            composeBar.transform = CGAffineTransformIdentity
            let yOffset = abs(streamView.maximumContentOffset.y - streamView.contentOffset.y) < Chat.MessageSpacing ?
                self.streamView.maximumContentOffset.y : self.streamView.contentOffset.y - keyboard.height
            streamView.setContentOffset(CGPointMake(0, yOffset), animated: false)
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
                _self.chat.add(message)
                let offset = streamView.contentOffset
                let maximumOffset = streamView.maximumContentOffset
                if let user = message.contributor where user != User.currentUser {
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
            SoundPlayer.playSend()
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
        enqueueSelector(#selector(ChatViewController.typingIdled), argument: nil, delay: 3)
    }
    
    func typingIdled() {
        typing = false
    }
    
    func composeBar(composeBar: ComposeBar, didChangeHeight oldHeight: CGFloat) {
        if composeBar.text?.isEmpty == true { return }
        streamView.setContentOffset(CGPointMake(0, streamView.contentOffset.y + (composeBar.height - oldHeight)), animated: false)
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
            streamView.contentOffset = streamView.maximumContentOffset
        }
        appendItemsIfNeededWithTargetContentOffset(streamView.contentOffset)
    }
    
    func streamViewPlaceholderMetrics(streamView: StreamView) -> StreamMetrics? {
        return placeholderMetrics
    }
    
    func scrollViewWillEndDragging(scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        appendItemsIfNeededWithTargetContentOffset(targetContentOffset.memory)
    }
}
