//
//  HomeViewController.swift
//  meWrap
//
//  Created by Sergey Maximenko on 2/18/16.
//  Copyright © 2016 Ravenpod. All rights reserved.
//

import UIKit

final class HomeViewController: BaseViewController {
    
    private lazy var dataSource: HomeDataSource = HomeDataSource(streamView: self.streamView)
    
    private let streamView = StreamView()
    private lazy var emailConfirmationView: UIView = {
        let view = UIView()
        let label = Label(preset: .Small, weight: .Regular, textColor: Color.grayDarker)
        label.text = "help_secure_account".ls
        label.numberOfLines = 0
        view.add(label) { make in
            make.leading.top.equalTo(view).offset(12)
            make.trailing.equalTo(view).offset(-12)
        }
        self.verificationEmailLabel.numberOfLines = 0
        view.add(self.verificationEmailLabel) { make in
            make.top.equalTo(label.snp_bottom)
            make.leading.equalTo(view).offset(12)
            make.trailing.equalTo(view).offset(-12)
        }
        func createButton(title: String, action: Selector) -> Button {
            let button = PressButton(preset: .Smaller, weight: .Light, textColor: .whiteColor())
            button.insets = 10 ^ 6
            button.cornerRadius = 4
            button.clipsToBounds = true
            button.addTarget(self, touchUpInside: action)
            button.setTitle(title, forState: .Normal)
            button.backgroundColor = Color.orange
            return button
        }
        view.add(createButton("change_email".ls, action: #selector(self.changeEmail(_:))), { (make) in
            make.leading.equalTo(view).offset(12)
            make.top.equalTo(self.verificationEmailLabel.snp_bottom).offset(12)
            make.bottom.equalTo(view).offset(-12)
        })
        view.add(createButton("resend".ls, action: #selector(self.resendConfirmation(_:))), { (make) in
            make.trailing.equalTo(view).offset(-12)
            make.top.equalTo(self.verificationEmailLabel.snp_bottom).offset(12)
            make.bottom.equalTo(view).offset(-12)
        })
        return view
    }()
    private lazy var verificationEmailLabel: Label = Label(preset: .XSmall, weight: .Light, textColor: Color.grayDarker)
    private let photoButton = AnimatedButton(circleInset: 5)
    private weak var candiesView: RecentCandiesView?
    private let createWrapButton = Button(icon: "P", size: 33, textColor: UIColor.whiteColor())
    
    private let activityStatusView = ActivityStatusView()
    
    private var userNotifyReceiver: EntryNotifyReceiver<User>!
    private var wrapNotifyReceiver: EntryNotifyReceiver<Wrap>!
    
    deinit {
        AddressBook.sharedAddressBook.endCaching()
        AuthorizedExecutor.authorized = false
        NSNotificationCenter.defaultCenter().removeObserver(self, name:UIApplicationWillEnterForegroundNotification, object:nil)
    }
    
