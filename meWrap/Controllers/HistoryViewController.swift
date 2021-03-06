//
//  HistoryViewController+Ext.swift
//  meWrap
//
//  Created by Sergey Maximenko on 1/31/16.
//  Copyright © 2016 Ravenpod. All rights reserved.
//

import Foundation
import Photos
import SnapKit

final class CommentView: UIView {
    
    private let avatar = UserAvatarView(cornerRadius: 24)
    private let name = Label(preset: .Small, weight: .Bold, textColor: UIColor.whiteColor())
    private let date = Label(preset: .Smaller, weight: .Regular, textColor: Color.grayLighter)
    private let text = Label(preset: .Small, weight: .Regular, textColor: UIColor.whiteColor())
    private let indicator = EntryStatusIndicator(color: Color.orange)
    
    private let imageView = ImageView(backgroundColor: UIColor.clearColor())
    private let tip = Label(preset: .XSmall, weight: .Regular, textColor: Color.gray)
    
    weak var videoPlayer: VideoPlayer?
    
    func layout() {
        text.numberOfLines = 2
        avatar.setBorder()
        avatar.placeholder.font = UIFont.icons(24)
        imageView.cornerRadius = 10
        imageView.setBorder()
        imageView.clipsToBounds = true
        snp_makeConstraints { (make) in
            make.height.equalTo(0)
        }
        tip.insets = 0 ^ 4
        tip.backgroundColor = UIColor(white: 1, alpha: 0.7)
        tip.textAlignment = .Center
        tip.text = "hold_to_view".ls
        imageView.add(tip) { (make) in
            make.leading.bottom.trailing.equalTo(imageView)
        }
        imageView.userInteractionEnabled = true
        imageView.addGestureRecognizer(CommentLongPressGesture.gesture({ [weak self] _ in
            return self?.comment
            }))
        indicator.setContentCompressionResistancePriority(UILayoutPriorityRequired, forAxis: .Horizontal)
    }
    
