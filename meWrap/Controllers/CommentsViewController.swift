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
    
    private let avatar = StatusUserAvatarView(cornerRadius: 24)
    private let name = Label(preset: .Small, weight: .Bold, textColor: UIColor.whiteColor())
    private let date = Label(preset: .Smaller, weight: .Regular, textColor: Color.grayLighter)
    private let text = SmartLabel(preset: .Small, weight: .Regular, textColor: UIColor.whiteColor())
    private let indicator = EntryStatusIndicator(color: Color.orange)
    
    override func layoutWithMetrics(metrics: StreamMetrics) {
        avatar.startReceivingStatusUpdates()
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
        avatar.wrap = comment.candy?.wrap
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
    
    private lazy var dataSource: StreamDataSource<[Comment]> = StreamDataSource(streamView: self.streamView)
    
    @IBOutlet weak var composeBar: ComposeBar!
    
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
            $0.modifyItem = { [weak self] item in
                let comment = item.entry as! Comment
                item.size = self?.heightCell(comment) ?? 0
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
        EntryToast.entryToast.handleTouch = { [weak self] _ in
            self?.view.layoutIfNeeded()
            self?.streamView.setMaximumContentOffsetAnimated(true)
        }
        
        composeBar.text = candy.typedComment
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        streamView.layoutIfNeeded()
        streamView.setMaximumContentOffsetAnimated(false)
    }
    
    var isEndingOfScroll = false
    
    private func addNotifyReceivers() {
        commentNotifyReceiver = EntryNotifyReceiver<Comment>().setup { [weak self] receiver in
            receiver.container = { return self?.candy }
            
            receiver.willDelete = { entry in
                var comments = self?.dataSource.items
                if let index = comments?.indexOf(entry) {
                    comments?.removeAtIndex(index)
                }
                self?.dataSource.items = comments
            }
            receiver.didAdd = { entry in
                self?.isEndingOfScroll = false
                self?.dataSource.items = self?.candy?.sortedComments()
                let offset = (self?.streamView.maximumContentOffset.y ?? 0) - (self?.streamView.contentOffset.y ?? 0) - (self?.heightCell(entry) ?? 0)
                if offset <= 5 {
                    self?.streamView.setMaximumContentOffsetAnimated(true)
                    self?.isEndingOfScroll = true
                }
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
    
    private func heightCell(comment: Comment) -> CGFloat {
        let font = Font.Small + .Regular
        let nameFont = Font.Small + .Bold
        let timeFont = Font.Smaller + .Regular
        let textHeight = comment.text?.heightWithFont(font, width:CommentEstimateWidth) ?? 0
        return max(textHeight, font.lineHeight) + nameFont.lineHeight + timeFont.lineHeight + CommentVerticalSpacing
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
    
    override func keyboardWillShow(keyboard: Keyboard) {
        super.keyboardWillShow(keyboard)
        streamView.setMaximumContentOffsetAnimated(true)
    }
    
    private func sendMessageWithText(text: String) {
        onClose(nil)
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
    }
    
    @IBAction func onClose(sender: AnyObject?) {
        typing = false
        view.endEditing(true)
        removeFromContainerAnimated(true)
        historyViewController?.setBarsHidden(false, animated: true)
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

extension CommentsViewController: UIScrollViewDelegate {
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        let direction = scrollView.panGestureRecognizer.translationInView(scrollView.superview).y < 0
        composeBarBottomPrioritizer.defaultState = direction
    }
    
    func scrollViewWillEndDragging(scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        let offset = scrollView.contentOffset.y
        if abs(offset) > scrollView.height/5 || abs(velocity.y) > 2 {
            let snapshot = contentView.snapshotViewAfterScreenUpdates(false)
            snapshot.frame = contentView.frame
            contentView.hidden = true
            view.addSubview(snapshot)
            typing = false
            UIView.animateWithDuration(0.5, animations: {
                let offsetY = offset > 0 ? -self.view.height : self.view.height
                snapshot.transform = CGAffineTransformMakeTranslation(0, offsetY)
                self.historyViewController?.setBarsHidden(false, animated: true)
                self.view.backgroundColor = UIColor.clearColor()
                }, completion: { _ in
                    self.removeFromContainerAnimated(true)
            })
        }
    }
}
