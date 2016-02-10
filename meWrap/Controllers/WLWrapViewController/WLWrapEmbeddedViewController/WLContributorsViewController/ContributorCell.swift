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
    func contributorCell(cell: ContributorCell, isCreator contributor: User) -> Bool
    func contributorCell(cell: ContributorCell, didToggleMenu contributor: User)
    func contributorCell(cell: ContributorCell, showMenu contributor: User) -> Bool
}

class ContributorCell: StreamReusableView {
    
    weak var delegate: ContributorCellDelegate?
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var avatarView: ImageView!
    @IBOutlet weak var phoneLabel: UILabel!
    @IBOutlet weak var slideMenuButton: Button!
    @IBOutlet weak var inviteLabel: UILabel!
    @IBOutlet weak var pandingLabel: UILabel!
    @IBOutlet weak var streamView: StreamView!
    lazy var dataSource: StreamDataSource = StreamDataSource(streamView: self.streamView)
    
    lazy var removeMetrics: StreamMetrics = {
        let loader = LayoutStreamLoader<StreamReusableView>(layoutBlock: { (view) -> Void in
            let button = PressButton(type: .Custom)
            button.backgroundColor = Color.dangerRed
            button.normalColor = Color.dangerRed
            button.preset = FontPreset.Small.rawValue
            button.titleLabel?.font = UIFont.lightFontSmall()
            button.setTitle("Remove", forState: .Normal)
            button.addTarget(self, action: "remove:", forControlEvents: .TouchUpInside)
            view.addSubview(button)
            button.snp_makeConstraints(closure: { $0.edges.equalTo(view) })
        })
        return self.addMetrics(StreamMetrics(loader: loader, size: 76))
    }()
    
    lazy var resendMetrics: StreamMetrics = {
        let loader = LayoutStreamLoader<StreamReusableView>(layoutBlock: { (view) -> Void in
            let button = PressButton(type: .Custom)
            button.backgroundColor = Color.orange
            button.normalColor = Color.orange
            button.preset = FontPreset.Small.rawValue
            button.titleLabel?.font = UIFont.lightFontSmall()
            button.titleLabel?.numberOfLines = 2
            button.titleLabel?.textAlignment = .Center
            button.setTitle("Resend invite", forState: .Normal)
            button.addTarget(self, action: "resendInvite:", forControlEvents: .TouchUpInside)
            view.addSubview(button)
            button.snp_makeConstraints(closure: { $0.edges.equalTo(view) })
        })
        return self.addMetrics(StreamMetrics(loader: loader, size: 76))
    }()
    
    lazy var spinnerMetics: StreamMetrics = {
        let loader = LayoutStreamLoader<StreamReusableView>(layoutBlock: { (view) -> Void in
            view.backgroundColor = Color.orange
            let spinner = UIActivityIndicatorView(activityIndicatorStyle: .White)
            view.addSubview(spinner)
            spinner.startAnimating()
            spinner.snp_makeConstraints(closure: { $0.center.equalTo(view) })
        })
        return self.addMetrics(StreamMetrics(loader: loader, size: 76))
    }()
    
    lazy var resendDoneMetrics: StreamMetrics = {
        let loader = LayoutStreamLoader<StreamReusableView>(layoutBlock: { (view) -> Void in
            view.backgroundColor = Color.orange
            let icon = UILabel()
            icon.font = UIFont(name: "icons", size: 36)
            icon.text = "l"
            icon.textColor = UIColor.whiteColor()
            view.addSubview(icon)
            icon.snp_makeConstraints(closure: { $0.center.equalTo(view) })
        })
        return self.addMetrics(StreamMetrics(loader: loader, size: 76))
    }()
    
    class func invitationHintText(user: User) -> String {
        let invitedAt = user.invitedAt
        if user.isInvited {
            return String(format: "invite_status_swipe_to".ls, invitedAt.stringWithDateStyle(.ShortStyle))
        } else {
            return "signup_status".ls
        }
    }
    
    private func addMetrics(metrics: StreamMetrics) -> StreamMetrics {
        metrics.hidden = true
        return self.dataSource.addMetrics(metrics)
    }
    
    override func didDequeue() {
        super.didDequeue()
        removeMetrics.hidden =          true
        resendMetrics.hidden =          true
        spinnerMetics.hidden =          true
        resendDoneMetrics.hidden =      true
    }
    
    override func setup(entry: AnyObject) {
        guard let user = entry as? User else { return }
        var deletable = false
        if delegate?.contributorCell(self, isCreator: user) == true {
            deletable = !user.current
        } else {
            deletable = false
        }
        if deletable {
            removeMetrics.hidden = false
        }
        let canBeInvited = user.isInvited
        if canBeInvited {
            let invited = delegate?.contributorCell(self, isInvitedContributor: user)
            resendDoneMetrics.hidden = invited != true
            resendMetrics.hidden = invited == true
        }
        layoutIfNeeded()
        dataSource.layoutOffset = width
        dataSource.items = [user]
        let isCreator = delegate?.contributorCell(self, isCreator: user)
        let userNameText = user.current ? "you".ls : user.name
        nameLabel.text = isCreator ?? false ? String(format: "formatted_owner".ls, userNameText ?? "") : userNameText
        pandingLabel.text = canBeInvited ? "sign_up_pending".ls : ""
        phoneLabel.text = user.securePhones
        let url = user.avatar?.small
        if !canBeInvited && url?.isEmpty ?? false {
            avatarView.defaultBackgroundColor = Color.orange
        } else {
            avatarView.defaultBackgroundColor = Color.grayLighter
        }
        avatarView.url = url
        inviteLabel.text = ContributorCell.invitationHintText(user)
        slideMenuButton.hidden = !deletable && !canBeInvited
        let showMenu = delegate?.contributorCell(self, showMenu: user)
        setMenuHidden(showMenu != true, animated: false)
    }
    
    func setMenuHidden(hidden: Bool, animated: Bool) {
        if hidden {
            dataSource.streamView?.setMinimumContentOffsetAnimated(animated)
        } else {
            dataSource.streamView?.setMaximumContentOffsetAnimated(animated)
        }
    }
    
    //MARK: Action
    
    @IBAction func toggleSlideMenu(sender: AnyObject) {
        setMenuHidden(dataSource.streamView?.contentOffset.x != 0, animated: true)
        if let user = entry as? User {
            delegate?.contributorCell(self, didToggleMenu: user)
        }
    }
    
    @IBAction func remove(sender: AnyObject) {
        if let user = entry as? User {
            delegate?.contributorCell(self, didRemoveContributor: user)
        }
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
