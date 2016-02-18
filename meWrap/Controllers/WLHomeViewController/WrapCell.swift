//
//  WrapCell.swift
//  meWrap
//
//  Created by Sergey Maximenko on 11/20/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit

class RecentCandiesView: StreamReusableView {
    
    var streamView: StreamView = StreamView()
    
    lazy var dataSource: StreamDataSource = StreamDataSource(streamView: self.streamView)
    
    class func layoutMetrics() -> StreamMetrics {
        return StreamMetrics(loader: LayoutStreamLoader<RecentCandiesView>())
    }
    
    override func layoutWithMetrics(metrics: StreamMetrics) {
        dataSource.numberOfGridColumns = 3
        streamView.layout = SquareGridLayout(horizontal: false)
        dataSource.addMetrics(StreamMetrics(loader: LayoutStreamLoader<CandyCell>())).disableMenu = true
        dataSource.layoutSpacing = Constants.pixelSize
        backgroundColor = Color.orange
        streamView.backgroundColor = UIColor.whiteColor()
        addSubview(streamView)
        streamView.snp_makeConstraints { (make) -> Void in
            make.leading.top.trailing.equalTo(self)
            make.bottom.equalTo(self).inset(5)
        }
    }
    
    override func setup(entry: AnyObject?) {
        guard let wrap = entry as? Wrap, let recentCandies = wrap.recentCandies else { return }
        layoutIfNeeded()
        dataSource.numberOfItems = (recentCandies.count > Constants.recentCandiesLimit_2) ? Constants.recentCandiesLimit : Constants.recentCandiesLimit_2
        dataSource.items = recentCandies
    }
}

@objc protocol WrapCellDelegate: NSObjectProtocol {
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
        
        swipeAction.shouldBeginPanning = { [unowned self] (action) -> Bool in
            guard let wrap = self.entry as? Wrap else {
                return false
            }
            if wrap.isPublic {
                if wrap.isContributing {
                    return action.direction == .Left
                } else {
                    return false
                }
            } else {
                return true
            }
        }
        
        swipeAction.didBeginPanning = { [unowned self] (action) -> Void in
            self.delegate?.wrapCellDidBeginPanning(self)
        }
        
        swipeAction.didEndPanning = { [unowned self] (action, performedAction) -> Void in
            self.delegate?.wrapCellDidEndPanning(self, performedAction: performedAction)
        }
        
        swipeAction.didPerformAction = { [unowned self] (action, direction) -> Void in
            if let wrap = self.entry as? Wrap {
                if action.direction == .Right {
                    self.delegate?.wrapCell(self, presentChatViewControllerForWrap: wrap)
                } else if action.direction == .Left {
                    self.delegate?.wrapCell(self, presentCameraViewControllerForWrap: wrap)
                }
            }
        }
        
        self.swipeAction = swipeAction
    }
    
    override func didDequeue() {
        super.didDequeue()
        swipeAction?.reset()
    }
    
    override func setup(entry: AnyObject?) {
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