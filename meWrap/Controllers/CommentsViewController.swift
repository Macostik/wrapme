//
//  CommentsViewController.swift
//  meWrap
//
//  Created by Sergey Maximenko on 2/22/16.
//  Copyright © 2016 Ravenpod. All rights reserved.
//

import UIKit
import SnapKit

import MobileCoreServices

final class CommentCell: StreamReusableView, FlowerMenuConstructor {
    
    private let avatar = UserAvatarView(cornerRadius: 24)
    private let name = Label(preset: .Small, weight: .Bold, textColor: UIColor.whiteColor())
    private let date = Label(preset: .Smaller, weight: .Regular, textColor: Color.grayLighter)
    private let text = SmartLabel(preset: .Small, weight: .Regular, textColor: UIColor.whiteColor())
    private let indicator = EntryStatusIndicator(color: Color.orange)
    
    override func layoutWithMetrics(metrics: StreamMetrics) {
        FlowerMenu.sharedMenu.registerView(self)
        text.numberOfLines = 0
        avatar.defaultIconSize = 24
        addSubview(avatar)
        addSubview(name)
        addSubview(date)
        addSubview(text)
        addSubview(indicator)
        
        avatar.snp_makeConstraints { (make) -> Void in
            make.leading.top.equalTo(self).offset(20)
            make.size.equalTo(48)
        }
        text.snp_makeConstraints { (make) -> Void in
            make.leading.equalTo(avatar.snp_trailing).offset(18)
            make.top.equalTo(avatar)
            make.trailing.lessThanOrEqualTo(self).inset(18)
        }
        name.snp_makeConstraints { (make) -> Void in
            make.leading.equalTo(avatar.snp_trailing).offset(18)
            make.top.equalTo(text.snp_bottom).offset(16)
            make.trailing.lessThanOrEqualTo(self).inset(18)
        }
        
        date.snp_makeConstraints { (make) -> Void in
            make.leading.equalTo(avatar.snp_trailing).offset(18)
            make.top.equalTo(name.snp_bottom).offset(4)
        }
        
        indicator.snp_makeConstraints { (make) -> Void in
            make.leading.equalTo(date.snp_trailing).offset(12)
            make.centerY.equalTo(date)
        }
    }
    
    func constructFlowerMenu(menu: FlowerMenu) {
        guard let comment = entry as? Comment else { return }
        if comment.deletable {
            menu.addDeleteAction({ [weak self] _ in
                self?.userInteractionEnabled = false
                comment.delete ({ (_) -> Void in
                    self?.userInteractionEnabled = true
                    }, failure: { (error) in
                        error?.show()
                        self?.userInteractionEnabled = true
                })
                })
        }
        menu.addCopyAction({ UIPasteboard.generalPasteboard().string = comment.text })
    }
    
    override func setup(entry: AnyObject?) {
        guard let comment = entry as? Comment else { return }
        userInteractionEnabled = true
        comment.markAsUnread(false)
        name.text = comment.contributor?.name
        avatar.user = comment.contributor
        date.text = comment.createdAt.timeAgoString()
        indicator.updateStatusIndicator(comment)
        text.text = comment.text
    }
}

private let CommentEstimateWidth: CGFloat = Constants.screenWidth - 104
private let CommentVerticalSpacing: CGFloat = 60

class CommentsViewController: BaseViewController {
    
    weak var candy: Candy?
    
    @IBOutlet weak var streamView: StreamView!
    @IBOutlet weak var friendsStreamView: StreamView!
    
    private lazy var friendsDataSource: StreamDataSource<[User]> = StreamDataSource(streamView: self.friendsStreamView)
    
    private lazy var dataSource: StreamDataSource<[Comment]> = StreamDataSource(streamView: self.streamView)
    
    @IBOutlet weak var composeBar: ComposeBar!
    
    @IBOutlet weak var composeBarBottomPrioritizer: LayoutPrioritizer!
    @IBOutlet weak var contentView: UIView!
    weak var historyViewController: HistoryViewController?
    
    private var candyNotifyReceiver: EntryNotifyReceiver<Candy>?
    
    private var commentNotifyReceiver: EntryNotifyReceiver<Comment>?
    @IBOutlet weak var topView: UIView!
    
