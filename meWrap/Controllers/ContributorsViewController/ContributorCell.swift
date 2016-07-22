//
//  ContributorCell.swift
//  meWrap
//
//  Created by Yura Granchenko on 08/02/16.
//  Copyright © 2016 Ravenpod. All rights reserved.
//

import Foundation
import SnapKit

protocol ContributorCellDelegate: class {
    func contributorCell(cell: ContributorCell, didRemoveContributor contributor: User)
    func contributorCell(cell: ContributorCell, didInviteContributor contributor: User, completionHandler: Bool -> Void)
    func contributorCell(cell: ContributorCell, isInvitedContributor contributor: User) -> Bool
    func contributorCell(cell: ContributorCell, didToggleMenu contributor: User)
    func contributorCell(cell: ContributorCell, showMenu contributor: User) -> Bool
}

final class ContributorCell: EntryStreamReusableView<AnyObject>, FlowerMenuConstructor {
    
    weak var delegate: ContributorCellDelegate?
    private let nameLabel = Label(preset: .Normal, weight: .Regular, textColor: Color.grayDark)
    private let avatarView = StatusUserAvatarView(cornerRadius: 24)
    private let slideMenuButton = UIButton(type: .Custom)
    private let infoLabel = Label(preset: .Small, textColor: Color.grayLight)
    
    private let streamView = StreamView()
    private lazy var dataSource: StreamDataSource<[User]> = StreamDataSource(streamView: self.streamView)
    
    override func layoutWithMetrics(metrics: StreamMetricsProtocol) {
        avatarView.startReceivingStatusUpdates()
        streamView.layout = HorizontalStreamLayout()
        streamView.showsHorizontalScrollIndicator = false
        streamView.pagingEnabled = true
        streamView.bounces = false
        avatarView.placeholder.font = UIFont.icons(24)
        infoLabel.numberOfLines = 0
        slideMenuButton.addTarget(self, touchUpInside: #selector(self.toggleSlideMenu(_:)))
        slideMenuButton.titleLabel?.font = UIFont.icons(24)
        slideMenuButton.setTitle("p", forState: .Normal)
        slideMenuButton.setTitleColor(Color.grayLightest, forState: .Normal)
        slideMenuButton.contentHorizontalAlignment = .Right
        slideMenuButton.contentVerticalAlignment = .Center
        slideMenuButton.titleEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 12)
        add(streamView) { $0.edges.equalTo(self) }
        let contentView = streamView.add(UIView()) {
            $0.leading.top.equalTo(streamView)
            $0.size.equalTo(streamView)
        }
        contentView.add(avatarView) {
            $0.leading.top.equalTo(contentView).inset(12)
            $0.size.equalTo(48)
        }
        contentView.add(nameLabel) {
            $0.top.equalTo(avatarView)
            $0.leading.equalTo(avatarView.snp_trailing).offset(12)
            $0.trailing.lessThanOrEqualTo(contentView).inset(24)
        }
        contentView.add(infoLabel) {
            $0.top.equalTo(nameLabel.snp_bottom)
            $0.leading.equalTo(avatarView.snp_trailing).offset(12)
            $0.trailing.lessThanOrEqualTo(contentView).inset(24)
        }
        contentView.add(slideMenuButton) { $0.edges.equalTo(contentView) }
        add(SeparatorView(color: Color.grayLightest)) { (make) -> Void in
            make.leading.trailing.bottom.equalTo(self)
            make.height.equalTo(1)
        }
        
        FlowerMenu.sharedMenu.registerView(self)
        addMetrics(removeMetrics)
        addMetrics(resendMetrics)
        addMetrics(spinnerMetics)
        addMetrics(resendDoneMetrics)
    }
    
