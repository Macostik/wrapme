//
//  ChatViewController.swift
//  meWrap
//
//  Created by Sergey Maximenko on 2/18/16.
//  Copyright © 2016 Ravenpod. All rights reserved.
//

import UIKit
import AudioToolbox

final class ChatViewController: WrapBaseViewController, UIScrollViewDelegate, StreamViewDataSource, EntryNotifying, ComposeBarDelegate {
    
    weak var badge: BadgeLabel?
    
    private let streamView = StreamView()
    let composeBar = ComposeBar()
    
    let chat: Chat
    
    required init(wrap: Wrap) {
        chat = Chat(wrap: wrap)
        super.init(wrap: wrap)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private var messageMetrics = StreamMetrics<MessageCell>().change({ $0.selectable = false })
    private var messageWithNameMetrics = StreamMetrics<MessageWithNameCell>().change({ $0.selectable = false })
    private var myMessageMetrics = StreamMetrics<MyMessageCell>().change({ $0.selectable = false })
    private var dateMetrics = StreamMetrics<MessageDateView>(size: 33).change({ $0.selectable = false })
    
    private var unreadMessagesMetrics = StreamMetrics<StreamReusableView>(layoutBlock: { view in
        let label = Label(preset: .Normal, weight: .Regular , textColor: Color.orange)
        label.text = "unread_messages".ls
        label.textAlignment = .Center
        label.backgroundColor = Color.orangeLightest
        view.addSubview(label)
        label.snp_makeConstraints(closure: { (make) -> Void in
            make.leading.trailing.equalTo(view)
            make.top.bottom.equalTo(view).inset(6)
        })
    }, size: 46).change({ $0.selectable = false })
    
    private var dragged = false
    
    private var runQueue = RunQueue(limit: 1)
    
    deinit {
        streamView.delegate = nil
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func applicationDidBecomeActive() {
        badge?.value = chat.unreadMessages.count
        streamView.unlock()
        chat.resetMessages()
        scrollToLastUnreadMessage()
        NSNotificationCenter.defaultCenter().removeObserver(self, name:UIApplicationDidBecomeActiveNotification, object:nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector:#selector(self.applicationWillResignActive), name:UIApplicationWillResignActiveNotification, object:nil)
    }
    
    func applicationWillResignActive() {
        streamView.lock()
        NSNotificationCenter.defaultCenter().removeObserver(self, name:UIApplicationWillResignActiveNotification, object:nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector:#selector(self.applicationDidBecomeActive), name:UIApplicationDidBecomeActiveNotification, object:nil)
    }
    
    override func loadView() {
        super.loadView()
        
        view.backgroundColor = UIColor.whiteColor()
        composeBar.backgroundColor = UIColor.whiteColor()
        
        streamView.alwaysBounceVertical = true
        streamView.delegate = self
        streamView.dataSource = self
        view.add(streamView) { (make) in
            make.top.equalTo(view).offset(100)
            make.leading.trailing.equalTo(view)
        }
        view.add(composeBar) { (make) in
            make.leading.trailing.equalTo(view)
            make.top.equalTo(streamView.snp_bottom)
            let constraint = make.bottom.equalTo(view).constraint
            Keyboard.keyboard.handle(self, willShow: { [unowned self] (keyboard) in
                self.streamView.keepContentOffset {
                    keyboard.performAnimation({ () in
                        constraint.updateOffset(-keyboard.height)
                        self.view.layoutIfNeeded()
                    })
                }
            }) { [unowned self] (keyboard) in
                self.streamView.keepContentOffset {
                    keyboard.performAnimation({ () in
                        constraint.updateOffset(0)
                        self.view.layoutIfNeeded()
                    })
                }
            }
        }
        let separator = SeparatorView(color: Color.grayLighter, contentMode: .Top)
        composeBar.add(separator) { (make) in
            make.leading.top.trailing.equalTo(composeBar)
            make.height.equalTo(1)
        }
        
        streamView.placeholderViewBlock = { [weak self] _ in
            let view = PlaceholderView.chatPlaceholder()()
            view.textLabel.text = String(format:"no_chat_message".ls, self?.wrap.name ?? "")
            return view
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        composeBar.textView.placeholder = "message_placeholder".ls
        composeBar.textView.textColor = Color.grayDark
        composeBar.delegate = self
        if wrap.valid == false {
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
        
        chat.didChangeNotifier.subscribe(self) { [unowned self] (value) in
            self.streamView.reload()
        }
        
        if !wrap.messages.isEmpty {
            chat.newer(nil, failure: { $0?.showNonNetworkError() })
        }
        
        Message.notifier().addReceiver(self)
        composeBar.text = wrap.typedMessage
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        streamView.width = view.width
        streamView.unlock()
        chat.sort()
        scrollToLastUnreadMessage()
        NSNotificationCenter.defaultCenter().addObserver(self, selector:#selector(self.applicationWillResignActive), name:UIApplicationWillResignActiveNotification, object:nil)
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
        NotificationCenter.defaultCenter.sendTyping(typing, wrap: wrap)
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
    
    private func appendItemsIfNeededWithTargetContentOffset(targetContentOffset: CGPoint) {
        let sv = self.streamView
        let reachedRequiredOffset = (targetContentOffset.y - sv.minimumContentOffset.y) < sv.fittingContentHeight
        if reachedRequiredOffset && Network.network.reachable && !chat.completed {
            if wrap.valid == true {
                chat.older(nil, failure: { $0?.showNonNetworkError() })
            }
        }
    }
    
    // MARK: - StreamViewDataSource
    
    func numberOfItemsIn(section: Int) -> Int {
        return chat.entries.count
    }
    
    func entryBlockForItem(item: StreamItem) -> (StreamItem -> AnyObject?)? {
        return { [weak self] item in
            return self?.chat.entries[safe: item.position.index]
        }
    }
    
    func metricsAt(position: StreamPosition) -> [StreamMetricsProtocol] {
        var metrics = [StreamMetricsProtocol]()
        guard let message = chat.entries[safe: position.index] else { return metrics }
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
    
    func didChangeContentSize(oldContentSize: CGSize) {
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
    
    func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        dragged = true
    }
    
    func scrollViewWillEndDragging(scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        appendItemsIfNeededWithTargetContentOffset(targetContentOffset.memory)
    }
    
    // MARK: - EntryNotifying
    
    func notifier(notifier: EntryNotifier, didAddEntry entry: Entry) {
        insertMessage(entry as! Message)
    }
    
    func notifier(notifier: EntryNotifier, didUpdateEntry entry: Entry, event: EntryUpdateEvent) {
        streamView.reload()
    }
    
    func notifier(notifier: EntryNotifier, willDeleteEntry entry: Entry) {
        guard let message = entry as? Message else { return }
        chat.remove(message)
    }
    
    func notifier(notifier: EntryNotifier, shouldNotifyOnEntry entry: Entry) -> Bool {
        return wrap == entry.container
    }
    
    // MARK: - ComposeBarDelegate
    
    private func sendMessageWithText(text: String) {
        if wrap.valid {
            markAsReadIfNeeded()
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
        if markAsReadIfNeeded() {
            streamView.reload()
        }
        wrap.typedMessage = composeBar.text
        typing = composeBar.text?.isEmpty == false
        enqueueSelector(#selector(self.typingIdled), argument: nil, delay: 3)
    }
    
    private func markAsReadIfNeeded() -> Bool {
        if chat.unreadMessages.count > 0 || badge?.value > 0 {
            chat.markAsRead()
            badge?.value = 0
            return true
        } else {
            return false
        }
    }
    
    func composeBarDidBeginEditing(composeBar: ComposeBar) {
        if markAsReadIfNeeded() {
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