    deinit {
        streamView.layer.removeObserver(self, forKeyPath: "bounds", context: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        streamView.indicatorStyle = .White
        
        streamView.layer.addObserver(self, forKeyPath: "bounds", options: .New, context: nil)
        view.addGestureRecognizer(streamView.panGestureRecognizer)
        streamView.panGestureRecognizer.addTarget(self, action: #selector(self.panned(_:)))
        
        guard let candy = candy?.validEntry() else { return }
        
        candy.comments.all({ $0.markAsUnread(false) })
        
        dataSource.addMetrics(specify(StreamMetrics(loader: StreamLoader<CommentCell>()), {
            $0.selectable = false
            $0.modifyItem = { [weak self] item in
                let comment = item.entry as! Comment
                item.size = self?.heightCell(comment) ?? 0
            }
        }))
        dataSource.placeholderMetrics = PlaceholderView.commentsPlaceholderMetrics()
        dataSource.items = candy.sortedComments()
        
        friendsStreamView.layout = HorizontalStreamLayout()
        let friendMetrics = StreamMetrics(loader: StreamLoader<FriendView>(), size: friendsStreamView.height)
        friendMetrics.prepareAppearing = { [weak self] item, view in
            (view as? FriendView)?.wrap = self?.candy?.wrap
        }
        friendsDataSource.addMetrics(friendMetrics)
        
        if candy.uploaded {
            candy.fetch({ [weak self] _ in
                self?.dataSource.items = candy.sortedComments()
                }, failure: { [weak self] (error) -> Void in
                    self?.dataSource.reload()
                    error?.showNonNetworkError()
            })
        }
        friendsDataSource.items = activeContibutors
        
        addNotifyReceivers()
        DeviceManager.defaultManager.addReceiver(self)
		User.notifier().addReceiver(self)
        composeBar.text = candy.typedComment
    }
    
    func panned(sender: UIPanGestureRecognizer) {
        if sender.state == .Ended && scrollingOffset != 0 {
            let velocity = sender.velocityInView(sender.view)
            if abs(scrollingOffset) > streamView.height/3 || abs(velocity.y) > 1000 {
                let snapshot = contentView.snapshotViewAfterScreenUpdates(false)
                snapshot.frame = contentView.frame
                contentView.hidden = true
                view.addSubview(snapshot)
                typing = false
                composeBar.resignFirstResponder()
                self.historyViewController?.setBarsHidden(false, animated: true)
                UIView.animateWithDuration(0.5, animations: {
                    let offsetY = self.scrollingOffset > 0 ? -self.view.height : self.view.height
                    snapshot.transform = CGAffineTransformMakeTranslation(0, offsetY)
                    self.view.backgroundColor = UIColor.clearColor()
                    }, completion: { _ in
                        self.removeFromContainerAnimated(true)
                })
            }
        }
    }
    
    var scrollingOffset: CGFloat = 0
    
    private func scrollingOffsetChanged() {
        if streamView.contentOffset.y < 0 {
            scrollingOffset = streamView.contentOffset.y
            let offset = abs(scrollingOffset)
            topView.transform = CGAffineTransformMakeTranslation(0, offset)
            composeBar.transform = CGAffineTransformIdentity
            let value = smoothstep(0, 1, 1 - offset / (contentView.height / 2))
            view.backgroundColor = UIColor(white: 0, alpha: 0.7 * value)
        } else if streamView.contentOffset.y > streamView.maximumContentOffset.y {
            let offset = (streamView.contentOffset.y - streamView.maximumContentOffset.y)
            topView.transform = CGAffineTransformIdentity
            composeBar.transform = CGAffineTransformMakeTranslation(0, -offset)
            let value = smoothstep(0.0, 1.0, 1 - offset / (contentView.height / 2))
            view.backgroundColor = UIColor(white: 0, alpha: 0.7 * value)
            scrollingOffset = offset
        } else {
            scrollingOffset = 0
            topView.transform = CGAffineTransformIdentity
            composeBar.transform = CGAffineTransformIdentity
            view.backgroundColor = UIColor(white: 0, alpha: 0.7)
        }
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if !contentView.hidden {
            scrollingOffsetChanged()
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        streamView.setMaximumContentOffsetAnimated(false)
    }
    
    var isEndingOfScroll: Bool {
        return abs(streamView.contentOffset.y - streamView.maximumContentOffset.y) <= 5
    }

 	var activeContibutors: [User] {
        set {}
        get {
            guard let wrap = candy?.wrap else { return [] }
            return wrap.contributors.filter({$0.activityForWrap(wrap) != nil }).sort({$0.name < $1.name})
        }
    }
    
    private func addNotifyReceivers() {
        commentNotifyReceiver = EntryNotifyReceiver<Comment>().setup { [weak self] receiver in
            receiver.container = { return self?.candy }
            
            receiver.willDelete = { entry in
                var comments = self?.dataSource.items
                comments?.remove(entry)
                self?.dataSource.items = comments
            }
            receiver.didAdd = { entry in
                let isEndingOfScroll = self?.isEndingOfScroll ?? false
                self?.dataSource.items = self?.candy?.sortedComments()
                if isEndingOfScroll {
                    self?.streamView.setMaximumContentOffsetAnimated(true)
                }
            }
            receiver.didUpdate = { _ in
                self?.dataSource.items = self?.candy?.sortedComments()
            }
        }
        
        candyNotifyReceiver = EntryNotifyReceiver<Candy>().setup { [weak self] receiver in
            receiver.entry = { return self?.candy }
            receiver.container = { return self?.candy?.wrap }
            receiver.willDelete = { _ in
                self?.close()
            }
            receiver.willDeleteContainer = { _ in
                self?.close()
            }
        }
    }
    
    private func heightCell(comment: Comment) -> CGFloat {
        let font = Font.Small + .Regular
        let nameFont = Font.Small + .Bold
        let timeFont = Font.Smaller + .Regular
        let textHeight = comment.text?.heightWithFont(font, width:CommentEstimateWidth) ?? 0
        return max(textHeight, font.lineHeight) + nameFont.lineHeight + timeFont.lineHeight + CommentVerticalSpacing
    }
    
    override func requestAuthorizationForPresentingEntry(entry: Entry, completion: BooleanBlock) {
        completion((entry as? Comment)?.candy != candy)
    }
    
    var typing = false {
        didSet {
            if typing != oldValue {
                enqueueSelector(#selector(CommentsViewController.sendTypingStateChange), delay: 1)
            }
        }
    }
    
    func sendTypingStateChange() {
        if let wrap = candy?.wrap {
            NotificationCenter.defaultCenter.sendTyping(typing, wrap: wrap)
        }
    }
    
    private func keepContentOffset(@noescape block: () -> ()) {
        let height = streamView.height
        let offset = streamView.contentOffset.y
        block()
        streamView.contentOffset.y = smoothstep(0, streamView.maximumContentOffset.y, offset + (height - streamView.height))
    }
    
    override func keyboardWillShow(keyboard: Keyboard) {
        keepContentOffset { 
            super.keyboardWillShow(keyboard)
        }
    }
    
    override func keyboardWillHide(keyboard: Keyboard) {
        keepContentOffset {
            super.keyboardWillHide(keyboard)
        }
    }
    
    private func sendMessageWithText(text: String) {
        close(true)
        if let candy = candy?.validEntry() {
            Dispatch.mainQueue.async {
                Sound.play()
                candy.uploadComment(text.trim)
            }
        }
    }
    
    func presentForController(controller: HistoryViewController) {
        historyViewController = controller
        controller.addContainedViewController(self, animated:false)
        let backgroundColor = view.backgroundColor
        view.backgroundColor = UIColor.clearColor()
        contentView.transform = CGAffineTransformMakeTranslation(0, view.height)
        animate {
            view.backgroundColor = backgroundColor
            contentView.transform = CGAffineTransformIdentity
        }
    }
    
    func close(animated: Bool = false) {
        typing = false
        view.endEditing(true)
        if animated {
            UIView.animateWithDuration(0.2, animations: {
                self.view.backgroundColor = UIColor.clearColor()
                self.contentView.transform = CGAffineTransformMakeTranslation(0, self.view.height)
            }) { (_) in
                self.removeFromContainerAnimated(true)
            }
        } else {
            removeFromContainerAnimated(true)
        }
        historyViewController?.setBarsHidden(false, animated: true)
    }
    
    @IBAction func onClose(sender: AnyObject?) {
        close(true)
    }
}

extension CommentsViewController: ComposeBarDelegate {
    
    func composeBar(composeBar: ComposeBar, didFinishWithText text: String) {
        typing = false
        candy?.typedComment = nil
        sendMessageWithText(text)
    }
    
    func composeBarDidChangeText(composeBar: ComposeBar) {
        candy?.typedComment = composeBar.text
        typing = composeBar.text?.isEmpty == false
        enqueueSelector(#selector(CommentsViewController.typingIdled), argument: nil, delay: 3)
    }
    
    func typingIdled() {
        typing = false
    }
}

extension CommentsViewController: DeviceManagerNotifying {
    
    func manager(manager: DeviceManager, didChangeOrientation orientation: UIDeviceOrientation) {
        view.layoutIfNeeded()
        dataSource.reload()
    }
}
extension CommentsViewController: EntryNotifying {
    
    func notifier(notifier: EntryNotifier, didUpdateEntry entry: Entry, event: EntryUpdateEvent) {
        friendsDataSource.items = activeContibutors
    }
}