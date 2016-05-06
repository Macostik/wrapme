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

final class ContributorCell: EntryStreamReusableView<User> {
    
    weak var delegate: ContributorCellDelegate?
    private let nameLabel = Label(preset: .Normal, weight: .Regular, textColor: Color.grayDark)
    private let avatarView = StatusUserAvatarView(cornerRadius: 24)
    private let slideMenuButton = UIButton(type: .Custom)
    private let infoLabel = Label(preset: .Small, textColor: Color.grayLight)
    
    private let streamView = StreamView()
    lazy var dataSource: StreamDataSource<[User]> = StreamDataSource(streamView: self.streamView)
    
    override func layoutWithMetrics(metrics: StreamMetricsProtocol) {
        avatarView.startReceivingStatusUpdates()
        streamView.layout = HorizontalStreamLayout()
        streamView.showsHorizontalScrollIndicator = false
        streamView.pagingEnabled = true
        streamView.bounces = false
        avatarView.defaultIconSize = 24
        infoLabel.numberOfLines = 0
        slideMenuButton.addTarget(self, action: #selector(ContributorCell.toggleSlideMenu(_:)), forControlEvents: .TouchUpInside)
        slideMenuButton.titleLabel?.font = UIFont.icons(24)
        slideMenuButton.setTitle("p", forState: .Normal)
        slideMenuButton.setTitleColor(Color.grayLightest, forState: .Normal)
        slideMenuButton.contentHorizontalAlignment = .Right
        slideMenuButton.contentVerticalAlignment = .Center
        slideMenuButton.titleEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 12)
        addSubview(streamView)
        let contentView = UIView()
        streamView.addSubview(contentView)
        contentView.addSubview(avatarView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(infoLabel)
        contentView.addSubview(slideMenuButton)
        streamView.snp_makeConstraints { $0.edges.equalTo(self) }
        contentView.snp_makeConstraints {
            $0.leading.top.equalTo(streamView)
            $0.size.equalTo(streamView)
        }
        avatarView.snp_makeConstraints {
            $0.leading.top.equalTo(contentView).inset(12)
            $0.size.equalTo(48)
        }
        nameLabel.snp_makeConstraints {
            $0.top.equalTo(avatarView)
            $0.leading.equalTo(avatarView.snp_trailing).offset(12)
            $0.trailing.lessThanOrEqualTo(contentView).inset(24)
        }
        infoLabel.snp_makeConstraints {
            $0.top.equalTo(nameLabel.snp_bottom)
            $0.leading.equalTo(avatarView.snp_trailing).offset(12)
            $0.trailing.lessThanOrEqualTo(contentView).inset(24)
        }
        slideMenuButton.snp_makeConstraints {
            $0.edges.equalTo(contentView)
        }
        
        let separator = SeparatorView(color: Color.grayLightest, contentMode: .Bottom)
        addSubview(separator)
        separator.snp_makeConstraints { (make) -> Void in
            make.leading.trailing.bottom.equalTo(self)
            make.height.equalTo(1)
        }
    }
    
    lazy var removeMetrics: StreamMetricsProtocol = {
        let metrics = StreamMetrics<StreamReusableView>(layoutBlock: { (view) -> Void in
            let button = PressButton(type: .Custom)
            button.backgroundColor = Color.dangerRed
            button.normalColor = Color.dangerRed
            button.preset = Font.Small.rawValue
            button.titleLabel?.font = UIFont.lightFontSmall()
            button.setTitle("Remove", forState: .Normal)
            button.addTarget(self, action: #selector(self.remove(_:)), forControlEvents: .TouchUpInside)
            view.addSubview(button)
            button.snp_makeConstraints(closure: { $0.edges.equalTo(view) })
        }, size: 76)
        return self.addMetrics(metrics)
    }()
    
    lazy var resendMetrics: StreamMetricsProtocol = {
        let metrics = StreamMetrics<StreamReusableView>(layoutBlock: { (view) -> Void in
            let button = PressButton(type: .Custom)
            button.backgroundColor = Color.orange
            button.normalColor = Color.orange
            button.preset = Font.Small.rawValue
            button.titleLabel?.font = UIFont.lightFontSmall()
            button.titleLabel?.numberOfLines = 2
            button.titleLabel?.textAlignment = .Center
            button.setTitle("Resend invite", forState: .Normal)
            button.addTarget(self, action: #selector(ContributorCell.resendInvite(_:)), forControlEvents: .TouchUpInside)
            view.addSubview(button)
            button.snp_makeConstraints(closure: { $0.edges.equalTo(view) })
        }, size: 76)
        return self.addMetrics(metrics)
    }()
    
    lazy var spinnerMetics: StreamMetricsProtocol = {
        let metrics = StreamMetrics<StreamReusableView>(layoutBlock: { (view) -> Void in
            view.backgroundColor = Color.orange
            let spinner = UIActivityIndicatorView(activityIndicatorStyle: .White)
            view.addSubview(spinner)
            spinner.startAnimating()
            spinner.snp_makeConstraints(closure: { $0.center.equalTo(view) })
        }, size: 76)
        return self.addMetrics(metrics)
    }()
    
    lazy var resendDoneMetrics: StreamMetricsProtocol = {
        let metrics = StreamMetrics<StreamReusableView>(layoutBlock: { (view) -> Void in
            view.backgroundColor = Color.orange
            let icon = Label(icon: "E", size: 36)
            view.addSubview(icon)
            icon.snp_makeConstraints(closure: { $0.center.equalTo(view) })
        }, size: 76)
        return self.addMetrics(metrics)
    }()
    
    private func addMetrics<T: StreamMetricsProtocol>(metrics: T) -> T {
        metrics.hidden = true
        return self.dataSource.addHeaderMetrics(metrics)
    }
    
    override func didDequeue() {
        super.didDequeue()
        removeMetrics.hidden =          true
        resendMetrics.hidden =          true
        spinnerMetics.hidden =          true
        resendDoneMetrics.hidden =      true
    }
    
    weak var wrap: Wrap?
    
    override func setup(user: User) {
        guard let currentUser = User.currentUser else { return }
        
        let deletable = wrap?.contributor == currentUser && !user.current
        removeMetrics.hidden = !deletable
        
        let isInvited = user.isInvited
        if isInvited {
            let inviteResent = delegate?.contributorCell(self, isInvitedContributor: user) ?? false
            resendDoneMetrics.hidden = !inviteResent
            resendMetrics.hidden = inviteResent
        }
        streamView.layoutIfNeeded()
        dataSource.layoutOffset = width
        dataSource.reload()
        let isCreator = wrap?.contributor == user ?? false
        let name = user.current ? "you".ls : user.name
        nameLabel.text = isCreator ? String(format: "formatted_owner".ls, name ?? "") : name
        infoLabel.text = user.contributorInfo()
        avatarView.wrap = wrap
        avatarView.user = user
        slideMenuButton.hidden = !deletable && !isInvited
        let showMenu = delegate?.contributorCell(self, showMenu: user) ?? false
        setMenuHidden(!showMenu, animated: false)
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
        if let user = entry {
            delegate?.contributorCell(self, didToggleMenu: user)
        }
    }
    
    @IBAction func remove(sender: AnyObject) {
        if let user = entry {
            delegate?.contributorCell(self, didRemoveContributor: user)
        }
    }
    
    @IBAction func resendInvite(sender: Button) {
        resendMetrics.hidden = true
        spinnerMetics.hidden = false
        dataSource.reload()
        sender.userInteractionEnabled = false
        guard let user = entry else { return }
        delegate?.contributorCell(self, didInviteContributor: user, completionHandler: { [weak self] (success) -> Void in
            sender.userInteractionEnabled = false
            self?.resendMetrics.hidden = success
            self?.resendDoneMetrics.hidden = !success
            self?.spinnerMetics.hidden = true
            self?.dataSource.reload()
        })
    }
}
