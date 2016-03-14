//
//  CommentsViewController.swift
//  meWrap
//
//  Created by Sergey Maximenko on 2/22/16.
//  Copyright © 2016 Ravenpod. All rights reserved.
//

import UIKit

import MobileCoreServices

class CommentCell: StreamReusableView, FlowerMenuConstructor {
    
    static let CommentLabelLenght = 250
    static let AuthorLabelHeight = 20
    static let MinimumCellHeight = 50
    static let LineHeadIndent = 16
    static let CommentItemIdentifier = "CommentCell"
    
    @IBOutlet weak var authorImageView: ImageView!
    @IBOutlet weak var authorNameLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var commentTextView: UILabel!
    @IBOutlet weak var indicator: EntryStatusIndicator!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        FlowerMenu.sharedMenu.registerView(self)
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
        authorNameLabel.text = comment.contributor?.name
        authorImageView.url = comment.contributor?.avatar?.small
        dateLabel.text = comment.createdAt.timeAgoString()
        indicator.updateStatusIndicator(comment)
        commentTextView.text = comment.text
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
        
        for comment in candy.comments {
            comment.markAsUnread(false)
        }
        
        self.dataSource.autogeneratedMetrics.identifier = CommentCell.CommentItemIdentifier
        self.dataSource.autogeneratedMetrics.selectable = false
        self.dataSource.autogeneratedMetrics.modifyItem = { item in
            let comment = item.entry as! Comment
            let font = UIFont.fontNormal()
            let nameFont = UIFont.lightFontNormal()
            let timeFont = UIFont.lightFontSmall()
            let textHeight = comment.text?.heightWithFont(font, width:Constants.screenWidth - CommentHorizontalSpacing) ?? 0
            item.size = max(72, textHeight + nameFont.lineHeight + timeFont.lineHeight + CommentVerticalSpacing)
        }
        self.dataSource.placeholderMetrics = PlaceholderView.commentsPlaceholderMetrics()
        self.dataSource.didLayoutBlock = { [weak self] _ in
            self?.streamView.setMaximumContentOffsetAnimated(false)
        }
        self.dataSource.items = candy.sortedComments()
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
                enqueueSelector("sendTypingStateChange", delay: 1)
            }
        }
    }
    
    func sendTypingStateChange() {
        if let wrap = candy?.wrap {
            NotificationCenter.defaultCenter.sendTyping(typing, wrap: wrap)
        }
    }
    
    private static let ContstraintOffset: CGFloat = 44
    
    override func keyboardAdjustmentForConstraint(constraint: NSLayoutConstraint, defaultConstant: CGFloat, keyboardHeight: CGFloat) -> CGFloat {
        let offset = CGPointMake(0, keyboardHeight + streamView.contentOffset.y > 0 ?
            view.height - streamView.height + streamView.contentOffset.y - 25.0 : streamView.contentOffset.y)
        streamView.setContentOffset(offset, animated: false)
        return keyboardHeight - CommentsViewController.ContstraintOffset
    }
    
    override func keyboardWillHide(keyboard: Keyboard) {
        super.keyboardWillHide(keyboard)
        keyboard.performAnimation {
            let offset = streamView.contentOffset.y >= streamView.maximumContentOffset.y ?
                streamView.maximumContentOffset.y + 25.0 : streamView.contentOffset.y - view.height + streamView.height
            streamView.setContentOffset(CGPointMake(0, offset), animated: false)
        }
    }
    
    private func sendMessageWithText(text: String) {
        onClose(nil)
        if let candy = candy?.validEntry() {
            Dispatch.mainQueue.async {
                SoundPlayer.player.play(.s04)
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
        enqueueSelector("typingIdled", argument: nil, delay: 3)
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
