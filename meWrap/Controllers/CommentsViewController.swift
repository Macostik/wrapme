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

class CommentCell: EntryStreamReusableView<Comment> {
    
    internal let name = Label(preset: .Small, weight: .Bold, textColor: UIColor.whiteColor())
    internal let date = Label(preset: .Smaller, weight: .Regular, textColor: Color.grayLighter)
    internal let indicator = EntryStatusIndicator(color: Color.orange)
    
    override func setup(comment: Comment) {
        comment.markAsUnread(false)
        name.text = comment.contributor?.name
        date.text = comment.createdAt.timeAgoString()
        indicator.updateStatusIndicator(comment)
    }
}

final class TextCommentCell: CommentCell, FlowerMenuConstructor {
    
    private let avatar = UserAvatarView(cornerRadius: 24)
    private let text = SmartLabel(preset: .Small, weight: .Regular, textColor: UIColor.whiteColor())
    
    override func layoutWithMetrics(metrics: StreamMetricsProtocol) {
        FlowerMenu.sharedMenu.registerView(self)
        text.numberOfLines = 0
        avatar.defaultIconSize = 24
        avatar.borderColor = UIColor.whiteColor()
        avatar.borderWidth = 1
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
            make.leading.equalTo(date.snp_trailing).offset(10)
            make.centerY.equalTo(date)
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
        menu.addCopyAction({ UIPasteboard.generalPasteboard().string = comment.text })
    }
    
    override func setup(comment: Comment) {
        userInteractionEnabled = true
        super.setup(comment)
        avatar.user = comment.contributor
        text.text = comment.text
    }
}

class MediaCommentCell: CommentCell {
    
    var mediaView: UIView!
    
    override func layoutWithMetrics(metrics: StreamMetricsProtocol) {
        mediaView.cornerRadius = 45
        mediaView.borderColor = UIColor.whiteColor()
        mediaView.borderWidth = 1
        mediaView.clipsToBounds = true
        addSubview(mediaView)
        addSubview(name)
        addSubview(date)
        addSubview(indicator)
        
        mediaView.snp_makeConstraints { (make) -> Void in
            make.leading.top.equalTo(self).offset(20)
            make.size.equalTo(90)
        }
        name.snp_makeConstraints { (make) -> Void in
            make.leading.equalTo(mediaView.snp_trailing).offset(18)
            make.bottom.equalTo(mediaView.snp_centerY).offset(-2)
            make.trailing.lessThanOrEqualTo(self).inset(18)
        }
        
        date.snp_makeConstraints { (make) -> Void in
            make.leading.equalTo(mediaView.snp_trailing).offset(18)
            make.top.equalTo(mediaView.snp_centerY).offset(2)
        }
        
        indicator.snp_makeConstraints { (make) -> Void in
            make.leading.equalTo(date.snp_trailing).offset(10)
            make.centerY.equalTo(date)
        }
        addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(self.longPress(_:))))
    }
    
    private weak var commentViewController: CommentViewController?
    
    @objc private func longPress(sender: UILongPressGestureRecognizer) {
        if sender.state == .Began {
            let controller = CommentViewController()
            controller.comment = entry
            controller.modalPresentationStyle = .OverCurrentContext
            UINavigationController.main.presentViewController(controller, animated: false, completion: nil)
            commentViewController = controller
        } else if sender.state == .Ended || sender.state == .Cancelled {
            if let comment = entry where commentViewController?.actionWith(sender) == .Delete {
                UINavigationController.main.dismissViewControllerAnimated(false, completion: nil)
                Dispatch.mainQueue.after(0.2) { [weak self] () in
                    UIAlertController.confirmCommentDeleting({  _ in
                        self?.userInteractionEnabled = false
                        comment.delete ({ (_) -> Void in
                            self?.userInteractionEnabled = true
                            }, failure: { [weak self] (error) in
                                error?.show()
                                self?.userInteractionEnabled = true
                            })
                        }, failure: nil)
                }
            } else {
                UINavigationController.main.dismissViewControllerAnimated(false, completion: nil)
            }
        }
    }
    
    private var uploadingView: UploadingView? {
        didSet {
            if oldValue?.superview == mediaView {
                oldValue?.removeFromSuperview()
            }
            if let uploadingView = uploadingView {
                mediaView.layoutIfNeeded()
                uploadingView.frame = mediaView.bounds
                mediaView.addSubview(uploadingView)
                uploadingView.update()
            }
        }
    }
}

final class PhotoCommentCell: MediaCommentCell {
    private let imageView = ImageView(backgroundColor: UIColor.clearColor())
    
    override func layoutWithMetrics(metrics: StreamMetricsProtocol) {
        mediaView = imageView
        imageView.defaultIconSize = 24
        super.layoutWithMetrics(metrics)
    }
    
