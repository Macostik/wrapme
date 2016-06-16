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

class CommentCell: EntryStreamReusableView<Comment>, FlowerMenuConstructor {
    
    internal let name = Label(preset: .Small, weight: .Bold, textColor: UIColor.whiteColor())
    internal let date = Label(preset: .Smaller, weight: .Regular, textColor: Color.grayLighter)
    internal let indicator = EntryStatusIndicator(color: Color.orange)
    
    private let avatar = UserAvatarView(cornerRadius: 24)
    private let text = SmartLabel(preset: .Small, weight: .Regular, textColor: UIColor.whiteColor())
    
    override func layoutWithMetrics(metrics: StreamMetricsProtocol) {
        FlowerMenu.sharedMenu.registerView(self)
        text.numberOfLines = 0
        avatar.placeholder.font = UIFont.icons(24)
        avatar.setBorder()
        addSubview(avatar)
        addSubview(name)
        addSubview(date)
        addSubview(text)
        indicator.setContentCompressionResistancePriority(UILayoutPriorityRequired, forAxis: .Horizontal)
        addSubview(indicator)
        
        avatar.snp_makeConstraints { (make) -> Void in
            make.leading.top.equalTo(self).offset(20)
            make.size.equalTo(48)
        }
        
        date.snp_makeConstraints { (make) -> Void in
            make.leading.equalTo(avatar.snp_trailing).offset(18)
            make.top.equalTo(name.snp_bottom).offset(4)
        }
        
        layout()
    }
    
    internal func layout() {
        
        indicator.snp_makeConstraints { (make) -> Void in
            make.leading.equalTo(date.snp_trailing).offset(10)
            make.centerY.equalTo(date)
        }
        
        text.snp_makeConstraints { (make) -> Void in
            make.leading.equalTo(avatar.snp_trailing).offset(18)
            make.top.equalTo(avatar)
            make.trailing.lessThanOrEqualTo(self).inset(20)
        }
        name.snp_makeConstraints { (make) -> Void in
            make.leading.equalTo(avatar.snp_trailing).offset(18)
            make.top.equalTo(text.snp_bottom).offset(16)
            make.trailing.lessThanOrEqualTo(self).inset(20)
        }
    }
    
    func constructFlowerMenu(menu: FlowerMenu) {
        guard let comment = entry else { return }
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
        if comment.text?.isEmpty == false {
            menu.addCopyAction({ UIPasteboard.generalPasteboard().string = comment.text })
        }
    }
    
    override func setup(comment: Comment) {
        userInteractionEnabled = true
        super.setup(comment)
        avatar.user = comment.contributor
        text.text = comment.displayText()
        comment.markAsUnread(false)
        name.text = comment.contributor?.name
        date.text = comment.createdAt.timeAgoString()
        indicator.updateStatusIndicator(comment)
    }
}

class MediaCommentCell: CommentCell {
    
    private let imageView = ImageView(backgroundColor: UIColor.clearColor())
    private let tip = Label(preset: .XSmall, weight: .Regular, textColor: Color.gray)
    
    override func layoutWithMetrics(metrics: StreamMetricsProtocol) {
        
        imageView.cornerRadius = 10
        imageView.setBorder()
        imageView.clipsToBounds = true
        add(imageView) { (make) -> Void in
            make.trailing.top.equalTo(self).inset(20)
            make.size.equalTo(88)
        }
        tip.insets = 0 ^ 4
        tip.backgroundColor = UIColor(white: 1, alpha: 0.7)
        tip.textAlignment = .Center
        tip.text = "hold_to_view".ls
        imageView.add(tip) { (make) in
            make.leading.bottom.trailing.equalTo(imageView)
        }
        
        imageView.userInteractionEnabled = true
        imageView.addGestureRecognizer(CommentLongPressGesture.gesture({ [weak self] () -> Comment? in
            return self?.entry
            }))
        
        super.layoutWithMetrics(metrics)
    }
    
