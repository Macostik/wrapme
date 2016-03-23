//
//  HomeViewController.swift
//  meWrap
//
//  Created by Sergey Maximenko on 2/18/16.
//  Copyright © 2016 Ravenpod. All rights reserved.
//

import UIKit

final class HomeViewController: BaseViewController {
    
    @IBOutlet var dataSource: HomeDataSource!
    @IBOutlet var emailConfirmationLayoutPrioritizer: LayoutPrioritizer!
    
    @IBOutlet weak var streamView: StreamView!
    @IBOutlet weak var emailConfirmationView: UIView!
    @IBOutlet weak var uploadingView: UploaderView!
    @IBOutlet weak var createWrapButton: UIButton!
    @IBOutlet weak var verificationEmailLabel: Label!
    @IBOutlet weak var photoButton: UIButton!
    weak var candiesView: RecentCandiesView?
    
    private var userNotifyReceiver: EntryNotifyReceiver<User>!
    private var wrapNotifyReceiver: EntryNotifyReceiver<Wrap>!
    
    deinit {
        AddressBook.sharedAddressBook.endCaching()
        AuthorizedExecutor.authorized = false
        NSNotificationCenter.defaultCenter().removeObserver(self, name:UIApplicationWillEnterForegroundNotification, object:nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.streamView.contentInset = self.streamView.scrollIndicatorInsets
        
        dataSource.addMetrics(specify(StreamMetrics(loader: StreamLoader<WrapCell>()), {
            $0.modifyItem = {
                let index = $0.position.index
                $0.size = index == 0 ? 70 : 60
                $0.insets.origin.y = index == 1 ? 5 : 0
            }
            
            $0.selection = { item, entry in
                if let entry = entry as? Entry {
                    ChronologicalEntryPresenter.presentEntry(entry, animated: false)
                }
            }
            $0.finalizeAppearing = { [weak self] item, view in
                (view as? WrapCell)?.delegate = self
                self?.photoButton.hidden = false
            }
        }))
        
        dataSource.addMetrics(StreamMetrics(loader: StreamLoader<RecentCandiesView>()).change({ [weak self] metrics in
            
            metrics.modifyItem = { item in
                let size = (Constants.screenWidth - 2.0)/3.0
                item.size = (self?.dataSource.wrap?.candies.count > Constants.recentCandiesLimit_2 ? 2*size : size) + 5
                item.hidden = item.position.index != 0
            }
            
            metrics.finalizeAppearing = { item, view in
                if let view = view as? RecentCandiesView {
                    self?.candiesView = view
                    self?.finalizeAppearingOfCandiesView(view)
                }
            }
            
            }))
        
        dataSource.placeholderMetrics = StreamMetrics(loader: HomePlaceholderView.homePlaceholderLoader({ [weak self] () -> Void in
            self?.navigationController?.pushViewController(Storyboard.UploadWizard.instantiate(), animated:false)
            })).change({ (metrics) -> Void in
                metrics.finalizeAppearing = { [weak self] item, view in
                    self?.photoButton.hidden = true
                }
            })
        
        let refresher = Refresher(scrollView: self.streamView)
        refresher.style = .Orange
        refresher.addTarget(dataSource, action: #selector(StreamDataSource.refresh(_:)), forControlEvents: .ValueChanged)
        refresher.addTarget(self, action: #selector(HomeViewController.refreshUserActivities), forControlEvents: .ValueChanged)
        
        super.viewDidLoad()
        
        AddressBook.sharedAddressBook.beginCaching()
        
        addNotifyReceivers()
        
        guard let user = User.currentUser else { return }
        let wraps = user.wraps
        
        dataSource.items = PaginatedList(entries:Array(wraps), request:PaginatedRequest.wraps(nil))
        
        if !wraps.isEmpty {
            dataSource.refresh()
        }
        
        uploadingView.uploader = Uploader.candyUploader
        
        NSUserDefaults.standardUserDefaults().numberOfLaunches += 1
        
        Dispatch.mainQueue.async { [weak self] _ in
            RunQueue.fetchQueue.run { finish in
                NotificationCenter.defaultCenter.refreshUserActivities {
                    self?.dataSource.paginatedSet?.sort()
                    finish()
                }
            }
        }
        streamView.layoutIfNeeded()
    }
    
    func refreshUserActivities() {
        NotificationCenter.defaultCenter.refreshUserActivities { [weak self] () -> Void in
            self?.dataSource.paginatedSet?.sort()
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        dataSource.reload()
        updateEmailConfirmationView(false)
        AuthorizedExecutor.authorized = true
        uploadingView.update()
        if NSUserDefaults.standardUserDefaults().numberOfLaunches >= 3 && User.currentUser?.wraps.count >= 3 {
            HintView.showHomeSwipeTransitionHintView(view)
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
        performSelector(#selector(HomeViewController.hideConfirmationEmailView), withObject:nil, afterDelay:15.0)
    }
    
    func hideConfirmationEmailView() {
        setEmailConfirmationViewHidden(true, animated:true)
    }
    
    private func addNotifyReceivers() {
        
        wrapNotifyReceiver = EntryNotifyReceiver<Wrap>().setup { [weak self] receiver in
            receiver.didAdd = {
                if $0.isContributing {
                    self?.dataSource.paginatedSet?.sort($0)
                }
                self?.streamView.contentOffset = CGPointZero
            }
            receiver.didUpdate = { entry, event in
                if event == .NumberOfUnreadMessagesChanged || event == .InboxChanged {
                    self?.streamView.visibleItems().all({ ($0.view as? WrapCell)?.updateBadgeNumber() })
                } else {
                    let wrap = entry
                    if wrap.isContributing {
                        self?.dataSource.paginatedSet?.sort(wrap)
                    } else {
                        self?.dataSource.paginatedSet?.remove(wrap)
                    }
                }
            }
            receiver.willDelete = {
                if $0.isContributing {
                    self?.dataSource.paginatedSet?.remove($0)
                }
            }
        }
        
        userNotifyReceiver = EntryNotifyReceiver<User>().setup { [weak self] receiver in
            receiver.didUpdate = { entry, event in
                if self?.isTopViewController == true {
                    self?.updateEmailConfirmationView(true)
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
        return dataSource.wrap
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
                SoundPlayer.playSend()
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
            navigationController?.pushViewController(wrapViewController, animated:false)
        }
    }
    
    func wrapCell(cell: WrapCell, presentCameraViewControllerForWrap wrap: Wrap) {
        streamView.userInteractionEnabled = true
        if (wrap.valid) {
            openCameraForWrap(wrap, animated: false)
        }
    }
}
