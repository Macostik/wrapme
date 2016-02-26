//
//  HistoryViewController+Ext.swift
//  meWrap
//
//  Created by Sergey Maximenko on 1/31/16.
//  Copyright © 2016 Ravenpod. All rights reserved.
//

import Foundation

class HistoryViewController: SwipeViewController {
    
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
    
    var showCommentViewController = false
    var presenter: CandyEnlargingPresenter?
    var commentPressed: Block?
    var dismissingView: ((presenter: CandyEnlargingPresenter?, candy: Candy) -> UIView?)?
    
    @IBOutlet weak var contentView: UIView!
    @IBOutlet var commentButtonPrioritizer: LayoutPrioritizer!
    
    @IBOutlet weak var bottomViewHeightPrioritizer: LayoutPrioritizer!
    @IBOutlet weak var primaryConstraint: LayoutPrioritizer!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet weak var downloadButton: UIButton!
    @IBOutlet weak var drawButton: UIButton!
    @IBOutlet weak var editButton: UIButton!
    @IBOutlet weak var reportButton: UIButton!
    @IBOutlet weak var bottomView: HistoryFooterView!
    @IBOutlet weak var topView: UIView!
    @IBOutlet weak var commentButton: Button!
    
    private var cachedCandyViewControllers = [Candy : CandyViewController]()
    private weak var removedCandy: Candy?
    private var paginationQueue = RunQueue(limit: 1)
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        contentView.addGestureRecognizer(scrollView!.panGestureRecognizer)
        
        wrap = candy?.wrap
        
        candies = wrap?.historyCandies ?? []
        
        Candy.notifier().addReceiver(self)
        
        commentButton.layer.borderColor = UIColor.whiteColor().CGColor
        
        if let wrap = wrap where history == nil {
            history = History(wrap:wrap)
        }
        
        setCandy(candy, direction: .Forward, animated: false)
        
        if (self.showCommentViewController) {
            showCommentView()
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        bottomView.comment = nil
        updateOwnerData()
        if !showCommentViewController {
            setBarsHidden(false, animated: animated)
            commentButtonPrioritizer.defaultState = true
        }
        if let candy = candy, let index = candies.indexOf(candy) where !candy.valid {
            if let candy = candyAfterDeletingCandyAt(index) {
                setCandy(candy, direction: .Forward, animated: false)
            } else {
                navigationController?.popViewControllerAnimated(false)
            }
        }
    }
    
    func setBarsHidden(hidden: Bool, animated: Bool) {
        primaryConstraint.setDefaultState(!hidden, animated: animated)
    }
    
    func showCommentView() {
        commentButton.sendActionsForControlEvents(.TouchUpInside)
        showCommentViewController = false
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
            let controller = Storyboard.Candy.instantiate()
            controller.candy = candy
            controller.historyViewController = self
            cachedCandyViewControllers[candy] = controller
            return controller
        }
    }
    
    private func updateOwnerData() {
        if let candy = candy?.validEntry() {
            bottomView.candy = candy
            setCommentButtonTitle(candy)
            deleteButton.hidden = !candy.deletable
            reportButton.hidden = !deleteButton.hidden
            drawButton.hidden = candy.isVideo
            editButton.hidden = candy.isVideo
            bottomViewHeightPrioritizer.defaultState = candy.latestComment?.valid ?? false
        }
    }
    
    private func setCommentButtonTitle(candy: Candy) {
        var title = "comment".ls
        if candy.commentCount == 1 {
            title = "one_comment".ls
        } else if candy.commentCount > 1 {
            title = String(format: "formatted_comments".ls, Int(candy.commentCount))
        }
        commentButton.setTitle(title, forState:.Normal)
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
    
    override func viewControllerNextTo(viewController: UIViewController?, direction: SwipeDirection) -> UIViewController? {
        guard let candy = (viewController as? CandyViewController)?.candy else { return nil }
        guard let index = candies.indexOf(candy) else { return nil }
        
        let isForward = direction == .Forward
        
        if let candy = candies[safe: (isForward ? index + 1 : index - 1)] {
            return candyViewController(candy)
        } else if isForward {
            fetchCandiesOlderThen(candy)
        }
        return nil
    }
    
    override func didChangeViewController(viewController: UIViewController!) {
        guard let candy = (viewController as? CandyViewController)?.candy else { return }
        self.candy = candy
        fetchCandiesOlderThen(candy)
    }
    
    override func didChangeOffsetForViewController(viewController: UIViewController, offset: CGFloat) {
        viewController.view.alpha = offset
    }
    
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return .All
    }
}

extension HistoryViewController: EntryNotifying {
    
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
}

extension HistoryViewController {
    
    override func back(sender: UIButton) {
        let animate = UIApplication.sharedApplication().statusBarOrientation.isPortrait
        if let candy = candy?.validEntry() {
            if let presenter = presenter where animate {
                navigationController?.popViewControllerAnimated(false)
                presenter.dismiss(candy)
            } else {
                navigationController?.popViewControllerAnimated(animate)
            }
        } else {
            navigationController?.popToRootViewControllerAnimated(false)
        }
    }
    
    @IBAction func downloadCandy(sender: Button) {
        FollowingViewController.followWrapIfNeeded(wrap) { [weak self] () -> Void in
            sender.loading = true
            self?.candy?.download({ () -> Void in
                sender.loading = false
                Toast.showDownloadingMediaMessageForCandy(self?.candy)
                }, failure: { (error) -> Void in
                    if let error = error where error.isNetworkError {
                        Toast.show("downloading_internet_connection_error".ls)
                    } else {
                        error?.show()
                    }
                    sender.loading = false
            })
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
        FollowingViewController.followWrapIfNeeded(wrap) { [weak self] () -> Void in
            if let controllers = self?.childViewControllers {
                for controller in controllers {
                    if controller is CommentsViewController {
                        return
                    }
                }
            }
            self?.setBarsHidden(true, animated: true)
            self?.applyScaleToCandyViewController(true)
            Storyboard.Comments.instantiate({ (controller) -> Void in
                controller.candy = self?.candy
                controller.presentForController(self)
            })
        }
    }
    
    @IBAction func hadleTapRecognizer(sender: AnyObject) {
        setBarsHidden(primaryConstraint.defaultState, animated: true)
        commentButtonPrioritizer.defaultState = primaryConstraint.defaultState
    }
    
    func applyScaleToCandyViewController(apply: Bool) {
        let controller = candyViewController(candy)
        let transform = apply ? CGAffineTransformMakeScale(0.9, 0.9) : CGAffineTransformIdentity
        UIView.animateWithDuration(0.25) { controller?.view.transform = transform }
        setBarsHidden(apply, animated: true)
    }
    
    func hideSecondaryViews(hide: Bool) {
        bottomView.hidden = hide
        topView.hidden = hide
        commentButton.hidden = hide
        if hide {
            bottomView.addAnimation(CATransition.transition(kCATransitionFade))
            topView.addAnimation(CATransition.transition(kCATransitionFade))
            commentButton.addAnimation(CATransition.transition(kCATransitionFade))
        }
    }
}
