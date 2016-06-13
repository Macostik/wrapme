//
//  ContributorsViewController.swift
//  meWrap
//
//  Created by Sergey Maximenko on 2/10/16.
//  Copyright © 2016 Ravenpod. All rights reserved.
//

import UIKit

private let VerticalIndent: CGFloat = 24
private let HorizontalIndent: CGFloat = 96.0
private let MinHeight: CGFloat = 72.0

final class InviteeCell: EntryStreamReusableView<Invitee> {
    
}

final class ContributorsViewController: BaseViewController {
    
    let wrap: Wrap
    
    private let streamView = StreamView()
    
    private lazy var dataSource: StreamDataSource<[AnyObject]> = StreamDataSource(streamView: self.streamView)
    
    private let addFriendView = Button(type: .Custom)
    
    private var invitedContributors = Set<User>()
    
    private var removedContributors = Set<User>()
    
    private weak var contributiorWithOpenedMenu: User?
    
    private var contributors: [AnyObject] = [] {
        didSet {
            dataSource.items = contributors
        }
    }
    
    required init(wrap: Wrap) {
        self.wrap = wrap
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        super.loadView()
        view.backgroundColor = UIColor.whiteColor()
        streamView.alwaysBounceVertical = true
        streamView.delaysContentTouches = false
        
        let navigationBar = UIView()
        
        view.addSubview(addFriendView)
        view.addSubview(navigationBar)
        
        addFriendView.snp_makeConstraints { (make) in
            make.centerX.equalTo(view)
            make.top.equalTo(navigationBar.snp_bottom)
            make.height.equalTo(44)
        }
        
        let addFriendIcon = Label(icon: "2", size: 19, textColor: Color.grayDark)
        let addFriendLabel = Label(preset: .Small, weight: .Regular, textColor: Color.grayDark)
        addFriendLabel.text = "add_friend...".ls
        addFriendIcon.highlightedTextColor = Color.grayLighter
        addFriendLabel.highlightedTextColor = Color.grayLighter
        addFriendView.highlightings = [addFriendIcon, addFriendLabel]
        addFriendView.addTarget(self, touchUpInside: #selector(self.addFriend(_:)))
        
        addFriendView.add(addFriendIcon) { (make) in
            make.leading.top.bottom.equalTo(addFriendView)
        }
        
        addFriendView.add(addFriendLabel) { (make) in
            make.centerY.trailing.equalTo(addFriendView)
            make.leading.equalTo(addFriendIcon.snp_trailing).offset(3)
        }
        
        view.add(streamView) { (make) in
            make.top.equalTo(addFriendView.snp_bottom)
            make.leading.bottom.trailing.equalTo(view)
        }
        
        navigationBar.backgroundColor = Color.orange
        navigationBar.snp_makeConstraints { (make) in
            make.leading.top.trailing.equalTo(view)
            make.height.equalTo(64)
        }
        navigationBar.add(backButton(UIColor.whiteColor())) { (make) in
            make.leading.equalTo(navigationBar).inset(12)
            make.centerY.equalTo(navigationBar).offset(10)
        }
        let title = Label(preset: .Large, weight: .Regular, textColor: UIColor.whiteColor())
        title.text = "friends".ls
        navigationBar.add(title) { (make) in
            make.centerX.equalTo(navigationBar)
            make.centerY.equalTo(navigationBar).offset(10)
        }
        self.navigationBar = navigationBar
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        dataSource.addMetrics(specify(StreamMetrics<ContributorCell>(), {
            $0.modifyItem = { item in
                let nameFont = UIFont.fontNormal()
                let infoFont = UIFont.lightFontSmall()
                if let contributor = item.entry as? Contributor {
                    let infoHeight = contributor.contributorInfo().heightWithFont(infoFont, width:Constants.screenWidth - HorizontalIndent)
                    item.size = max(infoHeight + nameFont.lineHeight + VerticalIndent, MinHeight) + 1
                } else {
                    item.size = max(infoFont.lineHeight + nameFont.lineHeight + VerticalIndent, MinHeight) + 1
                }
            }
            $0.prepareAppearing = { [weak self] item, view in
                view.wrap = self?.wrap
                view.delegate = self
            }
        }))
        
        streamView.contentInset = UIEdgeInsetsMake(0, 0, 44, 0)
        streamView.scrollIndicatorInsets = streamView.contentInset
        
        Wrap.notifier().addReceiver(self)
        
        updateContributors()
        
        API.contributors(wrap).send({ [weak self] _ in
            self?.updateContributors()
        }) { [weak self] (error) -> Void in
            self?.dataSource.reload()
            error?.showNonNetworkError()
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if let contributor = wrap.contributor where !contributor.current {
            setAddFriendViewHidden(wrap.isRestrictedInvite, animated: false)
        }
    }
    
    private var addFriendViewHidden = false
    
    private func setAddFriendViewHidden(hidden: Bool, animated: Bool) {
        guard hidden != addFriendViewHidden else { return }
        addFriendViewHidden = hidden
        addFriendView.snp_remakeConstraints { (make) in
            make.centerX.equalTo(view)
            if hidden {
                make.bottom.equalTo(navigationBar!)
            } else {
                make.top.equalTo(navigationBar!.snp_bottom)
            }
            make.height.equalTo(44)
        }
        if animated {
            UIView.animateWithDuration(0.3, animations: { 
                self.view.layoutIfNeeded()
            })
        }
    }
    
    private func updateContributors() {
        var contributors: [AnyObject] = Array(wrap.contributors.subtract(removedContributors))
        wrap.invitees.all({
            contributors.append($0)
        })
        self.contributors = contributors.sort {
            let lhs = $0 as! Contributor
            let rhs = $1 as! Contributor
            if lhs.current {
                return false
            } else if rhs.current {
                return true
            } else {
                return lhs.displayName < rhs.displayName
            }
        }
    }
    
    @objc private func addFriend(sender: AnyObject) {
        let controller = Storyboard.AddFriends.instantiate()
        controller.wrap = wrap
        navigationController?.pushViewController(controller, animated: false)
    }
}

extension ContributorsViewController: ContributorCellDelegate {
    
    func contributorCell(cell: ContributorCell, didRemoveContributor contributor: User) {
        
        if let index = contributors.indexOf({ $0 === contributor }) {
            contributors.removeAtIndex(index)
        }
        
        removedContributors.insert(contributor)
        
        API.removeContributors([contributor], wrap: wrap).send({ [weak self] (_) -> Void in
            self?.removedContributors.remove(contributor)
            if self?.contributiorWithOpenedMenu == contributor {
                self?.contributiorWithOpenedMenu = nil
            }
            }, failure: { [weak self] (error) -> Void in
                error?.show()
                self?.removedContributors.remove(contributor)
                self?.updateContributors()
            })
    }
    
    func hideMenuForContributor(contributor: User) {
        if contributiorWithOpenedMenu == contributor {
            contributiorWithOpenedMenu = nil
            for item in streamView.visibleItems() {
                if let cell = item.view as? ContributorCell where cell.entry === contributor {
                    cell.setMenuHidden(true, animated: true)
                    break
                }
            }
        }
    }
    
    func contributorCell(cell: ContributorCell, didInviteContributor contributor: User, completionHandler: Bool -> Void) {
        
        API.resendInvite(wrap, user: contributor).send({ [weak self] (_) -> Void in
            completionHandler(true)
            self?.invitedContributors.insert(contributor)
            self?.enqueueSelector(#selector(ContributorsViewController.hideMenuForContributor(_:)), argument: contributor, delay: 3.0)
            }) { (error) -> Void in
                error?.show()
                completionHandler(false)
        }
    }
    
    func contributorCell(cell: ContributorCell, isInvitedContributor contributor: User) -> Bool {
        return invitedContributors.contains(contributor)
    }
    
    func contributorCell(cell: ContributorCell, didToggleMenu contributor: User) {
        if let contributor = contributiorWithOpenedMenu {
            NSObject.cancelPreviousPerformRequestsWithTarget(self, selector:#selector(self.hideMenuForContributor(_:)), object:contributor)
        }
        
        if contributiorWithOpenedMenu == contributor {
            contributiorWithOpenedMenu = nil
        } else {
            contributiorWithOpenedMenu = contributor
            for item in streamView.visibleItems() {
                if let cell = item.view as? ContributorCell where cell.entry !== contributor {
                    cell.setMenuHidden(true, animated: true)
                }
            }
        }
    }
    
    func contributorCell(cell: ContributorCell, showMenu contributor: User) -> Bool {
        return contributiorWithOpenedMenu == contributor
    }
}

extension ContributorsViewController: EntryNotifying {
    
    func notifier(notifier: EntryNotifier, shouldNotifyOnEntry entry: Entry) -> Bool {
        return wrap == entry
    }
    
    func notifier(notifier: EntryNotifier, didUpdateEntry entry: Entry, event: EntryUpdateEvent) {
        if event == .ContributorsChanged {
            updateContributors()
        }
        if let contributor = wrap.contributor where !contributor.current {
            setAddFriendViewHidden(wrap.isRestrictedInvite, animated: viewAppeared)
        }
    }
}
