//
//  HomeViewController.swift
//  meWrap
//
//  Created by Sergey Maximenko on 2/18/16.
//  Copyright © 2016 Ravenpod. All rights reserved.
//

import UIKit

final class HomeViewController: WLBaseViewController {
    
    @IBOutlet var dataSource: SegmentedStreamDataSource!
    @IBOutlet var publicDataSource: PaginatedStreamDataSource!
    @IBOutlet var homeDataSource: HomeDataSource!
    @IBOutlet var emailConfirmationLayoutPrioritizer: LayoutPrioritizer!
    
    @IBOutlet weak var streamView: StreamView!
    @IBOutlet weak var emailConfirmationView: UIView!
    @IBOutlet weak var uploadingView: UploaderView!
    @IBOutlet weak var createWrapButton: UIButton!
    @IBOutlet weak var verificationEmailLabel: Label!
    @IBOutlet weak var photoButton: UIButton!
    weak var candiesView: RecentCandiesView!
    @IBOutlet weak var publicWrapsHeaderView: UIView!
    
    private var userNotifyReceiver: EntryNotifyReceiver!
    private var wrapNotifyReceiver: EntryNotifyReceiver!
    
    deinit {
        AddressBook.sharedAddressBook.endCaching()
        EventualEntryPresenter.sharedPresenter.isLoaded = false
        NSNotificationCenter.defaultCenter().removeObserver(self, name:UIApplicationWillEnterForegroundNotification, object:nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        unowned let streamView: StreamView = self.streamView
        unowned let homeDataSource: HomeDataSource = self.homeDataSource
        unowned let publicDataSource: PaginatedStreamDataSource = self.publicDataSource
        
        streamView.contentInset = streamView.scrollIndicatorInsets;
        
        homeDataSource.autogeneratedMetrics.change {
            $0.sizeAt = { $0.position.index == 0 ? 70 : 60 }
            $0.insetsAt = { CGRectMake(0, $0.position.index == 1 ? 5 : 0, 0, 0) }
            
            $0.selection = { item, entry in
                if let entry = entry as? Entry {
                    ChronologicalEntryPresenter.presentEntry(entry, animated: false)
                }
            }
            
            publicDataSource.autogeneratedMetrics.selection = $0.selection
            
            publicDataSource.autogeneratedMetrics.insetsAt = { CGRectMake(0, $0.position.index == 0 ? 5 : 0, 0, 0) }
        }
        
        homeDataSource.addMetrics(RecentCandiesView.layoutMetrics().change({ [weak self] metrics in
            metrics.sizeAt = { _ in
                let size = (streamView.width - 2.0)/3.0
                return (homeDataSource.wrap?.candies.count > Constants.recentCandiesLimit_2 ? 2*size : size) + 5
            }
            
            metrics.finalizeAppearing = { item, view in
                let view = view as! RecentCandiesView
                self?.candiesView = view
                self?.finalizeAppearingOfCandiesView(view)
            }
            
            metrics.hiddenAt = { $0.position.index != 0 }
            }))
        
        
        homeDataSource.autogeneratedMetrics.finalizeAppearing = { [weak self] item, view in
            self?.photoButton.hidden = false
        }
        publicDataSource.autogeneratedMetrics.finalizeAppearing = homeDataSource.autogeneratedMetrics.finalizeAppearing
        
        homeDataSource.placeholderMetrics = StreamMetrics(loader: HomePlaceholderView.homePlaceholderLoader({ [unowned self] () -> Void in
            self.navigationController?.pushViewController(Storyboard.UploadWizard.instantiate(), animated:false)
        })).change({ (metrics) -> Void in
            metrics.finalizeAppearing = { [weak self] item, view in
                self?.photoButton.hidden = true
            }
        })
        
        publicDataSource.loadingMetrics.sizeAt = { [unowned self] _ in
            return streamView.height - self.publicWrapsHeaderView.height - 48
        }
        
        dataSource.setRefreshableWithStyle(.Orange)
        
        super.viewDidLoad()
        
        AddressBook.sharedAddressBook.beginCaching()
        
        addNotifyReceivers()
        
        guard let user = User.currentUser else { return }
        let wraps = user.wraps
        
        homeDataSource.items = PaginatedList(entries:Array(wraps), request:PaginatedRequest.wraps(nil))
        
        if !wraps.isEmpty {
            homeDataSource.refresh()
        }
        
        uploadingView.uploader = Uploader.candyUploader
        
        NSUserDefaults.standardUserDefaults().numberOfLaunches++
        
        Dispatch.mainQueue.async {
            RunQueue.fetchQueue.run({ (finish) -> Void in
                NotificationCenter.defaultCenter.fetchLiveBroadcasts({
                    homeDataSource.paginatedSet?.sort()
                    publicDataSource.paginatedSet?.sort()
                    finish();
                })
            })
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        dataSource.reload()
        updateEmailConfirmationView(false)
        EventualEntryPresenter.sharedPresenter.isLoaded = true
        uploadingView.update()
        if NSUserDefaults.standardUserDefaults().numberOfLaunches >= 3 && User.currentUser?.wraps.count >= 3 {
            HintView.showHomeSwipeTransitionHintView()
        }
        streamView.unlock()
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        streamView.lock()
    }
    
    private func updateEmailConfirmationView(animated: Bool) {
        let hidden = (NSUserDefaults.standardUserDefaults().confirmationDate?.isToday() ?? false) || (Authorization.current.unconfirmed_email?.isEmpty ?? true)
        if !hidden {
            verificationEmailLabel.attributedText = ChangeProfileViewController.verificationSuggestion()
            deadlineEmailConfirmationView()
        }
        setEmailConfirmationViewHidden(hidden, animated:animated)
    }
    
    private func setEmailConfirmationViewHidden(hidden: Bool, animated: Bool) {
        emailConfirmationLayoutPrioritizer.setDefaultState(!hidden, animated:animated)
    }
    
    private func deadlineEmailConfirmationView() {
        NSUserDefaults.standardUserDefaults().confirmationDate = NSDate.now()
        performSelector("hideConfirmationEmailView", withObject:nil, afterDelay:15.0)
    }
    
    func hideConfirmationEmailView() {
        setEmailConfirmationViewHidden(true, animated:true)
    }
    
    private func addNotifyReceivers() {
        
        wrapNotifyReceiver = Wrap.notifyReceiver().setup { [unowned self] receiver in
            receiver.didAdd = {
                let wrap = $0 as! Wrap
                if wrap.isPublic {
                    self.publicDataSource.paginatedSet?.sort(wrap)
                }
                if wrap.isContributing {
                    self.homeDataSource.paginatedSet?.sort(wrap)
                }
                self.streamView.contentOffset = CGPointZero
            }
            receiver.didUpdate = { entry, event in
                if event == .NumberOfUnreadMessagesChanged || event == .InboxChanged {
                    for item in self.streamView.visibleItems() {
                        (item.view as? WrapCell)?.updateBadgeNumber()
                    }
                } else {
                    let wrap = entry as! Wrap
                    if wrap.isPublic {
                        self.publicDataSource.paginatedSet?.sort(wrap)
                    }
                    if wrap.isContributing {
                        self.homeDataSource.paginatedSet?.sort(wrap)
                    } else {
                        self.homeDataSource.paginatedSet?.remove(wrap)
                    }
                }
            }
            receiver.willDelete = {
                let wrap = $0 as! Wrap
                if wrap.isPublic {
                    self.publicDataSource.paginatedSet?.remove(wrap)
                }
                if wrap.isContributing {
                    self.homeDataSource.paginatedSet?.remove(wrap)
                }
            }
        }
        
        userNotifyReceiver = User.notifyReceiver().setup {
            $0.didUpdate = { [unowned self] entry, event in
                if self.isTopViewController {
                    self.updateEmailConfirmationView(true)
                }
            }
        }
    }
    
    private func finalizeAppearingOfCandiesView(candiesView: RecentCandiesView) {
        let metrics = candiesView.dataSource.metrics.first
        metrics?.selection = { [weak self] item, entry in
            if let candy = entry as? Candy {
                CandyEnlargingPresenter.handleCandySelection(item, entry: candy, dismissingView: { (presenter, candy) -> UIView? in
                    self?.streamView.scrollRectToVisible(candiesView.frame, animated:false)
                    return candiesView.streamView.itemPassingTest({ $0.entry === candy })?.view
                })
            } else {
                self?.addPhoto(nil)
            }
        }
    }
    
    private func openCameraForWrap(wrap: Wrap?, animated: Bool) {
        let captureViewController = CaptureViewController.captureMediaViewController(wrap)
        captureViewController.captureDelegate = self
        presentViewController(captureViewController, animated:animated, completion:nil)
    }
    
    private func topWrap() -> Wrap? {
        if (self.dataSource.currentDataSource == self.publicDataSource) {
            if let publicWraps = publicDataSource.paginatedSet?.entries as? [Wrap] {
                for wrap in publicWraps {
                    if wrap.isContributing {
                        return wrap
                    }
                }
            }
        }
        return homeDataSource.wrap
    }
}

extension HomeViewController {
    
    @IBAction func createWrap(sender: AnyObject?) {
        let controller = Storyboard.UploadWizard.instantiate()
        controller.isNewWrap = true
        navigationController?.pushViewController(controller, animated:false)
    }
    
    @IBAction func addPhoto(sender: AnyObject?) {
        openCameraForWrap(topWrap(), animated:false)
    }
    
    
    @IBAction func resendConfirmation(sender: AnyObject?) {
        APIRequest.resendConfirmation(nil).send({ _ in
            Toast.show("confirmation_resend".ls)
            }, failure: { $0?.show() })
    }
    
    @IBAction func hottestWrapsOpened(sender: AnyObject?) {
        self.publicWrapsHeaderView.hidden = false
        var wraps: [Wrap] = []
        if !Network.sharedNetwork.reachable {
            wraps = Wrap.fetch().query("isPublic == YES").execute() as! [Wrap]
        }
        publicDataSource.items = PaginatedList(entries:wraps, request:PaginatedRequest.wraps("public"))
    }
    
    @IBAction func privateWrapsOpened(sender: AnyObject?) {
        self.publicWrapsHeaderView.hidden = true
    }
}

extension HomeViewController: CaptureMediaViewControllerDelegate {
    
    func captureViewControllerDidCancel(controller: CaptureMediaViewController) {
        dismissViewControllerAnimated(false, completion: nil)
    }
    
    func captureViewController(controller: CaptureMediaViewController, didFinishWithAssets assets: [MutableAsset]) {
        dismissViewControllerAnimated(false, completion: nil)
        if let wrap = controller.wrap {
            if let controller = wrap.viewControllerWithNavigationController(navigationController!) as? WrapViewController {
                controller.segment = .Media
                navigationController?.viewControllers = [self, controller]
            }
            FollowingViewController.followWrapIfNeeded(wrap, performAction: {
                SoundPlayer.player.play(.s04)
                wrap.uploadAssets(assets)
            })
        }
    }
}

extension HomeViewController: WrapCellDelegate {
    
    func wrapCellDidBeginPanning(cell: WrapCell) {
        streamView.lock()
    }
    
    func wrapCellDidEndPanning(cell: WrapCell, performedAction: Bool) {
        streamView.unlock()
        streamView.userInteractionEnabled = !performedAction
    }
    
    func wrapCell(cell: WrapCell, presentChatViewControllerForWrap wrap: Wrap) {
        streamView.userInteractionEnabled = true
        if wrap.valid {
            let wrapViewController = Storyboard.Wrap.instantiate()
            wrapViewController.wrap = wrap
            wrapViewController.segment = .Chat
            navigationController?.pushViewController(wrapViewController, animated:true)
        }
    }
    
    func wrapCell(cell: WrapCell, presentCameraViewControllerForWrap wrap: Wrap) {
        streamView.userInteractionEnabled = true
        if (wrap.valid) {
            openCameraForWrap(wrap, animated: true)
        }
    }
}
