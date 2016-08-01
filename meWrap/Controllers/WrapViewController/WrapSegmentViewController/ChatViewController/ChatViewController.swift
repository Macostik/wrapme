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
    
    let streamView = StreamView()
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
        let label = Label(preset: .Small, weight: .Regular, textColor: Color.grayLightest)
        label.text = "unread_messages".ls
        view.add(label) { (make) -> Void in
            make.center.equalTo(view)
        }
        let border = UIView()
        border.backgroundColor = Color.dangerRed
        border.cornerRadius = 16
        view.insertSubview(border, belowSubview: label)
        border.snp_makeConstraints(closure: { (make) in
            make.leading.equalTo(label).offset(-16)
            make.trailing.equalTo(label).offset(16)
            make.centerY.equalTo(label)
            make.height.equalTo(32)
        })
        let leftLine = UIView()
        leftLine.backgroundColor = Color.dangerRed
        view.add(leftLine) { (make) in
            make.centerY.leading.equalTo(view)
            make.trailing.equalTo(border.snp_leading)
            make.height.equalTo(1)
        }
        let rightLine = UIView()
        rightLine.backgroundColor = Color.dangerRed
        view.add(rightLine) { (make) in
            make.centerY.trailing.equalTo(view)
            make.leading.equalTo(border.snp_trailing)
            make.height.equalTo(1)
        }
    }, size: 46).change({ $0.selectable = false })
    
    private var dragged = false
    
    private var runQueue = RunQueue(limit: 1)
    
    deinit {
        streamView.delegate = nil
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func applicationDidBecomeActive() {
        badge?.value = chat.unreadMessages.count
        streamView.reload()
        scrollToLastUnreadMessage()
    }
    
    func applicationWillResignActive() {
        if markAsReadIfNeeded() {
            streamView.reload()
        }
    }
    
    override func loadView() {
        super.loadView()
        
        view.backgroundColor = Color.grayLightest
        composeBar.backgroundColor = UIColor.whiteColor()
        streamView.alwaysBounceVertical = true
        streamView.delegate = self
        streamView.dataSource = self
        view.add(streamView) { (make) in
            make.top.equalTo(view)
            make.leading.trailing.equalTo(view)
        }
        view.add(composeBar) { (make) in
            make.leading.trailing.equalTo(view)
            make.top.equalTo(streamView.snp_bottom)
            let constraint = make.bottom.equalTo(view).constraint
            Keyboard.keyboard.handle(self, block: { [unowned self] (keyboard, willShow) in
                self.streamView.keepContentOffset {
                    keyboard.performAnimation({ () in
                        constraint.updateOffset(willShow ? -keyboard.height : 0)
                        self.view.layoutIfNeeded()
                    })
                }
                })
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
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector:#selector(self.applicationWillResignActive), name:UIApplicationWillResignActiveNotification, object:nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector:#selector(self.applicationDidBecomeActive), name:UIApplicationDidBecomeActiveNotification, object:nil)
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
//            item.insets.origin.y = message.chatMetadata.containsDate ? 0 : message.chatMetadata.isGroup ? Chat.MessageGroupSpacing : 0
            item.insets.size.height = message.chatMetadata.isGroupEnd ? Chat.MessageGroupSpacing : Chat.MessageSpacing
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
    
    private var topViewsHidden = false
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        topViewsHidden = false
        streamView.width = view.width
        streamView.unlock()
        chat.sort()
        scrollToLastUnreadMessage()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        streamView.lock()
        chat.markAsRead()
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
        if streamView.locked {
            chat.add(message)
            return
        }
        
        runQueue.run { [weak self] (finish) -> Void in
            guard let _self = self else {
                finish()
                return
            }
            let streamView = _self.streamView
            _self.chat.add(message)
            let offset = streamView.contentOffset.y
            let maxOffset = streamView.maximumContentOffset.y
            if message.contributor != User.currentUser {
                AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
            }
            if !streamView.scrollable || maxOffset - offset > 5 {
                finish()
            } else {
                streamView.contentOffset.y = maxOffset - _self.chat.heightOfMessageCell(message)
                streamView.setMaximumContentOffsetAnimated(true)
                Dispatch.mainQueue.after(0.5, block:finish)
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
    
    private func setTopViewsHidden(hidden: Bool) {
        if hidden != topViewsHidden {
            if streamView.scrollable || !hidden {
                topViewsHidden = hidden
                streamView.contentInset.top = hidden ? 0 : 100
                animate(animations: {
                    (parentViewController as? WrapViewController)?.setTopViewsHidden(hidden)
                })
            }
        }
    }
    
    func composeBar(composeBar: ComposeBar, didFinishWithText text: String) {
        setTopViewsHidden(false)
        self.typing = false
        wrap.typedMessage = nil
        composeBar.text = ""
        view.layoutIfNeeded()
        sendMessageWithText(text)
    }
    
    func composeBarDidChangeText(composeBar: ComposeBar) {
        if markAsReadIfNeeded() {
            streamView.reload()
        }
        wrap.typedMessage = composeBar.text
        typing = composeBar.text?.isEmpty == false
        setTopViewsHidden(typing)
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
        setTopViewsHidden(composeBar.text?.isEmpty == false)
        if markAsReadIfNeeded() {
            streamView.reload()
        }
    }
    
    func composeBarDidEndEditing(composeBar: ComposeBar) {
        setTopViewsHidden(false)
    }
    
    func typingIdled() {
        typing = false
    }
    
    func composeBar(composeBar: ComposeBar, didChangeHeight oldHeight: CGFloat) {
        if composeBar.text?.isEmpty == true { return }
        streamView.contentOffset.y += (composeBar.height - oldHeight)
    }
}