    override func loadView() {
        super.loadView()
        
        view.backgroundColor = .whiteColor()
        
        let navigationBar = UIView()
        
        view.add(navigationBar) { (make) in
            make.leading.top.trailing.equalTo(view)
            make.height.equalTo(64)
        }
        
        navigationBar.backgroundColor = Color.orange
        let title = Button(icon: "M", size: 70, textColor: UIColor.whiteColor())
        title.addTarget(self, touchUpInside: #selector(self.settings(_:)))
        navigationBar.add(title) { (make) in
            make.centerX.equalTo(navigationBar)
            make.centerY.equalTo(navigationBar).offset(10)
        }
        
        createWrapButton.addTarget(self, touchUpInside: #selector(self.createWrap(_:)))
        navigationBar.add(createWrapButton) { (make) in
            make.centerY.equalTo(navigationBar).offset(10)
            make.trailing.equalTo(navigationBar).offset(-12)
        }
        
        navigationBar.add(activityStatusView, { (make) in
            make.leading.equalTo(navigationBar).inset(12)
            make.centerY.equalTo(navigationBar).inset(10)
        })
        
        self.navigationBar = navigationBar
        
        streamView.delaysContentTouches = false
        streamView.alwaysBounceVertical = true
        view.add(streamView) { (make) in
            make.top.equalTo(navigationBar.snp_bottom)
            make.leading.bottom.trailing.equalTo(view)
        }
        
        photoButton.cornerRadius = 41
        photoButton.circleView.backgroundColor = Color.orange.colorWithAlphaComponent(0.88)
        photoButton.backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(0.7)
        photoButton.setImage(UIImage(named: "home_ic_new_photo"), forState: .Normal)
        photoButton.exclusiveTouch = true
        photoButton.addTarget(self, touchUpInside: #selector(self.addPhoto(_:)))
        view.addSubview(photoButton)
        setScrollSensitiveInterfaceHidden(false, animated: false)
        streamView.contentInset = UIEdgeInsetsMake(0, 0, 92, 0)
        streamView.scrollIndicatorInsets = streamView.contentInset
        streamView.trackScrollDirection = true
        streamView.scrollDirectionChanged = { [weak self] isUp -> () in
            self?.setScrollSensitiveInterfaceHidden(isUp, animated: true)
        }
        dataSource.didEndDecelerating = { [weak self] _ in
            self?.streamView.direction = .Down
        }
    }
    
    private func setScrollSensitiveInterfaceHidden(hidden: Bool, animated: Bool) {
        photoButton.snp_remakeConstraints { (make) in
            make.size.equalTo(82)
            if hidden {
                make.top.equalTo(view.snp_bottom).offset(4)
            } else {
                make.bottom.equalTo(view).offset(-4)
            }
            make.centerX.equalTo(view)
        }
        if animated {
            animate() {
                view.layoutIfNeeded()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        dataSource.addMetrics(specify(StreamMetrics<WrapCell>(), {
            $0.modifyItem = {
                let index = $0.position.index
                $0.size = index == 0 ? 70 : 60
                $0.insets.origin.y = index == 1 ? 5 : 0
            }
            
            $0.selection = { view in
                if let entry = view.entry {
                    ChronologicalEntryPresenter.presentEntry(entry, animated: false)
                }
            }
            $0.finalizeAppearing = { [weak self] item, view in
                view.delegate = self
                self?.photoButton.hidden = false
            }
        }))
        
        dataSource.addMetrics(StreamMetrics<RecentCandiesView>().change({ [weak self] metrics in
            
            metrics.modifyItem = { item in
                let size = (Constants.screenWidth - 2.0)/3.0
                item.size = (self?.dataSource.wrap?.candies.count > Constants.recentCandiesLimit_2 ? 2*size : size) + 5
                item.hidden = item.position.index != 0
            }
            
            metrics.finalizeAppearing = { item, view in
                self?.candiesView = view
                self?.finalizeAppearingOfCandiesView(view)
            }
            
            }))
        
        streamView.placeholderViewBlock = PlaceholderView.homePlaceholder({ [weak self] button -> Void in
            if let controller = self {
                controller.photoButton.hidden = true
                button.addTarget(controller, touchUpInside: #selector(self?.createWrap(_:)))
            }
            })
        
        let refresher = Refresher(scrollView: self.streamView)
        refresher.style = .Orange
        refresher.addTarget(dataSource, action: #selector(dataSource.refresh(_:)), forControlEvents: .ValueChanged)
        refresher.addTarget(self, action: #selector(HomeViewController.refreshUserActivities), forControlEvents: .ValueChanged)
        
        super.viewDidLoad()
        
        AddressBook.sharedAddressBook.beginCaching()
        
        addNotifyReceivers()
        
        guard let user = User.currentUser else { return }
        let wraps = user.wraps
        
        dataSource.items = specify(PaginatedList(), {
            $0.request = API.wraps(nil)
            $0.sorter = {
                if $1.liveBroadcasts.count > 0 {
                    if $0.liveBroadcasts.count > 0 {
                        return $0.name < $1.name
                    } else {
                        return false
                    }
                } else {
                    if $0.liveBroadcasts.count > 0 {
                        return true
                    } else {
                        return $0.updatedAt > $1.updatedAt
                    }
                }
            }
            $0.entries = wraps.sort($0.sorter)
            $0.newerThen = {
                return $0.maxElement({ $0.updatedAt < $1.updatedAt })?.updatedAt
            }
            $0.olderThen = {
                return $0.maxElement({ $0.updatedAt > $1.updatedAt })?.updatedAt
            }
        })
        
        if !wraps.isEmpty {
            dataSource.refresh()
        }
        
        NSUserDefaults.standardUserDefaults().numberOfLaunches += 1
        
        Dispatch.mainQueue.async { [weak self] _ in
            RunQueue.fetchQueue.run { finish in
                NotificationCenter.defaultCenter.refreshUserActivities {
                    self?.dataSource.items?.sort()
                    finish()
                }
            }
        }
        CallCenter.center.enable()
    }
    
    func refreshUserActivities() {
        NotificationCenter.defaultCenter.refreshUserActivities { [weak self] () -> Void in
            self?.dataSource.items?.sort()
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        CandyCell.videoCandy = nil
        dataSource.reload()
        updateEmailConfirmationView()
        AuthorizedExecutor.authorized = true
        streamView.unlock()
        activityStatusView.status = .None
        activityStatusView.update()
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        streamView.lock()
    }
    
    private func updateEmailConfirmationView() {
        let hidden = (NSUserDefaults.standardUserDefaults().confirmationDate?.isToday() ?? false) || (Authorization.current.unconfirmed_email?.isEmpty ?? true)
        emailConfirmationViewHidden = hidden
    }
    
    private var emailConfirmationViewHidden = true {
        didSet {
            guard emailConfirmationViewHidden != oldValue else { return }
            if emailConfirmationViewHidden {
                emailConfirmationView.removeFromSuperview()
                streamView.snp_remakeConstraints(closure: { (make) in
                    make.top.equalTo(navigationBar!.snp_bottom)
                    make.leading.bottom.trailing.equalTo(view)
                })
            } else {
                verificationEmailLabel.attributedText = ChangeProfileViewController.verificationSuggestion()
                view.add(emailConfirmationView, { (make) in
                    make.top.equalTo(navigationBar!.snp_bottom)
                    make.leading.trailing.equalTo(view)
                })
                streamView.snp_remakeConstraints(closure: { (make) in
                    make.top.equalTo(emailConfirmationView.snp_bottom)
                    make.leading.bottom.trailing.equalTo(view)
                })
                Dispatch.mainQueue.after(15, block: { [weak self] () in
                    NSUserDefaults.standardUserDefaults().confirmationDate = NSDate.now()
                    self?.emailConfirmationViewHidden = true
                })
            }
        }
    }
    
    private func addNotifyReceivers() {
        
        wrapNotifyReceiver = EntryNotifyReceiver<Wrap>().setup { [weak self] receiver in
            receiver.didAdd = {
                if $0.isContributing {
                    self?.dataSource.items?.sort($0)
                }
                self?.streamView.contentOffset = CGPointZero
            }
            receiver.didUpdate = { entry, event in
                if event == .NumberOfUnreadMessagesChanged || event == .InboxChanged {
                    self?.streamView.visibleItems().all({ ($0.view as? WrapCell)?.updateBadgeNumber() })
                } else {
                    let wrap = entry
                    if wrap.isContributing {
                        self?.dataSource.items?.sort(wrap)
                    } else {
                        self?.dataSource.items?.remove(wrap)
                    }
                }
            }
            receiver.willDelete = {
                if $0.isContributing {
                    self?.dataSource.items?.remove($0)
                }
            }
        }
        
        userNotifyReceiver = EntryNotifyReceiver<User>().setup { [weak self] receiver in
            receiver.didUpdate = { entry, event in
                if self?.isTopViewController == true {
                    self?.updateEmailConfirmationView()
                }
            }
        }
    }
    
    private func finalizeAppearingOfCandiesView(candiesView: RecentCandiesView) {
        candiesView.candyMetrics.selection = { [weak self] view in
            if view.entry != nil {
                CandyPresenter.present(view, dismissingView: { candy -> UIView? in
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
    
    func createWrap(sender: AnyObject?) {
        let controller = BeginWrapCreationViewController()
        navigationController?.pushViewController(controller, animated:false)
    }
    
    func addPhoto(sender: AnyObject?) {
        openCameraForWrap(topWrap(), animated:false)
    }
    
    func resendConfirmation(sender: AnyObject?) {
        API.resendConfirmation(nil).send({ _ in
            Toast.show("confirmation_resend".ls)
            }, failure: { $0?.show() })
    }
    
    func changeEmail(sender: AnyObject?) {
        navigationController?.push(ChangeProfileViewController())
    }
    
    func settings(sender: AnyObject?) {
        navigationController?.push(SettingsViewController())
    }
}

extension HomeViewController: CaptureCandyViewControllerDelegate {
    
    func captureViewControllerDidCancel(controller: CaptureCandyViewController) {
        dismissViewControllerAnimated(false, completion: nil)
    }
    
    func captureViewController(controller: CaptureCandyViewController, didFinishWithAssets assets: [MutableAsset]) {
        dismissViewControllerAnimated(false, completion: nil)
        if let wrap = controller.wrap {
            if let controller = wrap.createViewControllerIfNeeded() as? WrapViewController {
                controller.segment = .Media
                navigationController?.viewControllers = [self, controller]
            }
            Sound.play()
            wrap.uploadAssets(assets)
        }
    }
}

extension HomeViewController: WrapCellDelegate {
    
    func wrapCellDidBeginPanning(cell: WrapCell) {
        streamView.userInteractionEnabled = false
        streamView.lock()
    }
    
    func wrapCellDidEndPanning(cell: WrapCell, performedAction: Bool) {
        streamView.unlock()
        streamView.userInteractionEnabled = !performedAction
    }
    
    func wrapCell(cell: WrapCell, presentChatViewControllerForWrap wrap: Wrap) {
        streamView.userInteractionEnabled = true
        if wrap.valid {
            let wrapViewController = WrapViewController(wrap: wrap, segment: .Chat)
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
