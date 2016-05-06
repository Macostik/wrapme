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

final class ContributorsViewController: BaseViewController {
    
    weak var wrap: Wrap?
    
    @IBOutlet weak var streamView: StreamView!
    
    private lazy var dataSource: StreamDataSource<[User]> = StreamDataSource(streamView: self.streamView)
    
    @IBOutlet weak var addFriendView: UIView!
    
    @IBOutlet var restrictedInvitePrioritizer: LayoutPrioritizer!
    
    private var invitedContributors = Set<User>()
    
    private var removedContributors = Set<User>()
    
    private weak var contributiorWithOpenedMenu: User?
    
    private var contributors: [User] = [] {
        didSet {
            if contributors != oldValue {
                dataSource.items = contributors
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        dataSource.addMetrics(specify(StreamMetrics<ContributorCell>(), {
            $0.modifyItem = { item in
                let nameFont = UIFont.fontNormal()
                let infoFont = UIFont.lightFontSmall()
                let contributor = item.entry as! User
                let infoHeight = contributor.contributorInfo().heightWithFont(infoFont, width:Constants.screenWidth - HorizontalIndent)
                item.size = max(infoHeight + nameFont.lineHeight + VerticalIndent, MinHeight) + 1
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
        
        if let wrap = wrap {
            API.contributors(wrap).send({ [weak self] _ in
                self?.updateContributors()
                }) { [weak self] (error) -> Void in
                    self?.dataSource.reload()
                    error?.showNonNetworkError()
            }
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if let wrap = wrap, let contributor = wrap.contributor where !contributor.current {
            restrictedInvitePrioritizer.defaultState = !wrap.isRestrictedInvite
        }
    }
    
    private func updateContributors() {
        contributors = wrap?.contributors.subtract(removedContributors).sort {
            if $0.current {
                return false
            } else if $1.current {
                return true
            } else {
                return $0.name < $1.name
            }
            } ?? []
    }
}

extension ContributorsViewController: ContributorCellDelegate {
    
    func contributorCell(cell: ContributorCell, didRemoveContributor contributor: User) {
        
        guard let wrap = wrap else { return }
        
        if let index = contributors.indexOf(contributor) {
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
        
        guard let wrap = wrap else { return }
        
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
            NSObject.cancelPreviousPerformRequestsWithTarget(self, selector:#selector(ContributorsViewController.hideMenuForContributor(_:)), object:contributor)
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
        if let wrap = wrap, let contributor = wrap.contributor where !contributor.current {
            restrictedInvitePrioritizer.setDefaultState(!wrap.isRestrictedInvite, animated: viewAppeared)
        }
    }
}