    private func layoutFor(commentType: CommentType) {
        
        if commentType == .Text {
            add(avatar) { (make) -> Void in
                make.leading.top.equalTo(self).offset(20)
                make.size.equalTo(48)
            }
            add(text) { (make) -> Void in
                make.leading.equalTo(avatar.snp_trailing).offset(18)
                make.top.equalTo(avatar)
                make.trailing.lessThanOrEqualTo(self).inset(20)
            }
            add(name) { (make) -> Void in
                make.leading.equalTo(avatar.snp_trailing).offset(18)
                make.top.equalTo(avatar.snp_bottom).offset(5)
                make.trailing.lessThanOrEqualTo(self).inset(20)
            }
            
            add(date) { (make) -> Void in
                make.leading.equalTo(avatar.snp_trailing).offset(18)
                make.top.equalTo(name.snp_bottom).offset(4)
            }
            
            add(indicator) { (make) -> Void in
                make.leading.equalTo(date.snp_trailing).offset(10)
                make.centerY.equalTo(date)
            }
            
        } else {
            
            add(imageView) { (make) -> Void in
                make.trailing.top.equalTo(self).inset(20)
                make.size.equalTo(88)
            }
            
            add(avatar) { (make) -> Void in
                make.leading.top.equalTo(self).offset(20)
                make.size.equalTo(48)
            }
            add(text) { (make) -> Void in
                make.leading.equalTo(avatar.snp_trailing).offset(18)
                make.top.equalTo(avatar)
                make.trailing.lessThanOrEqualTo(imageView.snp_leading).inset(-18)
            }
            add(name) { (make) -> Void in
                make.leading.equalTo(avatar.snp_trailing).offset(18)
                make.top.equalTo(avatar.snp_bottom).offset(5)
                make.trailing.lessThanOrEqualTo(imageView.snp_leading).inset(-18)
            }
            
            add(date) { (make) -> Void in
                make.leading.equalTo(avatar.snp_trailing).offset(18)
                make.top.equalTo(name.snp_bottom).offset(4)
            }
            
            add(indicator) { (make) -> Void in
                make.leading.equalTo(date.snp_trailing).offset(10)
                make.centerY.equalTo(date)
                make.trailing.lessThanOrEqualTo(imageView.snp_leading).inset(-18)
            }
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
    
    private func addVideoPlayer(comment: Comment) {
        CandyCell.videoPlayers.clear()
        let playerView = VideoPlayer.createPlayerView()
        imageView.insertSubview(playerView, atIndex: 0)
        playerView.snp_makeConstraints { (make) in
            make.edges.equalTo(imageView)
        }
        playerView.url = comment.asset?.smallVideoURL()
        self.videoPlayer = playerView
        playerView.startPlaying()
    }
    
    var comment: Comment? {
        willSet {
            if newValue != comment {
                videoPlayer?.removeFromSuperview()
                avatar.removeFromSuperview()
                text.removeFromSuperview()
                imageView.removeFromSuperview()
                name.removeFromSuperview()
                date.removeFromSuperview()
                indicator.removeFromSuperview()
                if let comment = newValue {
                    comment.markAsUnread(false)
                    name.text = comment.contributor?.name
                    avatar.user = comment.contributor
                    date.text = comment.createdAt.timeAgoString()
                    indicator.updateStatusIndicator(comment)
                    let commentType = comment.commentType()
                    layoutFor(commentType)
                    if commentType != .Text {
                        text.text = comment.displayText((comment.isVideo ? "see_my_video_comment".ls : "see_my_photo_comment".ls))
                        imageView.url = comment.asset?.small
                        if commentType == .Video && comment.candy?.isVideo == false {
                            addVideoPlayer(comment)
                        }
                        uploadingView = comment.uploadingView
                    } else {
                        text.text = comment.text
                    }
                    snp_updateConstraints(closure: { (make) in
                        make.height.equalTo(130)
                    })
                } else {
                    snp_updateConstraints(closure: { (make) in
                        make.height.equalTo(0)
                    })
                }
                layoutIfNeeded()
            }
        }
    }
}

final class HistoryViewController: SwipeViewController<CandyViewController>, EntryNotifying {
    
    weak var candy: Candy? {
        didSet {
            if candy != oldValue && isViewLoaded() {
                updateOwnerData()
            }
        }
    }
    
    private weak var wrap: Wrap?
    var history: PaginatedList<Candy>?
    private var candies = [Candy]()
    
    var dismissingView: (Candy -> UIView?)?
    
    private var visibleBarsContrains = [Constraint]()
    private var invisibleBarsContrains = [Constraint]()
    
    private let drawButton = Button.candyAction("8", color: Color.purple, size: 24)
    private let editButton = Button.candyAction("R", color: Color.blue)
    private let deleteButton = Button.expandableCandyAction("n")
    private let downloadButton = Button.expandableCandyAction("o")
    private let reportButton = Button.expandableCandyAction("s")
    private let shareButton = Button.expandableCandyAction("h")
    private let expandButton = Button.expandableCandyAction("/")
    
    private lazy var toolbar: UIView = specify(UIView()) { view in
        view.add(self.expandButton) {
            $0.size.equalTo(44)
            $0.top.bottom.equalTo(view).inset(16)
            $0.trailing.equalTo(view).inset(20)
        }
        view.add(self.drawButton) {
            $0.size.equalTo(44)
            $0.centerY.equalTo(self.expandButton)
            $0.leading.equalTo(view).offset(20)
        }
        view.add(self.editButton) {
            $0.size.equalTo(44)
            $0.centerY.equalTo(self.expandButton)
            $0.leading.equalTo(self.drawButton.snp_trailing).offset(14)
        }
    }
    
    private lazy var expandableToolbar: ExpandableView = specify(ExpandableView()) { view in
        view.clipsToBounds = true
        view.makeExpandable { expandingConstraint in
            view.add(self.reportButton) {
                $0.size.equalTo(44)
                $0.top.equalTo(view).inset(16)
                expandingConstraint = $0.bottom.equalTo(view).inset(16).constraint
                $0.trailing.equalTo(view).inset(20)
            }
        }
        view.add(self.deleteButton) {
            $0.size.equalTo(44)
            $0.centerY.equalTo(self.reportButton)
            $0.trailing.equalTo(view).inset(20)
        }
        view.add(self.downloadButton) {
            $0.size.equalTo(44)
            $0.top.equalTo(view).inset(16)
            $0.centerY.equalTo(self.reportButton)
            $0.trailing.equalTo(self.reportButton.snp_leading).offset(-14)
        }
        self.shareButton.titleEdgeInsets = UIEdgeInsetsMake(0,0,0,2)
        view.add(self.shareButton) {
            $0.size.equalTo(44)
            $0.centerY.equalTo(self.reportButton)
            $0.trailing.equalTo(self.downloadButton.snp_leading).offset(-14)
        }
    }
    
    private lazy var commentView: CommentView = specify(CommentView()) {
        $0.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.7)
        $0.layout()
    }
    
    private let contributorAvatar = specify(UserAvatarView(cornerRadius: 24)) {
        $0.setBorder()
    }
    private let contributorName = Label(preset: .Small, weight: .Bold, textColor: UIColor.whiteColor())
    private let contributedAt = Label(preset: .Smaller, weight: .Regular, textColor: Color.grayLighter)
    
    private lazy var contributionStatus = EntryStatusIndicator(color: Color.orange)
    
    private lazy var editorAvatar = specify(UserAvatarView(cornerRadius: 24)) {
        $0.setBorder()
    }
    private lazy var editorName = Label(preset: .Small, weight: .Bold, textColor: UIColor.whiteColor())
    private lazy var editedAt = Label(preset: .Smaller, weight: .Regular, textColor: Color.grayLighter)
    
    private lazy var contributorView: UIView = specify(UIView()) { view in
        view.add(self.contributorAvatar) {
            $0.leading.equalTo(view).inset(20)
            $0.top.equalTo(view).inset(4)
            $0.bottom.equalTo(view).inset(4)
            $0.size.equalTo(48)
        }
        view.add(self.contributorName) {
            $0.leading.equalTo(self.contributorAvatar.snp_trailing).inset(-18)
            $0.bottom.equalTo(self.contributorAvatar.snp_centerY).inset(-2)
        }
        view.add(self.contributionStatus) {
            $0.leading.equalTo(self.contributorName.snp_trailing).inset(-11)
            $0.centerY.equalTo(self.contributorName)
            $0.trailing.lessThanOrEqualTo(view).inset(20)
        }
        view.add(self.contributedAt) {
            $0.leading.equalTo(self.contributorAvatar.snp_trailing).inset(-18)
            $0.top.equalTo(self.contributorAvatar.snp_centerY).inset(2)
            $0.trailing.lessThanOrEqualTo(view).inset(20)
        }
    }
    
    private lazy var editorView: ExpandableView = specify(ExpandableView()) { view in
        view.clipsToBounds = true
        view.makeExpandable { expandingConstraint in
            view.add(self.editorAvatar) {
                $0.leading.equalTo(view).inset(20)
                $0.top.equalTo(view).inset(4)
                expandingConstraint = $0.bottom.equalTo(view).inset(4).constraint
                $0.size.equalTo(48)
            }
        }
        
        view.add(self.editorName) {
            $0.leading.equalTo(self.editorAvatar.snp_trailing).inset(-18)
            $0.bottom.equalTo(self.editorAvatar.snp_centerY).inset(-2)
            $0.trailing.lessThanOrEqualTo(view).inset(20)
        }
        view.add(self.editedAt) {
            $0.leading.equalTo(self.editorAvatar.snp_trailing).inset(-18)
            $0.top.equalTo(self.editorAvatar.snp_centerY).inset(2)
            $0.trailing.lessThanOrEqualTo(view).inset(20)
        }
    }
    
    private lazy var topView: ExpandableView = specify(ExpandableView()) { view in
        let backgroundView = UIView()
        view.addSubview(backgroundView)
        backgroundView.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.6)
        view.makeExpandable { expandingConstraint in
            view.add(self.contributorView) {
                $0.leading.trailing.equalTo(view)
                expandingConstraint = $0.top.equalTo(view).inset(12).constraint
            }
        }
        view.add(self.editorView) {
            $0.leading.trailing.equalTo(view)
            $0.top.equalTo(self.contributorView.snp_bottom)
        }
        view.add(self.toolbar) {
            $0.leading.trailing.equalTo(view)
            $0.top.equalTo(self.editorView.snp_bottom).inset(-16)
        }
        view.add(self.expandableToolbar) {
            $0.leading.trailing.equalTo(view)
            $0.top.equalTo(self.toolbar.snp_bottom)
        }
        view.add(SeparatorView(color: UIColor.whiteColor().colorWithAlphaComponent(0.1), contentMode: .Bottom)) {
            $0.leading.trailing.equalTo(view)
            $0.top.equalTo(self.toolbar)
            $0.height.equalTo(1)
        }
        view.add(self.accessoryView) {
            $0.leading.trailing.equalTo(view)
            $0.height.equalTo(32)
            $0.top.equalTo(self.expandableToolbar.snp_bottom)
            $0.top.equalTo(view).priorityHigh()
        }
        
        view.add(self.backButton) { (make) in
            make.leading.bottom.equalTo(view).inset(20)
            make.top.equalTo(self.expandableToolbar.snp_bottom).inset(-20)
        }
        
        backgroundView.snp_makeConstraints(closure: { (make) in
            make.leading.trailing.equalTo(view)
            make.top.equalTo(view)
            make.bottom.equalTo(self.expandableToolbar)
        })
    }
    