    internal override func layout() {
        
        indicator.snp_makeConstraints { (make) -> Void in
            make.leading.equalTo(date.snp_trailing).offset(10)
            make.centerY.equalTo(date)
            make.trailing.lessThanOrEqualTo(imageView.snp_leading).inset(-18)
        }
        
        text.snp_makeConstraints { (make) -> Void in
            make.leading.equalTo(avatar.snp_trailing).offset(18)
            make.top.equalTo(avatar)
            make.trailing.lessThanOrEqualTo(imageView.snp_leading).inset(-18)
        }
        name.snp_makeConstraints { (make) -> Void in
            make.leading.equalTo(avatar.snp_trailing).offset(18)
            make.top.equalTo(text.snp_bottom).offset(16)
            make.trailing.lessThanOrEqualTo(imageView.snp_leading).inset(-18)
        }
    }
    
    private var uploadingView: UploadingView? {
        didSet {
            if oldValue?.superview == imageView {
                oldValue?.removeFromSuperview()
            }
            if let uploadingView = uploadingView {
                imageView.layoutIfNeeded()
                uploadingView.frame = imageView.bounds
                imageView.insertSubview(uploadingView, belowSubview: tip)
                uploadingView.update()
            }
        }
    }
    
    weak var playerView: VideoPlayer?
    
    override func willEnqueue() {
        super.willEnqueue()
        playerView?.removeFromSuperview()
    }
    
    override func setup(comment: Comment) {
        super.setup(comment)
        
        if comment.commentType() == .Video {
            let playerView = VideoPlayer.createPlayerView()
            imageView.insertSubview(playerView, atIndex: 0)
            playerView.snp_makeConstraints { (make) in
                make.edges.equalTo(imageView)
            }
            playerView.url = comment.asset?.videoURL()
            self.playerView = playerView
        }
        
        uploadingView = comment.uploadingView
        imageView.url = comment.asset?.small
    }
}

private let CommentVerticalSpacing: CGFloat = 60

final class CommentsDataSource: StreamDataSource<[Comment]> {
    
    var mediaCommentMetrics: StreamMetrics<MediaCommentCell>?
    
    override init() {
        super.init()
        addMetrics(specify(StreamMetrics<CommentCell>(), {
            $0.selectable = false
            $0.modifyItem = { [weak self] item in
                let comment = item.entry as! Comment
                item.size = max(130, self?.heightCell(comment) ?? 0)
                item.hidden = comment.hasMedia
            }
        }))
        
        let mediaCommentMetrics = addMetrics(specify(StreamMetrics<MediaCommentCell>(), {
            $0.selectable = false
            $0.modifyItem = { [weak self] item in
                let comment = item.entry as! Comment
                item.size = max(130, self?.heightCell(comment) ?? 0)
                item.hidden = !comment.hasMedia
            }
        }))
        self.mediaCommentMetrics = mediaCommentMetrics
    }
    
    private func heightCell(comment: Comment) -> CGFloat {
        let font = Font.Small + .Regular
        let nameFont = Font.Small + .Bold
        let timeFont = Font.Smaller + .Regular
        let textHeight = comment.text?.heightWithFont(font, width:Constants.screenWidth - (comment.hasMedia ? 212 : 106)) ?? 0
        return max(textHeight, font.lineHeight) + nameFont.lineHeight + timeFont.lineHeight + CommentVerticalSpacing
    }
    
    override func reload() {
        super.reload()
        playVideoCommentsIfNeeded()
    }
    
    func playVideoCommentsIfNeeded() {
        streamView?.visibleItems().all({
            if $0.metrics === mediaCommentMetrics {
                ($0.view as? MediaCommentCell)?.playerView?.playing = true
            }
        })
    }
    
    override func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        playVideoCommentsIfNeeded()
    }
    
    override func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            playVideoCommentsIfNeeded()
        }
    }
}

final class CommentsViewController: BaseViewController, CaptureCommentViewControllerDelegate {
    
    static weak var current: CommentsViewController?
    
    weak var candy: Candy?
    
    let streamView = StreamView()
    
    private lazy var dataSource: CommentsDataSource = CommentsDataSource(streamView: self.streamView)
    
    private let composeBar = ComposeBar()
    
    private var contentView = UIView()
    weak var historyViewController: HistoryViewController?
    
    private var candyNotifyReceiver: EntryNotifyReceiver<Candy>?
    