    override func setup(comment: Comment) {
        super.setup(comment)
        imageView.url = comment.asset?.small
        uploadingView = comment.uploadingView
    }
}

final class VideoCommentCell: MediaCommentCell {
    private let imageView = ImageView(backgroundColor: UIColor.clearColor())
    weak var playerView: VideoPlayer?
    
    override func layoutWithMetrics(metrics: StreamMetricsProtocol) {
        mediaView = imageView
        super.layoutWithMetrics(metrics)
    }
    
    override func willEnqueue() {
        super.willEnqueue()
        playerView?.removeFromSuperview()
    }
    
    override func setup(comment: Comment) {
        super.setup(comment)
        let playerView = CommentViewController.createPlayerView()
        imageView.insertSubview(playerView, atIndex: 0)
        playerView.snp_makeConstraints { (make) in
            make.edges.equalTo(imageView)
        }
        playerView.url = comment.asset?.videoURL()
        self.playerView = playerView
        uploadingView = comment.uploadingView
        imageView.url = comment.asset?.small
    }
}

private let CommentEstimateWidth: CGFloat = Constants.screenWidth - 104
private let CommentVerticalSpacing: CGFloat = 60

final class CommentsDataSource: StreamDataSource<[Comment]> {
    
    let videoCommentMetrics = specify(StreamMetrics<VideoCommentCell>(), {
        $0.selectable = false
        $0.size = 130
        $0.modifyItem = { item in
            let comment = item.entry as! Comment
            item.hidden = comment.commentType() != .Video
        }
    })
    
    override init() {
        super.init()
        addMetrics(specify(StreamMetrics<TextCommentCell>(), {
            $0.selectable = false
            $0.modifyItem = { [weak self] item in
                let comment = item.entry as! Comment
                item.size = self?.heightCell(comment) ?? 0
                item.hidden = comment.commentType() != .Text
            }
        }))
        
        addMetrics(specify(StreamMetrics<PhotoCommentCell>(), {
            $0.selectable = false
            $0.size = 130
            $0.modifyItem = { item in
                let comment = item.entry as! Comment
                item.hidden = comment.commentType() != .Photo
            }
        }))
        
        addMetrics(videoCommentMetrics)
    }
    
    private func heightCell(comment: Comment) -> CGFloat {
        let font = Font.Small + .Regular
        let nameFont = Font.Small + .Bold
        let timeFont = Font.Smaller + .Regular
        let textHeight = comment.text?.heightWithFont(font, width:CommentEstimateWidth) ?? 0
        return max(textHeight, font.lineHeight) + nameFont.lineHeight + timeFont.lineHeight + CommentVerticalSpacing
    }
    
    override func reload() {
        super.reload()
        playVideoCommentsIfNeeded()
    }
    
    func playVideoCommentsIfNeeded() {
        streamView?.visibleItems().all({
            if $0.metrics === videoCommentMetrics {
                ($0.view as? VideoCommentCell)?.playerView?.playing = true
            }
        })
    }
    
    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        playVideoCommentsIfNeeded()
    }
    
    func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            playVideoCommentsIfNeeded()
        }
    }
}

final class CommentsViewController: BaseViewController, CaptureCommentViewControllerDelegate {
    
    weak var candy: Candy?
    
    let streamView = StreamView()
    private let friendsStreamView = StreamView()
    
    private lazy var friendsDataSource: StreamDataSource<[User]> = StreamDataSource(streamView: self.friendsStreamView)
    
    private lazy var dataSource: CommentsDataSource = CommentsDataSource(streamView: self.streamView)
    
    private let composeBar = ComposeBar()
    
    private var contentView = UIView()
    weak var historyViewController: HistoryViewController?
    
    private var candyNotifyReceiver: EntryNotifyReceiver<Candy>?
    
