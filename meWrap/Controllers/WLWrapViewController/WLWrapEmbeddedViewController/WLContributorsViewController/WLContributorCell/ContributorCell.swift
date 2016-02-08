//
//  ContributorCell.swift
//  meWrap
//
//  Created by Yura Granchenko on 08/02/16.
//  Copyright © 2016 Ravenpod. All rights reserved.
//

import Foundation

@objc protocol ContributorCellDelegate {
    func contributorCell(cell: ContributorCell, didRemoveContributor contributor: User)
    func contributorCell(cell: ContributorCell, didInviteContributor contributor: User, completionHandler: Bool -> Void)
    func contributorCell(cell: ContributorCell, isInvitedContributor contributor: User) -> Bool
    func contributorCell(cell: ContributorCell, isCreator contributor: User) -> Bool
    func contributorCell(cell: ContributorCell, didToggleMenu contributor: User)
    func contributorCell(cell: ContributorCell, showMenu contributor: User) -> Bool
    
}

class ContributorCell: StreamReusableView {
    
    @IBOutlet weak var delegate: ContributorCellDelegate!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var avatarView: ImageView!
    @IBOutlet weak var phoneLabel: UILabel!
    @IBOutlet weak var slideMenuButton: Button!
    @IBOutlet weak var inviteLabel: UILabel!
    @IBOutlet weak var pandingLabel: UILabel!
    @IBOutlet weak var streamView: StreamView!
    lazy var dataSource: StreamDataSource = StreamDataSource(streamView: self.streamView)
    lazy var removeMetrics: StreamMetrics = self.dataSource.addMetrics(StreamMetrics(identifier: "ContributorRemoveCell", size: 76))
    lazy var resendMetrics: StreamMetrics = self.dataSource.addMetrics(StreamMetrics(identifier: "ContributorResendCell", size: 76))
    lazy var spinnerMetics: StreamMetrics = self.dataSource.addMetrics(StreamMetrics(identifier: "ContributorSpinnerCell", size: 76))
    lazy var resendDoneMetrics: StreamMetrics = self.dataSource.addMetrics(StreamMetrics(identifier: "ContributorResendDoneCell", size: 76))
    
    class func invitationHintText(user: User) -> String {
        let invitedAt = user.invitedAt
        if user.isInvited {
            return String(format: "invite_status_swipe_to".ls, invitedAt.stringWithDateStyle(.ShortStyle) ?? "")
        } else {
            return "signup_status".ls
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        removeMetrics.nibOwner =        self
        resendMetrics.nibOwner =        self
        spinnerMetics.nibOwner =        self
        resendDoneMetrics.nibOwner =    self
        removeMetrics.hidden =          true
        resendMetrics.hidden =          true
        spinnerMetics.hidden =          true
        resendDoneMetrics.hidden =      true
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
        if let _ = delegate?.contributorCell(self, isCreator: user) {
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
            resendDoneMetrics.hidden = invited ?? true
            resendMetrics.hidden = invited ?? false
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
        setMenuHidden(showMenu ?? false, animated: false)
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
