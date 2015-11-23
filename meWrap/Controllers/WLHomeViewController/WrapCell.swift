//
//  WrapCell.swift
//  meWrap
//
//  Created by Sergey Maximenko on 11/20/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit

@objc
protocol WrapCellDelegate: NSObjectProtocol {

    func wrapCellDidBeginPanning(cell: WrapCell)
    func wrapCellDidEndPanning(cell: WrapCell, performedAction:Bool)
    func wrapCell(cell: WrapCell, presentChatViewControllerForWrap wrap: Wrap)
    func wrapCell(cell: WrapCell, presentCameraViewControllerForWrap wrap: Wrap)

}

class WrapCell: StreamReusableView {
    
    @IBOutlet weak var delegate: WrapCellDelegate?
    
    @IBOutlet weak var coverView: WLWrapStatusImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel?
    
    @IBOutlet weak var wrapNotificationLabel: WLBadgeLabel?
    @IBOutlet weak var chatNotificationLabel: WLBadgeLabel?
    @IBOutlet weak var chatButton: UIButton?
    
    @IBOutlet weak var creatorName: UILabel?
    
    @IBOutlet var datePrioritizer: LayoutPrioritizer?
    
    @IBOutlet var chatPrioritizer: LayoutPrioritizer?
    
    @IBOutlet weak var liveBroadcastIndicator: UILabel?
    @IBOutlet var nameLeadingPrioritizer: LayoutPrioritizer?
    
    var swipeAction: SwipeAction?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        guard let _ = dateLabel else {
            return
        }
        let swipeAction = SwipeAction(view: self)
        
        swipeAction.shouldBeginPanning = { [weak self] (action) -> Bool in
            guard let wrap = self?.entry as? Wrap else {
                return false
            }
            if wrap.isPublic {
                if wrap.isContributing {
                    return self?.swipeAction?.direction == .Left
                } else {
                    return false
                }
            } else {
                return true
            }
        }
        
        swipeAction.didBeginPanning = { [weak self] (action) -> Void in
            if let cell = self {
                cell.delegate?.wrapCellDidBeginPanning(cell)
            }
        }
        
        swipeAction.didEndPanning = { [weak self] (action, performedAction) -> Void in
            if let cell = self {
                cell.delegate?.wrapCellDidEndPanning(cell, performedAction: performedAction)
            }
        }
        
        swipeAction.didPerformAction = { [weak self] (action, direction) -> Void in
            if let cell = self, let wrap = cell.entry as? Wrap {
                if action.direction == .Right {
                    cell.delegate?.wrapCell(cell, presentChatViewControllerForWrap: wrap)
                } else if action.direction == .Left {
                    cell.delegate?.wrapCell(cell, presentCameraViewControllerForWrap: wrap)
                }
            }
        }
        
        self.swipeAction = swipeAction
    }
    
    override func didDequeue() {
        super.didDequeue()
        swipeAction?.reset()
    }
    
    override func setup(entry: AnyObject!) {
        guard let wrap = entry as? Wrap else {
            return
        }
        
        nameLabel.text = wrap.name
        dateLabel?.text = wrap.updatedAt.timeAgoStringAtAMPM()
        coverView.url = wrap.picture?.small
        wrapNotificationLabel?.value = WLWhatsUpSet.sharedSet().unreadCandiesCountForWrap(wrap)
        if (wrap.isPublic) {
            chatNotificationLabel?.value = 0
            chatButton?.hidden = true
            chatPrioritizer?.defaultState = false
            coverView.isFollowed = wrap.isContributing
            coverView.isOwner = wrap.contributor?.current ?? false
            datePrioritizer?.defaultState = true
            creatorName?.text = wrap.contributor?.name
        } else {
            let messageConter = WLMessagesCounter.instance().countForWrap(wrap)
            let hasUnreadMessages = messageConter > 0
            chatNotificationLabel?.value = messageConter
            chatButton?.hidden = !hasUnreadMessages
            chatPrioritizer?.defaultState = hasUnreadMessages
            coverView.isFollowed = false
            datePrioritizer?.defaultState = false
            creatorName?.text = nil
        }
        if let broadcasts = LiveBroadcast.broadcastsForWrap(wrap) {
            liveBroadcastIndicator?.hidden = broadcasts.isEmpty
            nameLeadingPrioritizer?.defaultState = !broadcasts.isEmpty
        } else {
            liveBroadcastIndicator?.hidden = true
            nameLeadingPrioritizer?.defaultState = false
        }
    }
    
    func updateCandyNotifyCounter() {
        if let wrap = entry as? Wrap {
            wrapNotificationLabel?.value = WLWhatsUpSet.sharedSet().unreadCandiesCountForWrap(wrap)
        }
    }
    
    func updateChatNotifyCounter() {
        if let wrap = entry as? Wrap where !wrap.isPublic {
            let messageConter = WLMessagesCounter.instance().countForWrap(wrap)
            let hasUnreadMessages = messageConter > 0
            chatNotificationLabel?.value = messageConter
            chatButton?.hidden = !hasUnreadMessages
            chatPrioritizer?.defaultState = hasUnreadMessages
        }
    }
    
    @IBAction func notifyChatClick(sender: AnyObject) {
        if let wrap = entry as? Wrap {
            delegate?.wrapCell(self, presentChatViewControllerForWrap: wrap)
        }
    }
}