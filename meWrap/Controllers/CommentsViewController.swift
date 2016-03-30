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
    
    private let avatarView = StatusUserAvatarView()
    private let nameLabel = Label(preset: .Normal, textColor: Color.grayDark)
    private let dateLabel = Label(preset: .Small, textColor: Color.grayLight)
    private let textLabel = SmartLabel(preset: .Normal, weight: .Regular, textColor: UIColor.blackColor())
    private let indicator = EntryStatusIndicator(color: Color.grayLight)
    
    override func layoutWithMetrics(metrics: StreamMetrics) {
        avatarView.startReceivingStatusUpdates()
        FlowerMenu.sharedMenu.registerView(self)
        textLabel.numberOfLines = 0
        avatarView.cornerRadius = 24
        avatarView.defaultIconSize = 24
        addSubview(avatarView)
        addSubview(nameLabel)
        addSubview(dateLabel)
        addSubview(textLabel)
        addSubview(indicator)
        avatarView.snp_makeConstraints { (make) -> Void in
            make.leading.top.equalTo(self).offset(12)
            make.size.equalTo(48)
        }
        nameLabel.snp_makeConstraints { (make) -> Void in
            make.leading.equalTo(avatarView.snp_trailing).offset(12)
            make.top.equalTo(avatarView)
            make.trailing.lessThanOrEqualTo(self).inset(12)
        }
        textLabel.snp_makeConstraints { (make) -> Void in
            make.leading.equalTo(avatarView.snp_trailing).offset(12)
            make.top.equalTo(nameLabel.snp_bottom)
            make.trailing.lessThanOrEqualTo(self).inset(12)
        }
        dateLabel.snp_makeConstraints { (make) -> Void in
            make.leading.equalTo(avatarView.snp_trailing).offset(12)
            make.top.equalTo(textLabel.snp_bottom)
        }
        indicator.snp_makeConstraints { (make) -> Void in
            make.leading.equalTo(dateLabel.snp_trailing).offset(2)
            make.centerY.equalTo(dateLabel)
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
        nameLabel.text = comment.contributor?.name
        avatarView.wrap = comment.candy?.wrap
        avatarView.user = comment.contributor
        dateLabel.text = comment.createdAt.timeAgoString()
        indicator.updateStatusIndicator(comment)
        textLabel.text = comment.text
    }
}

private let CommentHorizontalSpacing: CGFloat = 84.0
private let CommentVerticalSpacing: CGFloat = 24.0

class CommentsViewController: BaseViewController {
    
    weak var candy: Candy?
    
    @IBOutlet weak var streamView: StreamView!
    
    private lazy var dataSource: StreamDataSource = StreamDataSource(streamView: self.streamView)
    
    @IBOutlet weak var composeBarBottomPrioritizer: LayoutPrioritizer!
    @IBOutlet weak var contentView: InternalScrollView!
    weak var historyViewController: HistoryViewController?
    
    private var candyNotifyReceiver: EntryNotifyReceiver<Candy>?
    
    private var commentNotifyReceiver: EntryNotifyReceiver<Comment>?
    
    deinit {
        contentView?.delegate = nil
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let candy = candy?.validEntry() else { return }
        
        candy.comments.all({ $0.markAsUnread(false) })
        
        dataSource.addMetrics(specify(StreamMetrics(loader: StreamLoader<CommentCell>()), {
            $0.selectable = false
            $0.modifyItem = { item in
                let comment = item.entry as! Comment
                let font = UIFont.fontNormal()
                let nameFont = UIFont.lightFontNormal()
                let timeFont = UIFont.lightFontSmall()
                let textHeight = comment.text?.heightWithFont(font, width:Constants.screenWidth - CommentHorizontalSpacing) ?? 0
                item.size = max(72, textHeight + nameFont.lineHeight + timeFont.lineHeight + CommentVerticalSpacing)
            }
        }))
        dataSource.placeholderMetrics = PlaceholderView.commentsPlaceholderMetrics()
        dataSource.didLayoutBlock = { [weak self] _ in
            self?.streamView.setMaximumContentOffsetAnimated(false)
        }
        dataSource.items = candy.sortedComments()
        Dispatch.mainQueue.async { [weak self] _ in
            self?.dataSource.didLayoutBlock = nil
        }
        
        if candy.uploaded {
            candy.fetch({ [weak self] _ in
                self?.dataSource.items = candy.sortedComments()
                }, failure: { [weak self] (error) -> Void in
                    self?.dataSource.reload()
                    error?.showNonNetworkError()
            })
        }
        
        addNotifyReceivers()
        DeviceManager.defaultManager.addReceiver(self)
        historyViewController = parentViewController as? HistoryViewController
    }
    
