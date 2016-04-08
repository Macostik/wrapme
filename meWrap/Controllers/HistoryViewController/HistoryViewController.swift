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

final class CommentView: ExpendableView {
    
    private let avatar = UserAvatarView(cornerRadius: 24)
    private let name = Label(preset: .Small, weight: .Bold, textColor: UIColor.whiteColor())
    private let date = Label(preset: .Smaller, weight: .Regular, textColor: Color.grayLighter)
    private let text = Label(preset: .Small, weight: .Regular, textColor: UIColor.whiteColor())
    private let indicator = EntryStatusIndicator(color: Color.orange)
    
    func layout() {
        text.numberOfLines = 2
        avatar.borderColor = UIColor.whiteColor()
        avatar.borderWidth = 1
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
        
        makeExpandable { (expandingConstraint) in
            date.snp_makeConstraints { (make) -> Void in
                make.leading.equalTo(avatar.snp_trailing).offset(18)
                make.top.equalTo(name.snp_bottom).offset(4)
                expandingConstraint = make.bottom.equalTo(self).inset(20).constraint
            }
        }

        indicator.snp_makeConstraints { (make) -> Void in
            make.leading.equalTo(date.snp_trailing).offset(12)
            make.centerY.equalTo(date)
        }
    }
    
    var comment: Comment? {
        willSet {
            if newValue != comment {
                if let comment = newValue {
                    comment.markAsUnread(false)
                    name.text = comment.contributor?.name
                    avatar.user = comment.contributor
                    date.text = comment.createdAt.timeAgoString()
                    indicator.updateStatusIndicator(comment)
                    text.text = comment.text
                    expanded = true
                } else {
                    expanded = false
                }
                layoutIfNeeded()
            }
        }
    }
}

class ExpendableView: UIView {
    
    var expandingConstraint: Constraint?
    
    var expanded = false {
        willSet {
            if newValue != expanded {
                if newValue {
                    expandingConstraint?.activate()
                } else {
                    expandingConstraint?.deactivate()
                }
            }
        }
    }
    
    func makeExpandable(@noescape block: (expandingConstraint: inout Constraint?) -> ()) {
        var constraint: Constraint?
        block(expandingConstraint: &constraint)
        expandingConstraint = constraint
        constraint?.deactivate()
    }
}

extension Button {
    
    class func candyAction(action: String, color: UIColor) -> Button {
        let button = Button(icon: action, size: 20)
        button.cornerRadius = 22
        button.clipsToBounds = true
        button.normalColor = color
        button.highlightedColor = color.darkerColor()
        button.update()
        return button
    }
    
    class func expandableCandyAction(action: String) -> Button {
        let button = Button(icon: action, size: 20)
        button.setTitleColor(Color.grayLight, forState: .Highlighted)
        button.setTitleColor(Color.grayLight, forState: .Selected)
        button.borderColor = UIColor.whiteColor()
        button.borderWidth = 1.5
        button.clipsToBounds = true
        button.cornerRadius = 22
        return button
    }
}

class HistoryViewController: SwipeViewController<CandyViewController>, EntryNotifying {
    
    weak var candy: Candy? {
        didSet {
            if candy != oldValue && isViewLoaded() {
                updateOwnerData()
            }
        }
    }
    
    private weak var wrap: Wrap?
    var history: History?
    private var candies = [Candy]()
    
    var presenter: CandyEnlargingPresenter?
    var commentPressed: Block?
    var dismissingView: ((presenter: CandyEnlargingPresenter?, candy: Candy) -> UIView?)?
    
    private let spinner = UIActivityIndicatorView(activityIndicatorStyle: .White)
    private let drawButton = Button.candyAction("8", color: Color.purple)
    private let editButton = Button.candyAction("R", color: Color.blue)
    private let deleteButton = Button.expandableCandyAction("n")
    private let downloadButton = Button.expandableCandyAction("o")
    private let reportButton = Button.expandableCandyAction("s")
    private let expandButton = Button.expandableCandyAction("/")
    
    private lazy var toolbar: UIView = specify(UIView()) { view in
        view.addSubview(self.drawButton)
        view.addSubview(self.editButton)
        view.addSubview(self.expandButton)
        self.drawButton.snp_makeConstraints {
            $0.size.equalTo(44)
            $0.centerY.equalTo(self.expandButton)
            $0.leading.equalTo(view).offset(20)
        }
        self.editButton.snp_makeConstraints {
            $0.size.equalTo(44)
            $0.centerY.equalTo(self.expandButton)
            $0.leading.equalTo(self.drawButton.snp_trailing).offset(14)
        }
        self.expandButton.snp_makeConstraints {
            $0.size.equalTo(44)
            $0.top.bottom.equalTo(view).inset(16)
            $0.trailing.equalTo(view).inset(20)
        }
    }
    