    private var commentNotifyReceiver: EntryNotifyReceiver<Comment>?
    private let topView = UIView()
    private let bottomView = UIView()
    private let cameraButton = Button(icon: "u", size: 24, textColor: Color.orange)
    let closeButton = Button(icon: "!", size: 15, textColor: Color.orange)
    
    private let userStatusView = specify(StatusUserAvatarView(backgroundColor: UIColor.clearColor())) {
        $0.applyPlaceholder(ImageView.Placeholder.gray)
        $0.cornerRadius = 22
        $0.setBorder()
    }
    
    private var userNotifyReceiver: EntryNotifyReceiver<User>?
    
    deinit {
        streamView.layer.removeObserver(self, forKeyPath: "bounds", context: nil)
    }
    
    override func loadView() {
        let view = UIView(frame: self.preferredViewFrame)
        self.view = view
        view.backgroundColor = UIColor(white: 0, alpha: 0.7)
        view.add(contentView) { (make) in
            make.edges.equalTo(view)
        }
        contentView.add(topView) { (make) in
            make.leading.trailing.equalTo(self.contentView)
            make.top.equalTo(self.contentView)
        }
        topView.add(closeButton) { (make) in
            make.centerY.equalTo(topView)
            make.trailing.equalTo(topView).inset(5)
        }
        
        closeButton.setTitleColor(Color.orangeDark, forState: .Highlighted)
        closeButton.addTarget(self, touchUpInside: #selector(self.onClose(_:)))
        
        userStatusView.hidden = true
        topView.add(userStatusView) {
            $0.size.equalTo(44)
            $0.leading.top.bottom.equalTo(topView).inset(20)
        }
        
        let commentsLabel = Label(preset: .Large, weight: .Regular, textColor: UIColor.whiteColor())
        commentsLabel.text = "comments".ls
        topView.add(commentsLabel) { (make) in
            make.center.equalTo(topView)
        }
        
        let separator = SeparatorView(color: UIColor(white: 1, alpha: 0.5))
        separator.contentMode = .Bottom
        topView.add(separator) { (make) in
            make.leading.bottom.trailing.equalTo(topView)
            make.height.equalTo(1)
        }
        contentView.insertSubview(streamView, atIndex: 0)
        streamView.snp_makeConstraints { (make) in
            make.leading.trailing.equalTo(contentView)
            make.top.equalTo(topView.snp_bottom)
        }
        bottomView.backgroundColor = UIColor(white: 0, alpha: 0.7)
        contentView.add(bottomView) { (make) in
            make.leading.trailing.bottom.equalTo(contentView)
            make.top.equalTo(streamView.snp_bottom)
        }
        
        cameraButton.setTitleColor(Color.orangeDark, forState: .Highlighted)
        cameraButton.addTarget(self, touchUpInside: #selector(self.cameraAction(_:)))
        showComposeBar()
        
        composeBar.animatesDoneButton = false
        composeBar.delegate = self
        composeBar.textView.placeholder = "comment_placeholder".ls
        streamView.indicatorStyle = .White
        streamView.alwaysBounceVertical = true
        
        streamView.tapped { [weak self] (_) in
            self?.handleTap()
        }
    }
    
    override func requestPresentingPermission(completion: BooleanBlock) {
        if let camera = camera {
            camera.requestPresentingPermission(completion)
        } else {
            completion(true)
        }
    }
    
    func handleTap() -> Bool {
        
        if composeBar.superview == nil {
            
            if let camera = camera {
                camera.requestPresentingPermission({ [weak self] allow in
                    if allow {
                        self?.camera?.removeFromContainerAnimated(false)
                        self?.showComposeBar()
                    }
                    })
            } else {
                showComposeBar()
            }
            
            return false
        } else if composeBar.isFirstResponder() == true {
            composeBar.resignFirstResponder()
            return false
        } else {
            return true
        }
    }
    
    var disableDismissingByScroll = false
    
    private func showComposeBar() {
        disableDismissingByScroll = false
        if composeBar.superview != bottomView {
            bottomView.subviews.all({ $0.removeFromSuperview() })
            bottomView.add(composeBar) { (make) in
                make.edges.equalTo(bottomView)
            }
            bottomView.add(cameraButton) { (make) in
                make.trailing.top.bottom.equalTo(bottomView)
                make.width.equalTo(48)
            }
        }
    }
    
    private weak var camera: CaptureCommentViewController?
    
    func showCamera() {
        let camera = CaptureViewController.captureCommentViewController()
        camera.cameraViewController?.preferredViewFrame = 0 ^ 0 ^ (view.width ^ view.width)
        camera.captureDelegate = self
        disableDismissingByScroll = true
        bottomView.subviews.all({ $0.removeFromSuperview() })
        addChildViewController(camera)
        bottomView.addSubview(camera.view)
        camera.view.snp_makeConstraints { (make) in
            make.edges.equalTo(bottomView)
            make.height.equalTo(camera.view.width)
        }
        camera.didMoveToParentViewController(self)
        view.layoutIfNeeded()
        self.camera = camera
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        streamView.layer.addObserver(self, forKeyPath: "bounds", options: .New, context: nil)
        streamView.panGestureRecognizer.addTarget(self, action: #selector(self.panned(_:)))
        
        guard let candy = candy?.validEntry() else { return }
        
        candy.comments.all({ $0.markAsUnread(false) })
        
        streamView.placeholderViewBlock = PlaceholderView.commentsPlaceholder()
        dataSource.items = candy.sortedComments()
        
        if candy.uploaded {
            candy.fetch({ [weak self] _ in
                let comments = candy.sortedComments()
                let autoScroll = self?.dataSource.items?.count != comments.count
                self?.dataSource.items = comments
                if autoScroll {
                    self?.streamView.setMaximumContentOffsetAnimated(false)
                }
                
                }, failure: { [weak self] (error) -> Void in
                    self?.dataSource.reload()
                    error?.showNonNetworkError()
                })
        }
        
        addNotifyReceivers()
        composeBar.text = candy.typedComment
        cameraButton.hidden = composeBar.text?.isEmpty == false
        
        if let wrap = candy.wrap {
            updateUserStatus(wrap)
            userNotifyReceiver = EntryNotifyReceiver<User>().setup({ [weak self] (receiver) in
                receiver.didUpdate = { user, event in
                    if wrap.contributors.contains(user) && event == .UserStatus {
                        self?.updateUserStatus(wrap)
                    }
                }
                })
        }
        
        Keyboard.keyboard.handle(self, willShow: { [unowned self] (keyboard) in
            self.streamView.keepContentOffset {
                keyboard.performAnimation({ () in
                    if self.camera == nil {
                        self.contentView.snp_remakeConstraints(closure: { (make) in
                            make.leading.top.trailing.equalTo(self.view)
                            make.bottom.equalTo(self.view).inset(keyboard.height)
                        })
                    } else {
                        self.contentView.snp_remakeConstraints(closure: { (make) in
                            make.size.equalTo(self.view)
                            make.centerX.equalTo(self.view)
                            make.bottom.equalTo(self.view).offset(-self.topView.height)
                        })
                    }
                    self.contentView.layoutIfNeeded()
                })
            }
            }) { [unowned self] (keyboard) in
                self.streamView.keepContentOffset {
                    keyboard.performAnimation({ () in
                        self.contentView.snp_remakeConstraints(closure: { (make) in
                            make.edges.equalTo(self.view)
                        })
                        self.contentView.layoutIfNeeded()
                    })
                }
        }
    }
    
    private weak var mediaCommentHint: UIView?
    
    private func showMediaCommentHintIfNeeded() {
        
        let showCount = NSUserDefaults.standardUserDefaults()["mediaCommentHintShowCount"] as? Int ?? 0
        guard showCount < 10 else { return }
        NSUserDefaults.standardUserDefaults()["mediaCommentHintShowCount"] = showCount + 1
        
        composeBar.clipsToBounds = false
        let tipView = self.composeBar.add(UIView()) { (make) in
            make.trailing.equalTo(self.composeBar).offset(-6)
            make.bottom.equalTo(cameraButton.snp_top)
        }
        
        let contentView = tipView.add(UIView()) { (make) in
            make.leading.top.trailing.equalTo(tipView)
        }
        contentView.cornerRadius = 4
        contentView.clipsToBounds = true
        contentView.backgroundColor = Color.orange.colorWithAlphaComponent(0.8)
        let label = Label(preset: .Smaller, weight: .Regular, textColor: UIColor.whiteColor())
        label.text = "media_comment_hint".ls
        let triangle = TriangleView()
        triangle.backgroundColor = contentView.backgroundColor
        triangle.contentMode = .Bottom
        
        tipView.add(triangle) { (make) in
            make.top.equalTo(contentView.snp_bottom)
            make.bottom.equalTo(tipView)
            make.size.equalTo(CGSize(width: 20, height: 10))
            make.centerX.equalTo(cameraButton)
        }
        
        contentView.add(label) { (make) in
            make.edges.equalTo(contentView).inset(10)
        }
        
        mediaCommentHint = tipView
        hideMediaCommentHintIfNeeded(4)
    }
    
    private func hideMediaCommentHintIfNeeded(delay: Float = 0) {
        if let mediaCommentHint = mediaCommentHint {
            Dispatch.mainQueue.after(delay, block: { [weak mediaCommentHint] () in
                self.mediaCommentHint = nil
                UIView.animateWithDuration(0.3, animations: { _ in
                    mediaCommentHint?.alpha = 0
                    }, completion: { (_) in
                        mediaCommentHint?.removeFromSuperview()
                    })
            })
            
        }
    }
    
    private func updateUserStatus(wrap: Wrap) {
        let activeContributors = wrap.contributors.filter({ $0.activityForWrap(wrap) != nil })
        userStatusView.hidden = activeContributors.isEmpty
        userStatusView.wrap = wrap
        userStatusView.user = activeContributors.sort({ $0.activeAt > $1.activeAt }).first
    }
    
    func panned(sender: UIPanGestureRecognizer) {
        if sender.state == .Ended && scrollingOffset != 0 && !disableDismissingByScroll {
            let velocity = sender.velocityInView(sender.view)
            if abs(scrollingOffset) > streamView.height/4 || abs(velocity.y) > 1200 {
                let snapshot = contentView.snapshotViewAfterScreenUpdates(false)
                snapshot.frame = contentView.frame
                contentView.hidden = true
                view.addSubview(snapshot)
                contentView = snapshot
                close(true, up: self.scrollingOffset > 0)
            }
        }
    }
    
    var scrollingOffset: CGFloat = 0 {
        willSet {
            guard newValue != scrollingOffset else { return }
            if newValue == 0 {
                topView.transform = CGAffineTransformIdentity
                bottomView.transform = CGAffineTransformIdentity
                view.backgroundColor = UIColor(white: 0, alpha: 0.7)
            } else {
                (newValue < 0 ? topView : bottomView).transform = CGAffineTransformMakeTranslation(0, -newValue)
                (newValue < 0 ? bottomView : topView).transform = CGAffineTransformIdentity
                let value = smoothstep(0.0, 1.0, 1 - abs(newValue) / (contentView.height / 2))
                view.backgroundColor = UIColor(white: 0, alpha: 0.7 * value)
            }
        }
    }
    
    private func scrollingOffsetChanged() -> CGFloat {
        let offset = streamView.contentOffset.y
        return offset < 0 ? offset : max(0, offset - streamView.maximumContentOffset.y)
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if streamView.superview == contentView && !disableDismissingByScroll {
            scrollingOffset = scrollingOffsetChanged()
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        streamView.setMaximumContentOffsetAnimated(false)
    }
    
    var isEndingOfScroll: Bool {
        return abs(streamView.contentOffset.y - streamView.maximumContentOffset.y) <= 5
    }
    
    var isMaxContentOffset: Bool = false
    
    private func addNotifyReceivers() {
        commentNotifyReceiver = EntryNotifyReceiver<Comment>().setup { [weak self] receiver in
            receiver.container = { return self?.candy }
            
            receiver.willDelete = { entry in
                var comments = self?.dataSource.items
                comments?.remove(entry)
                self?.dataSource.items = comments
            }
            receiver.didAdd = { entry in
                self?.isMaxContentOffset = false
                let isEndingOfScroll = self?.isEndingOfScroll ?? false
                self?.dataSource.items = self?.candy?.sortedComments()
                if isEndingOfScroll {
                    self?.streamView.setMaximumContentOffsetAnimated(true)
                    self?.isMaxContentOffset = true
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
    
    var typing = false {
        didSet {
            if typing != oldValue {
                enqueueSelector(#selector(self.sendTypingStateChange), delay: 1)
            }
        }
    }
    
    func sendTypingStateChange() {
        if let wrap = candy?.wrap {
            NotificationCenter.defaultCenter.sendTyping(typing, wrap: wrap)
        }
    }
    
    private func sendComment(@noescape block: Comment -> ()) {
        if let candy = candy?.validEntry() {
            Sound.play()
            let comment: Comment = insertContribution()
            block(comment)
            candy.uploadComment(comment)
            self.streamView.setMaximumContentOffsetAnimated(true)
        }
    }
    
    func presentForController(controller: HistoryViewController, animated: Bool) {
        historyViewController = controller
        controller.addContainedViewController(self, animated:false)
        let backgroundColor = view.backgroundColor
        view.backgroundColor = UIColor.clearColor()
        contentView.transform = CGAffineTransformMakeTranslation(0, view.height)
        animate(animated) {
            view.backgroundColor = backgroundColor
            contentView.transform = CGAffineTransformIdentity
        }
    }
    
    func close(animated: Bool = false, up: Bool = false) {
        typing = false
        composeBar.resignFirstResponder()
        if animated {
            UIView.animateWithDuration(0.5, animations: {
                self.view.backgroundColor = UIColor.clearColor()
                self.contentView.transform = CGAffineTransformMakeTranslation(0, up ? -self.view.height : self.view.height)
            }) { (_) in
                self.removeFromContainerAnimated(true)
                CommentsViewController.current = nil
            }
        } else {
            removeFromContainerAnimated(true)
            CommentsViewController.current = nil
        }
        historyViewController?.setBarsHidden(false, animated: animated)
        historyViewController?.commentButton.hidden = false
    }
    
    @IBAction func onClose(sender: AnyObject?) {
        if let camera = camera {
            camera.requestPresentingPermission({ [weak self] allow in
                if allow {
                    self?.camera?.removeFromContainerAnimated(false)
                    self?.showComposeBar()
                }
                })
        } else {
            close(true)
        }
    }
    
    @IBAction func cameraAction(sender: AnyObject?) {
        mediaCommentHint?.removeFromSuperview()
        showCamera()
    }
    
    func captureViewController(controller: CaptureCommentViewController, didFinishWithAsset asset: MutableAsset) {
        camera?.removeFromContainerAnimated(false)
        showComposeBar()
        view.layoutIfNeeded()
        sendComment { (comment) in
            comment.text = asset.comment
            comment.asset = asset.uploadableAsset()
        }
    }
    
    func captureViewControllerDidCancel(controller: CaptureCommentViewController) {
        camera?.removeFromContainerAnimated(false)
        showComposeBar()
        view.layoutIfNeeded()
    }
}

extension CommentsViewController: ComposeBarDelegate {
    
    func composeBar(composeBar: ComposeBar, didFinishWithText text: String) {
        typing = false
        composeBar.text = nil
        cameraButton.hidden = false
        contentView.layoutIfNeeded()
        sendComment { (comment) in
            comment.text = text
        }
        candy?.typedComment = nil
    }
    
    func composeBarDidBeginEditing(composeBar: ComposeBar) {
        showMediaCommentHintIfNeeded()
    }
    
    func composeBarDidEndEditing(composeBar: ComposeBar) {
        hideMediaCommentHintIfNeeded()
    }
    
    func composeBarDidChangeText(composeBar: ComposeBar) {
        hideMediaCommentHintIfNeeded()
        candy?.typedComment = composeBar.text
        typing = composeBar.text?.isEmpty == false
        cameraButton.hidden = composeBar.text?.isEmpty == false
        enqueueSelector(#selector(self.typingIdled), argument: nil, delay: 3)
    }
    
    func typingIdled() {
        typing = false
    }
}