    private func addNotifyReceivers() {
        
        commentNotifyReceiver = EntryNotifyReceiver<Comment>().setup { [weak self] receiver in
            receiver.container = { return self?.candy }
            
            receiver.willDelete = { entry in
                var comments = self?.dataSource.items as? [Comment]
                if let index = comments?.indexOf(entry) {
                    comments?.removeAtIndex(index)
                }
                self?.dataSource.items = comments
            }
            receiver.didAdd = { _ in
                self?.dataSource.items = self?.candy?.sortedComments()
            }
            receiver.didUpdate = { _ in
                self?.dataSource.items = self?.candy?.sortedComments()
            }
        }
        
        candyNotifyReceiver = EntryNotifyReceiver<Candy>().setup {  [weak self]receiver in
            receiver.entry = { return self?.candy }
            receiver.container = { return self?.candy?.wrap }
            receiver.willDelete = { _ in
                self?.onClose(nil)
            }
            receiver.willDeleteContainer = { _ in
                self?.onClose(nil)
            }
        }
    }
    
    override func requestAuthorizationForPresentingEntry(entry: Entry, completion: BooleanBlock) {
        if let comment = entry as? Comment {
            completion(!(candy?.comments.contains(comment) ?? false))
        }
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
    
    private static let ContstraintOffset: CGFloat = 44
    var height: CGFloat = 0.0
    
    override func keyboardAdjustmentConstant(adjustment: KeyboardAdjustment, keyboard: Keyboard) -> CGFloat {
        if adjustment.constraint.constant == adjustment.defaultConstant {
            if dataSource.items?.count == 0 {
                height = streamView.height
                streamView.height -= keyboard.height + CommentsViewController.ContstraintOffset
            }
            let offset = CGPointMake(0, keyboard.height + streamView.contentOffset.y > 0 ?
                view.height - streamView.height + streamView.contentOffset.y - 25.0 : streamView.contentOffset.y)
            streamView.setContentOffset(offset, animated: false)
        }
        
        return adjustment.defaultConstant + (keyboard.height - CommentsViewController.ContstraintOffset)
    }
    
    override func keyboardWillHide(keyboard: Keyboard) {
        super.keyboardWillHide(keyboard)
        keyboard.performAnimation {
            streamView.height = height
            let offset = streamView.contentOffset.y >= streamView.maximumContentOffset.y ?
                streamView.maximumContentOffset.y + 25.0 : streamView.contentOffset.y - view.height + streamView.height
            streamView.setContentOffset(CGPointMake(0, offset), animated: false)
        }
    }
    
    private func sendMessageWithText(text: String) {
        onClose(nil)
        if let candy = candy?.validEntry() {
            Dispatch.mainQueue.async {
                SoundPlayer.playSend()
                candy.uploadComment(text.trim)
            }
        }
    }
    
    func presentForController(controller: UIViewController?) {
        controller?.addContainedViewController(self, animated:false)
        contentView.transform = CGAffineTransformMakeTranslation(0, view.frame.maxY)
        UIView.animateWithDuration(0.5, delay:0.0, usingSpringWithDamping:0.7, initialSpringVelocity:1, options:.CurveEaseIn,
            animations: {
                self.contentView.transform = CGAffineTransformIdentity
            }, completion:nil)
    }
    
    @IBAction func onClose(sender: AnyObject?) {
        typing = false
        view.endEditing(true)
        removeFromContainerAnimated(true)
        historyViewController?.viewWillAppear(true)
        historyViewController?.applyScaleToCandyViewController(false)
    }
    
    @IBAction func hide(sender: UITapGestureRecognizer) {
        let contentView = streamView.superview
        if contentView?.bounds.contains(sender.locationInView(contentView)) == true {
            view.endEditing(true)
        } else {
            onClose(nil)
        }
    }
}

extension CommentsViewController: ComposeBarDelegate {
    
    func composeBar(composeBar: ComposeBar, didFinishWithText text: String) {
        typing = false
        sendMessageWithText(text)
    }
    
    func composeBarDidChangeText(composeBar: ComposeBar) {
        typing = composeBar.text?.isEmpty == false
        enqueueSelector(#selector(CommentsViewController.typingIdled), argument: nil, delay: 3)
    }
    
    func typingIdled() {
        typing = false
    }
    
    func composeBarDidShouldResignOnFinish(composeBar: ComposeBar) -> Bool {
        return false
    }
}

extension CommentsViewController: DeviceManagerNotifying {
    
    func manager(manager: DeviceManager, didChangeOrientation orientation: UIDeviceOrientation) {
        view.layoutIfNeeded()
        dataSource.reload()
    }
}

extension CommentsViewController: UIScrollViewDelegate {
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        let direction = scrollView.panGestureRecognizer.translationInView(scrollView.superview).y < 0
        composeBarBottomPrioritizer.defaultState = direction
    }
    
    func scrollViewWillEndDragging(scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        let offset = scrollView.contentOffset.y
        if abs(offset) > scrollView.height/5 || abs(velocity.y) > 2 {
            let snapshot = contentView.snapshotViewAfterScreenUpdates(false)
            snapshot.frame = CGRectMake(0, self.contentView.y, self.view.width, self.contentView.height)
            view.window?.addSubview(snapshot)
            typing = false
            removeFromContainerAnimated(true)
            UIView.animateWithDuration(0.5, animations: {
                let offsetY = offset > 0 ? self.view.y - self.view.height : self.view.height
                snapshot.transform = CGAffineTransformMakeTranslation(0, offsetY);
                self.historyViewController?.applyScaleToCandyViewController(false)
                }, completion: { _ in
                    snapshot.removeFromSuperview()
            })
        }
    }
}