    private var commentNotifyReceiver: EntryNotifyReceiver<Comment>?
    private let topView = UIView()
    private let bottomView = UIView()
    private let cameraButton = Button(icon: "u", size: 24, textColor: Color.orange)
    
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
            make.leading.trailing.top.equalTo(contentView)
        }
        topView.add(friendsStreamView) { (make) in
            make.edges.equalTo(topView)
        }
        let closeButton = Button(icon: "!", size: 15, textColor: Color.orange)
        closeButton.setTitleColor(Color.orangeDark, forState: .Highlighted)
        closeButton.addTarget(self, touchUpInside: #selector(self.onClose(_:)))
        topView.add(closeButton) { (make) in
            make.top.trailing.bottom.equalTo(topView).inset(5)
        }
        contentView.add(streamView) { (make) in
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
        
        composeBar.delegate = self
        composeBar.textView.placeholder = "comment_placeholder".ls
        streamView.indicatorStyle = .White
        streamView.alwaysBounceVertical = true
        
        keyboardBottomGuideView = contentView
    }
    
    var disableDismissingByScroll = false
    
    private func showComposeBar() {
        disableDismissingByScroll = false
        bottomView.subviews.all({ $0.removeFromSuperview() })
        bottomView.add(composeBar) { (make) in
            make.leading.top.bottom.equalTo(bottomView)
        }
        bottomView.add(cameraButton) { (make) in
            make.trailing.top.bottom.equalTo(bottomView)
            make.leading.equalTo(composeBar.snp_trailing)
            make.width.equalTo(44)
        }
    }
    
    func showCamera() {
        let camera = CaptureViewController.captureCommentViewController()
        camera.captureDelegate = self
        if UIApplication.sharedApplication().statusBarOrientation.isPortrait {
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
        } else {
            UINavigationController.main.presentViewController(camera, animated: false, completion: nil)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        streamView.layer.addObserver(self, forKeyPath: "bounds", options: .New, context: nil)
        streamView.panGestureRecognizer.addTarget(self, action: #selector(self.panned(_:)))
        
        guard let candy = candy?.validEntry() else { return }
        
        candy.comments.all({ $0.markAsUnread(false) })
        
        dataSource.placeholderMetrics = PlaceholderView.commentsPlaceholderMetrics()
        dataSource.items = candy.sortedComments()
        
        friendsStreamView.layout = HorizontalStreamLayout()
        let friendMetrics = StreamMetrics<FriendView>(size: friendsStreamView.height)
        friendMetrics.prepareAppearing = { [weak self] item, view in
            view.wrap = self?.candy?.wrap
        }
        friendsDataSource.addMetrics(friendMetrics)
        
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
        friendsDataSource.items = activeContibutors
        
        addNotifyReceivers()
        DeviceManager.defaultManager.addReceiver(self)
		User.notifier().addReceiver(self)
        composeBar.text = candy.typedComment
    }
    
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        if childViewControllers.count > 0 {
            return [.Portrait, .PortraitUpsideDown]
        } else {
            return .All
        }
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

 	var activeContibutors: [User] {
        guard let wrap = candy?.wrap else { return [] }
        return wrap.contributors.filter({ $0.activityForWrap(wrap) != nil }).sort({ $0.name < $1.name })
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
    
    override func requestAuthorizationForPresentingEntry(entry: Entry, completion: BooleanBlock) {
        completion((entry as? Comment)?.candy != candy)
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
    
    private func sendMessageWithText(text: String) {
        close(true)
        if let candy = candy?.validEntry() {
            Dispatch.mainQueue.async {
                Sound.play()
                candy.uploadComment(text.trim)
                candy.typedComment = nil
            }
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
                self.historyViewController?.commentsViewController = nil
            }
        } else {
            removeFromContainerAnimated(true)
            self.historyViewController?.commentsViewController = nil
        }
        historyViewController?.setBarsHidden(false, animated: animated)
    }
    
    @IBAction func onClose(sender: AnyObject?) {
        close(true)
    }
    
    @IBAction func cameraAction(sender: AnyObject?) {
        showCamera()
    }
    
    func captureViewController(controller: CaptureCommentViewController, didFinishWithAsset asset: MutableAsset) {
        if let presenter = controller.presentingViewController {
            presenter.dismissViewControllerAnimated(false, completion: nil)
        }
        close(true)
        if let candy = candy?.validEntry() {
            Sound.play()
            let comment: Comment = Comment.contribution()
            comment.asset = asset.uploadableAsset()
            candy.commentCount += 1
            comment.candy = candy
            Uploader.commentUploader.upload(Uploading.uploading(comment))
            comment.notifyOnAddition()
        }
    }
    
    func captureViewControllerDidCancel(controller: CaptureCommentViewController) {
        if let presenter = controller.presentingViewController {
            presenter.dismissViewControllerAnimated(false, completion: nil)
        } else {
            controller.removeFromContainerAnimated(false)
            showComposeBar()
            view.layoutIfNeeded()
        }
    }
}

extension CommentsViewController: ComposeBarDelegate {
    
    func composeBar(composeBar: ComposeBar, didFinishWithText text: String) {
        typing = false
        sendMessageWithText(text)
    }
    
    func composeBarDidChangeText(composeBar: ComposeBar) {
        candy?.typedComment = composeBar.text
        typing = composeBar.text?.isEmpty == false
        enqueueSelector(#selector(self.typingIdled), argument: nil, delay: 3)
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
        if event == .UserStatus {
            friendsDataSource.items = activeContibutors
        }
    }
}