    private let accessoryLabel = Label(icon: "y", size: 21)
    
    private lazy var accessoryView: UIView = specify(UIView()) { view in
        view.clipsToBounds = true
        let squareView = UIView()
        squareView.cornerRadius = 4
        squareView.clipsToBounds = true
        squareView.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.6)
        view.add(squareView) {
            $0.centerX.equalTo(view)
            $0.top.equalTo(view).inset(-4)
            $0.bottom.equalTo(view)
            $0.width.equalTo(44)
        }
        view.add(self.accessoryLabel) { $0.center.equalTo(view) }
    }
    
    private let backButton = specify(Button(icon: "w", size: 24, textColor: UIColor.whiteColor())) {
        $0.layer.shadowColor = UIColor.blackColor().CGColor
        $0.layer.shadowOpacity = 0.5
        $0.layer.shadowOffset = CGSize(width: 0, height: 3)
    }
    let commentButton = Button.candyAction("f", color: Color.orange)
    private let commentCountLabel = specify(UILabel()) {
        $0.font = UIFont.systemFontOfSize(10, weight: UIFontWeightBold)
        $0.textColor = UIColor.whiteColor()
        $0.backgroundColor = Color.orange
        $0.cornerRadius = 10
        $0.textAlignment = .Center
        $0.clipsToBounds = true
    }
    
    let volumeButton = specify(Button.expandableCandyAction("l")) {
        $0.setTitle("m", forState: .Selected)
        $0.setTitleColor(Color.grayLight, forState: .Highlighted)
        $0.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.6)
    }
    
    private let userStatusView = specify(StatusUserAvatarView(backgroundColor: UIColor.clearColor())) {
        $0.applyPlaceholder(ImageView.Placeholder.gray)
        $0.cornerRadius = 22
        $0.setBorder()
    }
    
    private var cachedCandyViewControllers = [Candy : CandyViewController]()
    private weak var removedCandy: Candy?
    
    var swipeDownGesture: SwipeGesture!
    var swipeUpGesture: SwipeGesture!
    var tapGesture: TapGesture!
    
    let contentView = UIView()
    
    override func loadView() {
        self.view = UIView(frame: preferredViewFrame)
        self.view.backgroundColor = UIColor.blackColor()
        contentView.frame = preferredViewFrame
        let view = self.view.add(contentView) {
            $0.edges.equalTo(self.view)
        }
        scrollView.frame = preferredViewFrame
        view.add(scrollView) { $0.edges.equalTo(view) }
        
        view.add(commentView) {
            $0.leading.trailing.equalTo(view)
            visibleBarsContrains.append($0.bottom.equalTo(view).priorityHigh().constraint)
            invisibleBarsContrains.append($0.top.equalTo(view.snp_bottom).priorityLow().constraint)
        }
        commentButton.layer.shadowColor = UIColor.blackColor().CGColor
        commentButton.layer.shadowOpacity = 0.5
        commentButton.layer.shadowOffset = CGSize(width: 0, height: 3)
        view.add(commentButton) {
            $0.size.equalTo(44)
            $0.trailing.equalTo(view).inset(20)
            $0.bottom.equalTo(commentView.snp_top).inset(-20)
        }
        commentButton.add(commentCountLabel) { (make) in
            make.trailing.top.equalTo(commentButton).inset(-2)
            make.size.equalTo(20)
        }
        
        view.add(volumeButton) {
            $0.size.equalTo(44)
            $0.leading.equalTo(view).inset(20)
            visibleBarsContrains.append($0.bottom.equalTo(commentView.snp_top).offset(-20).priorityHigh().constraint)
            invisibleBarsContrains.append($0.top.equalTo(commentView).inset(20).priorityLow().constraint)
        }
        
        view.add(topView) {
            $0.leading.trailing.equalTo(view)
            visibleBarsContrains.append($0.top.equalTo(view).priorityHigh().constraint)
            invisibleBarsContrains.append($0.bottom.equalTo(view.snp_top).priorityLow().constraint)
        }
        
        userStatusView.hidden = true
        view.add(userStatusView) {
            $0.size.equalTo(44)
            $0.bottom.equalTo(commentView.snp_top).inset(-20).priorityLow()
            $0.bottom.lessThanOrEqualTo(commentButton.snp_top).offset(-20).priorityHigh()
            visibleBarsContrains.append($0.trailing.equalTo(view).inset(20).priorityHigh().constraint)
            invisibleBarsContrains.append($0.leading.equalTo(view.snp_trailing).inset(-20).priorityLow().constraint)
        }
        
        backButton.addTarget(self, action: #selector(self.back(_:)), forControlEvents: .TouchUpInside)
        expandButton.addTarget(self, action: #selector(self.toggleActions), forControlEvents: .TouchUpInside)
        commentButton.addTarget(self, action: #selector(self.comments(_:)), forControlEvents: .TouchUpInside)
        drawButton.addTarget(self, action: #selector(self.draw(_:)), forControlEvents: .TouchUpInside)
        editButton.addTarget(self, action: #selector(self.editPhoto(_:)), forControlEvents: .TouchUpInside)
        reportButton.addTarget(self, action: #selector(self.report(_:)), forControlEvents: .TouchUpInside)
        deleteButton.addTarget(self, action: #selector(self.deleteCandy(_:)), forControlEvents: .TouchUpInside)
        downloadButton.addTarget(self, action: #selector(self.downloadCandy(_:)), forControlEvents: .TouchUpInside)
        shareButton.addTarget(self, action: #selector(self.share(_:)), forControlEvents: .TouchUpInside)
        volumeButton.addTarget(self, action: #selector(self.toggleVolume(_:)), forControlEvents: .TouchUpInside)
        
        accessoryView.tapped { [weak self] _ in
            self?.toggleTopView()
        }
        swipeDownGesture = view.swiped(.Down) { [weak self] _ in
            if let controller = self {
                if controller.topView.y != 0 {
                    controller.setBarsHidden(false, animated: true)
                } else {
                    controller.setTopViewExpanded(true)
                }
            }
        }
        swipeUpGesture = view.swiped(.Up) { [weak self] _ in
            self?.setTopViewExpanded(false)
        }
        swipeUpGesture.shouldBegin = { [weak self] _ in
            return self?.topView.expanded == true
        }
        tapGesture = scrollView.tapped { [weak self] _ in
            self?.handleTapOnScrollView()
        }
        
        let secondCommentButton = TransparentButton(type: .Custom)
        secondCommentButton.titleLabel?.removeFromSuperview()
        secondCommentButton.highlightedColor = Color.grayLighter.colorWithAlphaComponent(0.2)
        commentView.insertSubview(secondCommentButton, atIndex: 0)
        secondCommentButton.highlightings = [commentButton]
        secondCommentButton.snp_makeConstraints(closure: {
            $0.edges.equalTo(commentView)
        })
        secondCommentButton.addTarget(self, touchUpInside: #selector(self.comments(_:)))
    }
    
    override func shouldUsePreferredViewFrame() -> Bool {
        return false
    }
    
    override func requestPresentingPermission(completion: BooleanBlock) {
        if let commentsViewController = CommentsViewController.current {
            commentsViewController.requestPresentingPermission(completion)
        } else {
            super.requestPresentingPermission(completion)
        }
    }
    
    @objc private func toggleActions() {
        setActionsExpanded(!expandableToolbar.expanded)
    }
    
    private func setActionsExpanded(expanded: Bool, animated: Bool = true) {
        guard expandableToolbar.expanded != expanded else { return }
        animate(animated) {
            expandableToolbar.expanded = expanded
            expandButton.selected = expanded
            topView.layoutIfNeeded()
        }
    }
    
    private func handleTapOnScrollView() {
        if topView.expanded {
            setTopViewExpanded(false)
        } else {
            setBarsHidden(topView.y == 0, animated: true)
        }
    }
    
    private func setTopViewExpanded(expanded: Bool, animated: Bool = true) {
        guard topView.expanded != expanded else { return }
        animate(animated) {
            accessoryLabel.layer.transform = CATransform3DMakeRotation(expanded ? CGFloat(M_PI) : 0, 1, 0, 0)
            topView.expanded = expanded
            topView.layoutIfNeeded()
        }
    }
    
    private func toggleTopView() {
        setTopViewExpanded(!topView.expanded)
    }
    
    private var userNotifyReceiver: EntryNotifyReceiver<User>?
    
    private var shrinkTransition: ShrinkTransition!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        VideoPlayer.didBecomeUnmuted.subscribe(self) { [unowned self] videoPlayer in
            if let videoViewConroller = self.viewController as? VideoCandyViewController {
                if videoViewConroller.playerView != videoPlayer {
                    videoViewConroller.playerView.muted = true
                    self.volumeButton.selected = false
                }
            }
        }
        
        CommentViewController.willAppear.subscribe(self) { [unowned self] controller in
            if let videoViewConroller = self.viewController as? VideoCandyViewController {
                if controller.comment?.commentType() == .Video {
                    videoViewConroller.playerView.playing = false
                    CommentViewController.willDisappear.subscribe(self) { controller in
                        videoViewConroller.playerView.startPlaying()
                        CommentViewController.willDisappear.unsubscribe(self)
                    }
                }
            }
        }
        
        shrinkTransition = createShrinkTransition()
        
        wrap = candy?.wrap
        
        candies = wrap?.historyCandies ?? []
        
        Candy.notifier().addReceiver(self)
        
        if let wrap = wrap {
            if history == nil {
                history = History.paginatedList(wrap)
            }
            updateUserStatus(wrap)
            userNotifyReceiver = EntryNotifyReceiver<User>().setup({ [weak self] (receiver) in
                receiver.didUpdate = { user, event in
                    if wrap.contributors.contains(user) && event == .UserStatus {
                        self?.updateUserStatus(wrap)
                    }
                }
                })
        }
        
        if let candy = candy {
            setCandy(candy, direction: .Forward, animated: false)
        }
    }
    
    private func updateUserStatus(wrap: Wrap) {
        let activeContributors = wrap.contributors.filter({ $0.activityForWrap(wrap) != nil })
        userStatusView.hidden = activeContributors.isEmpty
        userStatusView.wrap = wrap
        userStatusView.user = activeContributors.sort({ $0.activeAt > $1.activeAt }).first
    }
    
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        if CommentsViewController.current != nil || CommentViewController.current != nil {
            return [.Portrait, .PortraitUpsideDown]
        } else {
            return .All
        }
    }
    
    override func shouldAutorotate() -> Bool {
        if CommentsViewController.current != nil || CommentViewController.current != nil {
            return false
        } else {
            return true
        }
    }
    
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
        coordinator.animateAlongsideTransition({ (context) in
            let isLandscape = DeviceManager.defaultManager.orientation.isLandscape
            self.setBarsHidden(isLandscape, animated: false)
            self.view.layoutIfNeeded()
            self.commentButton.alpha = isLandscape ? 0 : 1
            self.swipeUpGesture.enabled = !isLandscape
            self.swipeDownGesture.enabled = !isLandscape
            self.tapGesture.enabled = !isLandscape
            self.shrinkTransition.enabled = !isLandscape
            }) { (context) in
                
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        commentView.comment = nil
        downloadButton.active = !PHPhotoLibrary.authorizationStatus().denied
        updateOwnerData()
        if let candy = candy, let index = candies.indexOf(candy) where !candy.valid {
            if let candy = candyAfterDeletingCandyAt(index) {
                setCandy(candy, direction: .Forward, animated: false)
            } else {
                navigationController?.popViewControllerAnimated(false)
            }
        }
    }
    
    func setBarsHidden(hidden: Bool, animated: Bool, additionalAnimation: (() -> ())? = nil) {
        animate(animated, duration: 0.3) {
            visibleBarsContrains.all { $0.updatePriority(hidden ? 250 : 750) }
            invisibleBarsContrains.all { $0.updatePriority(hidden ? 750 : 250) }
            if animated {
                view.layoutIfNeeded()
            }
            additionalAnimation?()
        }
    }
    
    func showCommentView(animated: Bool = true) {
        if CommentsViewController.current != nil {
            return
        }
        setBarsHidden(true, animated: animated)
        let commentsViewController = CommentsViewController()
        commentsViewController.candy = candy
        commentsViewController.presentForController(self, animated: animated)
        CommentsViewController.current = commentsViewController
        commentButton.hidden = true
    }
    
    private func setCandy(candy: Candy, direction: SwipeDirection, animated: Bool) {
        self.candy = candy
        let controller = candyViewController(candy)
        updateOwnerData()
        setViewController(controller, direction: direction, animated: animated)
    }
    
    private func fetchCandiesOlderThen(candy: Candy) {
        guard let history = history where !history.completed else { return }
        guard let index = candies.indexOf(candy) else { return }
        guard candies.count - index < 4 else { return }
        history.older({ [weak self] _ in
            self?.candies = self?.wrap?.historyCandies ?? []
            }, failure: nil)
    }
    
    private func candyViewController(candy: Candy) -> CandyViewController {
        if let controller = cachedCandyViewControllers[candy] {
            return controller
        } else {
            let controller = candy.mediaType == .Video ? VideoCandyViewController() : PhotoCandyViewController()
            controller.candy = candy
            cachedCandyViewControllers[candy] = controller
            return controller
        }
    }
    
    private func updateOwnerData() {
        if let candy = candy?.validEntry() {
            candy.markAsUnread(false)
            contributorAvatar.user = candy.contributor
            contributorName.text = String(format:(candy.isVideo ? "formatted_video_by" : "formatted_photo_by").ls, candy.contributor?.name ?? "")
            contributedAt.text = candy.createdAt.timeAgoStringAtAMPM()
            contributionStatus.updateStatusIndicator(candy)
            
            if candy.contributor == candy.editor {
                contributorName.text = String(format:"formatted_photo_edited_by".ls, candy.contributor?.name ?? "")
                editorView.expanded = false
                topView.layoutIfNeeded()
            } else if let editor = candy.editor {
                editorAvatar.user = editor
                editorName.text = String(format:"formatted_edited_by".ls, editor.name ?? "")
                editedAt.text = candy.editedAt.timeAgoStringAtAMPM()
                editorView.expanded = true
            } else {
                editorView.expanded = false
            }
            
            deleteButton.hidden = !candy.deletable
            reportButton.hidden = !deleteButton.hidden
            drawButton.hidden = candy.isVideo
            editButton.hidden = candy.isVideo
            commentView.comment = candy.latestComment
            let commentCount = candy.commentCount
            if commentCount > 0 {
                commentCountLabel.hidden = false
                commentCountLabel.text = commentCount > 99 ? "99+" : "\(commentCount)"
            } else {
                commentCountLabel.hidden = true
            }
            volumeButton.hidden = !candy.isVideo
        }
    }
    
    private func candyAfterDeletingCandyAt(index: Int) -> Candy? {
        guard wrap?.candies.count > 0 else { return nil }
        return candies[safe: index] ?? candies[safe: index - 1] ?? candies.first
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        cachedCandyViewControllers.removeAll()
    }
    
    override func viewControllerNextTo(viewController: CandyViewController?, direction: SwipeDirection) -> CandyViewController? {
        guard let candy = viewController?.candy else { return nil }
        guard let index = candies.indexOf(candy) else { return nil }
        
        let isForward = direction == .Forward
        
        if let candy = candies[safe: (isForward ? index - 1 : index + 1)] {
            return candyViewController(candy)
        } else if isForward {
            fetchCandiesOlderThen(candy)
        }
        return nil
    }
    
    override func didChangeViewController(viewController: CandyViewController!) {
        guard let candy = viewController?.candy else { return }
        self.candy = candy
        fetchCandiesOlderThen(candy)
        if let videoViewConroller = viewController as? VideoCandyViewController {
            volumeButton.selected = !videoViewConroller.playerView.muted
        }
        setActionsExpanded(false, animated: false)
        setTopViewExpanded(false)
    }
    
    override func didChangeOffsetForViewController(viewController: CandyViewController, offset: CGFloat) {
        viewController.view.alpha = offset
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    func notifier(notifier: EntryNotifier, didAddEntry entry: Entry) {
        candies = wrap?.historyCandies ?? []
    }
    
    func notifier(notifier: EntryNotifier, didUpdateEntry entry: Entry, event: EntryUpdateEvent) {
        if candy == entry {
            updateOwnerData()
        }
    }
    
    func notifier(notifier: EntryNotifier, willDeleteEntry entry: Entry) {
        
        guard let candy = entry as? Candy, let index = candies.indexOf(candy) else { return }
        
        candies.removeAtIndex(index)
        
        if candy == self.candy {
            if navigationController?.presentedViewController != nil {
                navigationController?.dismissViewControllerAnimated(false, completion: nil)
            }
            if removedCandy == candy {
                Toast.show((candy.isVideo ? "video_deleted" : "photo_deleted").ls)
                self.removedCandy = nil
            } else {
                Toast.show((candy.isVideo ? "video_unavailable" : "photo_unavailable").ls)
            }
            
            if let nextCandy = candyAfterDeletingCandyAt(index) {
                setCandy(nextCandy, direction: .Forward, animated: false)
                setBarsHidden(false, animated: true)
            } else {
                navigationController?.popViewControllerAnimated(false)
            }
            cachedCandyViewControllers[candy] = nil
        }
    }
    
    func notifier(notifier: EntryNotifier, willDeleteContainer container: Entry) {
        Toast.showMessageForUnavailableWrap(wrap)
        navigationController?.popToRootViewControllerAnimated(false)
    }
    
    func notifier(notifier: EntryNotifier, shouldNotifyOnEntry entry: Entry) -> Bool {
        return entry.container == wrap
    }
    
    func notifier(notifier: EntryNotifier, shouldNotifyOnContainer container: Entry) -> Bool {
        return wrap == container
    }
    
    override func back(sender: UIButton) {
        if let candy = candy?.validEntry() {
            navigationController?.popViewControllerAnimated(false)
            CandyPresenter.dismiss(candy, dismissingView: dismissingView)
        } else {
            navigationController?.popToRootViewControllerAnimated(false)
        }
    }
    
    @IBAction func downloadCandy(sender: Button) {
        PHPhotoLibrary.authorize({ [weak self] in
            if let candy = self?.candy {
                candy.download({ () -> Void in
                    Toast.showDownloadingMediaMessageForCandy(candy)
                    }, failure: { (error) -> Void in
                        if let error = error where error.isNetworkError {
                            Toast.show("downloading_internet_connection_error".ls)
                        } else {
                            error?.show()
                        }
                })
            }
        }) { (_) -> Void in
            sender.active = false
        }
    }
    
    @IBAction func deleteCandy(sender: Button) {
        guard let candy = candy else { return }
        UIAlertController.confirmCandyDeleting(candy, success: { [weak self] _ in
            self?.removedCandy = candy
            sender.loading = true
            candy.delete({ _ in
                sender.loading = false
                }, failure: { (error) -> Void in
                    self?.removedCandy = nil
                    error?.show()
                    sender.loading = false
            })
            }, failure: nil)
    }
    
    @IBAction func report(sender: AnyObject) {
        if let candy = candy {
            let controller = ReportViewController(candy: candy)
            navigationController?.presentViewController(controller, animated: false, completion: nil)
        }
    }
    
    @IBAction func editPhoto(sender: AnyObject) {
        DownloadingView.downloadCandyImage(candy, success: { [weak self] (image) -> Void in
            ImageEditor.editImage(image) { self?.candy?.editWithImage($0) }
            }, failure: { $0?.show() })
    }
    
    @IBAction func draw(sender: UIButton) {
        sender.userInteractionEnabled = false
        DownloadingView.downloadCandyImage(candy, success: { [weak self] (image) -> Void in
            DrawingViewController.draw(image, wrap: self?.candy?.wrap) { self?.candy?.editWithImage($0) }
            sender.userInteractionEnabled = true
            }, failure: { (error) -> Void in
                error?.show()
                sender.userInteractionEnabled = true
        })
    }
    
    @IBAction func share(sender: Button) {
        
        DownloadingView.downloadCandy(candy, message: "downloading_media_for_sharing".ls, success: { [weak self] (url) in
            let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
            activityVC.popoverPresentationController?.sourceView = sender
            self?.presentViewController(activityVC, animated: true, completion: nil)
            })
    }
    
    @IBAction func comments(sender: AnyObject) {
        showCommentView()
    }
    
    private func toggleVolume() {
        if let videoViewConroller = viewController as? VideoCandyViewController {
            volumeButton.selected = !volumeButton.selected
            videoViewConroller.playerView.muted = !volumeButton.selected
        }
    }
    
    @IBAction func toggleVolume(sender: AnyObject) {
        toggleVolume()
    }
}