    private lazy var removeMetrics: StreamMetrics<StreamReusableView> = StreamMetrics(layoutBlock: { (view) -> Void in
        let button = PressButton(preset: .Small, weight: .Light, textColor: UIColor.whiteColor())
        button.backgroundColor = Color.dangerRed
        button.normalColor = Color.dangerRed
        button.setTitle("Remove", forState: .Normal)
        button.addTarget(self, touchUpInside: #selector(self.remove(_:)))
        view.add(button) { $0.edges.equalTo(view) }
        }, size: 76)
    
    private lazy var resendMetrics: StreamMetrics<StreamReusableView> = StreamMetrics(layoutBlock: { (view) -> Void in
        let button = PressButton(preset: .Small, weight: .Light, textColor: UIColor.whiteColor())
        button.backgroundColor = Color.orange
        button.normalColor = Color.orange
        button.titleLabel?.numberOfLines = 2
        button.titleLabel?.textAlignment = .Center
        button.setTitle("Resend invite", forState: .Normal)
        button.addTarget(self, touchUpInside: #selector(self.resendInvite(_:)))
        view.add(button) { $0.edges.equalTo(view) }
        }, size: 76)
    
    private let spinnerMetics = StreamMetrics<StreamReusableView>(layoutBlock: { (view) -> Void in
        view.backgroundColor = Color.orange
        let spinner = view.add(UIActivityIndicatorView(activityIndicatorStyle: .White)) { $0.center.equalTo(view) }
        spinner.startAnimating()
        }, size: 76)
    
    private let resendDoneMetrics = StreamMetrics<StreamReusableView>(layoutBlock: { (view) -> Void in
        view.backgroundColor = Color.orange
        view.add(Label(icon: "E", size: 36)) { $0.center.equalTo(view) }
        }, size: 76)
    
    private func addMetrics<T: StreamMetricsProtocol>(metrics: T) -> T {
        metrics.hidden = true
        return self.dataSource.addSectionHeaderMetrics(metrics)
    }
    
    override func didDequeue() {
        super.didDequeue()
        removeMetrics.hidden =          true
        resendMetrics.hidden =          true
        spinnerMetics.hidden =          true
        resendDoneMetrics.hidden =      true
    }
    
    weak var wrap: Wrap?
    
    func constructFlowerMenu(menu: FlowerMenu) {
        if let user = entry as? User where user.current == false {
            menu.addCallAction({
                CallCenter.center.call(user)
            })
        }
    }
    
    override func setup(entry: AnyObject) {
        if let user = entry as? User {
            setupUser(user)
        } else if let invitee = entry as? Invitee {
            setupInvitee(invitee)
        }
    }
    
    private func setupUser(user: User) {
        guard let wrap = wrap else { return }
        let deletable = wrap.contributor?.current == true && !user.current
        removeMetrics.hidden = !deletable
        let signupPending = user.signupPending
        if signupPending {
            let inviteResent = delegate?.contributorCell(self, isInvitedContributor: user) ?? false
            resendDoneMetrics.hidden = !inviteResent
            resendMetrics.hidden = inviteResent
        }
        streamView.layoutIfNeeded()
        streamView.layout.offset = width
        dataSource.reload()
        let isCreator = wrap.contributor == user
        let name = user.current ? "you".ls : user.name
        nameLabel.text = isCreator ? String(format: "formatted_owner".ls, name ?? "") : name
        infoLabel.text = user.contributorInfo()
        avatarView.wrap = wrap
        avatarView.user = user
        slideMenuButton.hidden = !deletable && !signupPending
        let showMenu = delegate?.contributorCell(self, showMenu: user) ?? false
        setMenuHidden(!showMenu, animated: false)
    }
    
    private func setupInvitee(invitee: Invitee) {
        streamView.layoutIfNeeded()
        streamView.layout.offset = width
        dataSource.reload()
        nameLabel.text = invitee.user?.name ?? invitee.name
        infoLabel.text = invitee.contributorInfo()
        avatarView.wrap = nil
        avatarView.user = nil
        slideMenuButton.hidden = true
        setMenuHidden(true, animated: false)
    }
    
    func setMenuHidden(hidden: Bool, animated: Bool) {
        if hidden {
            streamView.setMinimumContentOffsetAnimated(animated)
        } else {
            streamView.setMaximumContentOffsetAnimated(animated)
        }
    }
    
    //MARK: Action
    
    @IBAction func toggleSlideMenu(sender: AnyObject) {
        setMenuHidden(streamView.contentOffset.x != 0, animated: true)
        guard let user = entry as? User else { return }
        delegate?.contributorCell(self, didToggleMenu: user)
    }
    
    @IBAction func remove(sender: AnyObject) {
        guard let user = entry as? User else { return }
        delegate?.contributorCell(self, didRemoveContributor: user)
    }
    
    @IBAction func resendInvite(sender: Button) {
        resendMetrics.hidden = true
        spinnerMetics.hidden = false
        dataSource.reload()
        sender.userInteractionEnabled = false
        guard let user = entry as? User else { return }
        delegate?.contributorCell(self, didInviteContributor: user, completionHandler: { [weak self] (success) -> Void in
            sender.userInteractionEnabled = false
            self?.resendMetrics.hidden = success
            self?.resendDoneMetrics.hidden = !success
            self?.spinnerMetics.hidden = true
            self?.dataSource.reload()
        })
    }
}
