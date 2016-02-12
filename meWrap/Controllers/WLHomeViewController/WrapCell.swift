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
    
    @IBOutlet weak var coverView: WrapCoverView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel?
    
    @IBOutlet weak var wrapNotificationLabel: BadgeLabel?
    @IBOutlet weak var chatNotificationLabel: BadgeLabel?
    @IBOutlet weak var chatButton: UIButton?
    
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
    
    override func setup(entry: AnyObject) {
        guard let wrap = entry as? Wrap else {
            return
        }
        
        nameLabel.text = wrap.name
        coverView.url = wrap.asset?.small
        wrapNotificationLabel?.value = wrap.numberOfUnreadCandies
        if (wrap.isPublic) {
            dateLabel?.text = "\(wrap.contributor?.name ?? "") \(wrap.updatedAt.timeAgoStringAtAMPM())"
            chatNotificationLabel?.value = 0
            chatButton?.hidden = true
            chatPrioritizer?.defaultState = false
            coverView.isFollowed = wrap.isContributing
            coverView.isOwner = wrap.contributor?.current ?? false
        } else {
            dateLabel?.text = wrap.updatedAt.timeAgoStringAtAMPM()
            updateChatNotifyCounter(wrap)
            coverView.isFollowed = false
        }
        liveBroadcastIndicator?.hidden = wrap.liveBroadcasts.isEmpty
        nameLeadingPrioritizer?.defaultState = !wrap.liveBroadcasts.isEmpty
    }
    
    func updateCandyNotifyCounter() {
        if let wrap = entry as? Wrap {
            wrapNotificationLabel?.value = wrap.numberOfUnreadCandies
        }
    }
    
    func updateChatNotifyCounter() {
        if let wrap = entry as? Wrap where !wrap.isPublic {
            updateChatNotifyCounter(wrap)
        }
    }
    
    private func updateChatNotifyCounter(wrap: Wrap) {
        let messageConter = wrap.numberOfUnreadMessages
        let hasUnreadMessages = messageConter > 0
        chatNotificationLabel?.value = messageConter
        chatButton?.hidden = !hasUnreadMessages
        chatPrioritizer?.defaultState = hasUnreadMessages
    }
    
    @IBAction func notifyChatClick(sender: AnyObject) {
        if let wrap = entry as? Wrap {
            delegate?.wrapCell(self, presentChatViewControllerForWrap: wrap)
        }
    }
}