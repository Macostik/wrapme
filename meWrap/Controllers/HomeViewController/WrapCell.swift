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
        streamView.scrollEnabled = false
        dataSource.numberOfGridColumns = 3
        streamView.layout = SquareGridLayout(streamView: streamView, horizontal: false)
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
    
    @IBOutlet weak var liveBroadcastIndicator: UILabel?
    @IBOutlet var nameLeadingPrioritizer: LayoutPrioritizer?
    
    private var swipeAction: SwipeAction?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let swipeAction = SwipeAction(view: self)
        
        swipeAction.shouldBeginPanning = { [weak self] (action) -> Bool in
            guard let wrap = self?.entry as? Wrap else {
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
        
        swipeAction.didBeginPanning = { [weak self] (action) -> Void in
            if let weakSelf = self {
                weakSelf.delegate?.wrapCellDidBeginPanning(weakSelf)
            }
        }
        
        swipeAction.didEndPanning = { [weak self] (action, performedAction) -> Void in
            if let weakSelf = self {
                weakSelf.delegate?.wrapCellDidEndPanning(weakSelf, performedAction: performedAction)
            }
        }
        
        swipeAction.didPerformAction = { [weak self] (action, direction) -> Void in
            if let weakSelf = self {
                if let wrap = weakSelf.entry as? Wrap {
                    if action.direction == .Right {
                        weakSelf.delegate?.wrapCell(weakSelf, presentChatViewControllerForWrap: wrap)
                    } else if action.direction == .Left {
                        weakSelf.delegate?.wrapCell(weakSelf, presentCameraViewControllerForWrap: wrap)
                    }
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
        wrapNotificationLabel?.value = wrap.numberOfUnreadInboxItems
        if (wrap.isPublic) {
            dateLabel?.text = "\(wrap.contributor?.name ?? "") \(wrap.updatedAt.timeAgoStringAtAMPM())"
            coverView.isFollowed = wrap.isContributing
            coverView.isOwner = wrap.contributor?.current ?? false
        } else {
            dateLabel?.text = wrap.updatedAt.timeAgoStringAtAMPM()
            coverView.isFollowed = false
        }
        updateBadgeNumber()
        liveBroadcastIndicator?.hidden = wrap.liveBroadcasts.isEmpty
        nameLeadingPrioritizer?.defaultState = !wrap.liveBroadcasts.isEmpty
    }
    
    func updateBadgeNumber() {
        if let wrap = entry as? Wrap {
            wrapNotificationLabel?.value = wrap.numberOfUnreadInboxItems + wrap.numberOfUnreadMessages
        }
    }
}