    private lazy var expandableToolbar: ExpendableView = specify(ExpendableView()) { view in
        view.addSubview(self.reportButton)
        view.addSubview(self.deleteButton)
        view.addSubview(self.downloadButton)
        view.clipsToBounds = true
        self.reportButton.snp_makeConstraints {
            $0.size.equalTo(44)
            $0.centerY.equalTo(self.downloadButton)
            $0.trailing.equalTo(view).inset(20)
        }
        self.deleteButton.snp_makeConstraints {
            $0.size.equalTo(44)
            $0.centerY.equalTo(self.downloadButton)
            $0.trailing.equalTo(view).inset(20)
        }
        view.makeExpandable { expandingConstraint in
            self.downloadButton.snp_makeConstraints {
                $0.size.equalTo(44)
                $0.top.equalTo(view).inset(16)
                expandingConstraint = $0.bottom.equalTo(view).inset(16).constraint
                $0.trailing.equalTo(self.reportButton.snp_leading).offset(-14)
            }
        }
    }
    
    private lazy var commentView: CommentView = specify(CommentView()) {
        $0.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.6)
        $0.layout()
    }
    
    private let contributorAvatar = specify(UserAvatarView(cornerRadius: 24)) {
        $0.borderColor = UIColor.whiteColor()
        $0.borderWidth = 1
    }
    private let contributorName = Label(preset: .Small, weight: .Bold, textColor: UIColor.whiteColor())
    private let contributedAt = Label(preset: .Smaller, weight: .Regular, textColor: Color.grayLighter)
    
    private lazy var contributionStatus = EntryStatusIndicator(color: Color.orange)
    
    private lazy var editorAvatar = specify(UserAvatarView(cornerRadius: 24)) {
        $0.borderColor = UIColor.whiteColor()
        $0.borderWidth = 1
    }
    private lazy var editorName = Label(preset: .Small, weight: .Bold, textColor: UIColor.whiteColor())
    private lazy var editedAt = Label(preset: .Smaller, weight: .Regular, textColor: Color.grayLighter)
    
    private lazy var contributorView: UIView = specify(UIView()) { view in
        view.addSubview(self.contributorAvatar)
        view.addSubview(self.contributorName)
        view.addSubview(self.contributionStatus)
        view.addSubview(self.contributedAt)
        self.contributorAvatar.snp_makeConstraints {
            $0.leading.equalTo(view).inset(20)
            $0.top.equalTo(view).inset(4)
            $0.bottom.equalTo(view).inset(4)
            $0.size.equalTo(48)
        }
        self.contributorName.snp_makeConstraints {
            $0.leading.equalTo(self.contributorAvatar.snp_trailing).inset(-18)
            $0.bottom.equalTo(self.contributorAvatar.snp_centerY).inset(-2)
        }
        self.contributionStatus.snp_makeConstraints {
            $0.leading.equalTo(self.contributorName.snp_trailing).inset(-11)
            $0.centerY.equalTo(self.contributorName)
            $0.trailing.lessThanOrEqualTo(view).inset(20)
        }
        self.contributedAt.snp_makeConstraints {
            $0.leading.equalTo(self.contributorAvatar.snp_trailing).inset(-18)
            $0.top.equalTo(self.contributorAvatar.snp_centerY).inset(2)
            $0.trailing.lessThanOrEqualTo(view).inset(20)
        }
    }
    
    private lazy var editorView: ExpendableView = specify(ExpendableView()) { view in
        view.clipsToBounds = true
        view.addSubview(self.editorAvatar)
        view.addSubview(self.editorName)
        view.addSubview(self.editedAt)
        view.makeExpandable { expandingConstraint in
            self.editorAvatar.snp_makeConstraints {
                $0.leading.equalTo(view).inset(20)
                $0.top.equalTo(view).inset(4)
                expandingConstraint = $0.bottom.equalTo(view).inset(4).constraint
                $0.size.equalTo(48)
            }
        }
        
        self.editorName.snp_makeConstraints {
            $0.leading.equalTo(self.editorAvatar.snp_trailing).inset(-18)
            $0.bottom.equalTo(self.editorAvatar.snp_centerY).inset(-2)
            $0.trailing.lessThanOrEqualTo(view).inset(20)
        }
        self.editedAt.snp_makeConstraints {
            $0.leading.equalTo(self.editorAvatar.snp_trailing).inset(-18)
            $0.top.equalTo(self.editorAvatar.snp_centerY).inset(2)
            $0.trailing.lessThanOrEqualTo(view).inset(20)
        }
    }
    
    private lazy var topView: ExpendableView = specify(ExpendableView()) { view in
        view.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.6)
        view.addSubview(self.contributorView)
        view.addSubview(self.editorView)
        view.addSubview(self.toolbar)
        view.addSubview(self.expandableToolbar)
        
        view.makeExpandable { expandingConstraint in
            self.contributorView.snp_makeConstraints {
                $0.leading.trailing.equalTo(view)
                expandingConstraint = $0.top.equalTo(view).inset(12).constraint
            }
        }
        
        self.editorView.snp_makeConstraints {
            $0.leading.trailing.equalTo(view)
            $0.top.equalTo(self.contributorView.snp_bottom)
        }
        
        self.toolbar.snp_makeConstraints {
            $0.leading.trailing.equalTo(view)
            $0.top.equalTo(self.editorView.snp_bottom).inset(-16)
        }
        self.expandableToolbar.snp_makeConstraints {
            $0.leading.trailing.equalTo(view)
            $0.top.equalTo(self.toolbar.snp_bottom)
            $0.bottom.equalTo(view)
        }
        
        let separator = SeparatorView(color: UIColor.whiteColor().colorWithAlphaComponent(0.1), contentMode: .Bottom)
        view.addSubview(separator)
        separator.snp_makeConstraints(closure: {
            $0.leading.trailing.equalTo(view)
            $0.top.equalTo(self.toolbar)
            $0.height.equalTo(1)
        })
    }
    
    private let accessoryLabel = Label(icon: "y", size: 18)
    
    private lazy var accessoryView: UIView = specify(UIView()) { view in
        view.clipsToBounds = true
        let squareView = UIView()
        squareView.cornerRadius = 4
        squareView.clipsToBounds = true
        squareView.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.6)
        view.addSubview(squareView)
        squareView.snp_makeConstraints {
            $0.centerX.equalTo(view)
            $0.top.equalTo(view).inset(-4)
            $0.bottom.equalTo(view)
            $0.width.equalTo(44)
        }
        view.addSubview(self.accessoryLabel)
        self.accessoryLabel.snp_makeConstraints { $0.center.equalTo(view) }
    }
    
    private let commentButton = Button.candyAction("f", color: Color.orange)
    
    private var cachedCandyViewControllers = [Candy : CandyViewController]()
    private weak var removedCandy: Candy?
    private var paginationQueue = RunQueue(limit: 1)
    
    override func loadView() {
        let view = UIView(frame: preferredViewFrame)
        let scrollView = UIScrollView()
        view.addSubview(scrollView)
        scrollView.snp_makeConstraints {
            $0.center.equalTo(view)
            $0.size.equalTo(view)
        }
        self.scrollView = scrollView
        view.addSubview(topView)
        topView.snp_makeConstraints {
            $0.leading.trailing.equalTo(view)
            $0.top.equalTo(view)
        }
        view.addSubview(accessoryView)
        accessoryView.snp_makeConstraints {
            $0.leading.trailing.equalTo(view)
            $0.height.equalTo(32)
            $0.top.equalTo(topView.snp_bottom)
        }
        
        view.addSubview(commentView)
        commentView.snp_makeConstraints {
            $0.leading.trailing.bottom.equalTo(view)
        }
        view.addSubview(commentButton)
        commentButton.snp_makeConstraints {
            $0.size.equalTo(44)
            $0.trailing.bottom.equalTo(view).inset(20)
        }
        
        expandButton.addTarget(self, action: #selector(self.toggleActions), forControlEvents: .TouchUpInside)
        commentButton.addTarget(self, action: #selector(self.comments(_:)), forControlEvents: .TouchUpInside)
        drawButton.addTarget(self, action: #selector(self.draw(_:)), forControlEvents: .TouchUpInside)
        editButton.addTarget(self, action: #selector(self.editPhoto(_:)), forControlEvents: .TouchUpInside)
        reportButton.addTarget(self, action: #selector(self.report(_:)), forControlEvents: .TouchUpInside)
        deleteButton.addTarget(self, action: #selector(self.deleteCandy(_:)), forControlEvents: .TouchUpInside)
        downloadButton.addTarget(self, action: #selector(self.downloadCandy(_:)), forControlEvents: .TouchUpInside)
        
        self.view = view
        
        accessoryView.tapped { [weak self] _ in
            self?.toggleTopView()
        }
        scrollView.swiped(.Down) { [weak self] _ in
            self?.setTopViewExpanded(true)
        }
        scrollView.swiped(.Up) { [weak self] _ in
            self?.setTopViewExpanded(false)
        }
        view.tapped { [weak self] _ in
            self?.setTopViewExpanded(false)
        }
    }
    
    @objc private func toggleActions() {
        animate { 
            expandableToolbar.expanded = !expandableToolbar.expanded
            expandButton.selected = expandableToolbar.expanded
            topView.layoutIfNeeded()
            accessoryView.layoutIfNeeded()
        }
    }
    
    private func setTopViewExpanded(expanded: Bool) {
        if topView.expanded != expanded {
            animate {
                topView.expanded = expanded
                topView.layoutIfNeeded()
                accessoryView.layoutIfNeeded()
            }
        }
    }
    
    private func toggleTopView() {
        setTopViewExpanded(!topView.expanded)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        wrap = candy?.wrap
        
        candies = wrap?.historyCandies ?? []
        
        Candy.notifier().addReceiver(self)
        
        commentButton.layer.borderColor = UIColor.whiteColor().CGColor
        
        if let wrap = wrap where history == nil {
            history = History(wrap:wrap)
        }
        
        setCandy(candy, direction: .Forward, animated: false)
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
    
    func setBarsHidden(hidden: Bool, animated: Bool) {
//        primaryConstraint?.setDefaultState(!hidden, animated: animated)
    }
    
    func showCommentView() {
        if childViewControllers.contains({ $0 is CommentsViewController }) {
            return
        }
        setBarsHidden(true, animated: true)
        applyScaleToCandyViewController(true)
        Storyboard.Comments.instantiate({ $0.candy = candy }).presentForController(self)
    }
    
    private func setCandy(candy: Candy?, direction: SwipeDirection, animated: Bool) {
        self.candy = candy
        if let controller = candyViewController(candy) {
            updateOwnerData()
            setViewController(controller, direction: direction, animated: animated)
        }
    }
    
    private func fetchCandiesOlderThen(candy: Candy) {
        guard let history = history where !history.completed else { return }
        guard let index = candies.indexOf(candy) else { return }
        guard candies.count - index < 4 else { return }
        paginationQueue.run { [weak self] (finish) -> Void in
            self?.spinner.startAnimating()
            history.older({ _ in
                self?.candies = self?.wrap?.historyCandies ?? []
                self?.spinner.stopAnimating()
                finish()
                }, failure: { _ in
                    self?.spinner.stopAnimating()
                    finish()
            })
        }
    }
    
    private func candyViewController(candy: Candy?) -> CandyViewController? {
        guard let candy = candy else { return nil }
        if let controller = cachedCandyViewControllers[candy] {
            return controller
        } else {
            let controller = (candy.mediaType == .Video ? Storyboard.VideoCandy : Storyboard.PhotoCandy).instantiate()
            controller.candy = candy
            controller.historyViewController = self
            cachedCandyViewControllers[candy] = controller
            return controller
        }
    }
    
    private func updateOwnerData() {
        if let candy = candy?.validEntry() {
            
            contributorAvatar.user = candy.contributor
            contributorName.text = String(format:(candy.isVideo ? "formatted_video_by" : "formatted_photo_by").ls, candy.contributor?.name ?? "")
            contributedAt.text = candy.createdAt.timeAgoStringAtAMPM()
            contributionStatus.updateStatusIndicator(candy)
            
            if let editor = candy.editor {
                editorAvatar.user = editor
                editorName.text = String(format:"formatted_edited_by".ls, editor.name ?? "")
                editedAt.text = candy.editedAt.timeAgoStringAtAMPM()
                editorView.expanded = true
                topView.layoutIfNeeded()
            } else {
                editorView.expanded = false
                topView.layoutIfNeeded()
            }
            deleteButton.hidden = !candy.deletable
            reportButton.hidden = !deleteButton.hidden
            drawButton.hidden = candy.isVideo
            editButton.hidden = candy.isVideo
            commentView.comment = candy.latestComment
        }
    }
    
    private func candyAfterDeletingCandyAt(index: Int) -> Candy? {
        guard wrap?.candies.count > 0 else { return nil }
        return candies[safe: index] ?? candies[safe: index - 1] ?? candies.first
    }
    
    private func downloadCandyOriginal(candy: Candy?, success: UIImage -> Void, failure: FailureBlock) {
        if let candy = candy {
            if let error = candy.updateError() {
                failure(error)
            } else {
                DownloadingView.downloadCandy(candy, success: success, failure: failure)
            }
        } else {
            failure(nil)
        }
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
    }
    
    override func didChangeOffsetForViewController(viewController: CandyViewController, offset: CGFloat) {
        viewController.view.alpha = offset
    }
    
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return .All
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
                InfoToast.show((candy.isVideo ? "video_deleted" : "photo_deleted").ls)
                self.removedCandy = nil
            } else {
                InfoToast.show((candy.isVideo ? "video_unavailable" : "photo_unavailable").ls)
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
        InfoToast.showMessageForUnavailableWrap(wrap)
        navigationController?.popToRootViewControllerAnimated(false)
    }
    
    func notifier(notifier: EntryNotifier, shouldNotifyOnEntry entry: Entry) -> Bool {
        return entry.container == wrap
    }
    
    func notifier(notifier: EntryNotifier, shouldNotifyOnContainer container: Entry) -> Bool {
        return wrap == container
    }
    
    @IBAction func downloadCandy(sender: Button) {
        PHPhotoLibrary.authorize({ [weak self] in
            FollowingViewController.followWrapIfNeeded(self?.wrap) { _ in
                sender.loading = true
                self?.candy?.download({ () -> Void in
                    sender.loading = false
                    InfoToast.showDownloadingMediaMessageForCandy(self?.candy)
                    }, failure: { (error) -> Void in
                        if let error = error where error.isNetworkError {
                            InfoToast.show("downloading_internet_connection_error".ls)
                        } else {
                            error?.show()
                        }
                        sender.loading = false
                })
            }
        }) { (_) -> Void in
            sender.active = false
        }
    }
    
    @IBAction func deleteCandy(sender: Button) {
        FollowingViewController.followWrapIfNeeded(wrap) { [weak self] () -> Void in
            guard let candy = self?.candy else { return }
            UIAlertController.confirmCandyDeleting(candy, success: { _ in
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
    }
    
    @IBAction func report(sender: AnyObject) {
        Storyboard.ReportCandy.instantiate { (controller) -> Void in
            controller.candy = candy
            navigationController?.presentViewController(controller, animated: false, completion: nil)
        }
    }
    
    @IBAction func editPhoto(sender: AnyObject) {
        FollowingViewController.followWrapIfNeeded(wrap) { [weak self] () -> Void in
            self?.downloadCandyOriginal(self?.candy, success: { (image) -> Void in
                ImageEditor.editImage(image) { self?.candy?.editWithImage($0) }
                }, failure: { $0?.show() })
        }
    }
    
    @IBAction func draw(sender: UIButton) {
        sender.userInteractionEnabled = false
        FollowingViewController.followWrapIfNeeded(wrap) { [weak self] () -> Void in
            self?.downloadCandyOriginal(self?.candy, success: { (image) -> Void in
                DrawingViewController.draw(image) { self?.candy?.editWithImage($0) }
                sender.userInteractionEnabled = true
                }, failure: { (error) -> Void in
                    error?.show()
                    sender.userInteractionEnabled = true
            })
        }
    }
    
    @IBAction func comments(sender: AnyObject) {
        commentPressed?()
        showCommentView()
    }
    
    @IBAction func hadleTapRecognizer(sender: AnyObject) {
//        setBarsHidden(primaryConstraint?.defaultState ?? false, animated: true)
//        commentButtonPrioritizer?.defaultState = primaryConstraint?.defaultState ?? false
    }
    
    func applyScaleToCandyViewController(apply: Bool) {
        let controller = candyViewController(candy)
        let transform = apply ? CGAffineTransformMakeScale(0.9, 0.9) : CGAffineTransformIdentity
        UIView.animateWithDuration(0.25) { controller?.view.transform = transform }
        setBarsHidden(apply, animated: true)
    }
    
    func hideSecondaryViews(hide: Bool) {
        commentView.hidden = hide
        topView.hidden = hide
        accessoryView.hidden = hide
        commentButton.hidden = hide
        if hide {
            commentView.addAnimation(CATransition.transition(kCATransitionFade))
            topView.addAnimation(CATransition.transition(kCATransitionFade))
            commentButton.addAnimation(CATransition.transition(kCATransitionFade))
        }
    }
}
