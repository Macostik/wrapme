//
//  WrapCell.swift
//  meWrap
//
//  Created by Sergey Maximenko on 11/20/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit
import SnapKit

class RecentCandiesView: StreamReusableView {
    
    var streamView: StreamView = StreamView()
    
    lazy var dataSource: StreamDataSource = StreamDataSource(streamView: self.streamView)
    
    override func layoutWithMetrics(metrics: StreamMetrics) {
        streamView.scrollEnabled = false
        dataSource.numberOfGridColumns = 3
        streamView.layout = SquareGridLayout(streamView: streamView, horizontal: false)
        dataSource.addMetrics(StreamMetrics(loader: StreamLoader<CandyCell>())).disableMenu = true
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
    
    weak var delegate: WrapCellDelegate?
    
    private let coverView = WrapCoverView(backgroundColor: UIColor.whiteColor())
    private let nameLabel = Label(preset: .Large, textColor: Color.grayDarker)
    private let dateLabel = Label(preset: .Small, textColor: Color.grayLight)
    private let badgeLabel = BadgeLabel(preset: .Smaller, textColor: UIColor.whiteColor())
    private let liveBadge = Label(preset: FontPreset.XSmall, textColor: UIColor.whiteColor())
    
    private var nameBadgeLeading: Constraint!
    private var nameLiveLeading: Constraint!
    
    private var swipeAction: SwipeAction?
    
    override func layoutWithMetrics(metrics: StreamMetrics) {
        
        coverView.clipsToBounds = true
        coverView.cornerRadius = 25
        coverView.defaultBackgroundColor = Color.grayLighter
        coverView.defaultIconText = "t"
        
        badgeLabel.intrinsicContentSizeInsets = CGSize(width: 4, height: 4)
        badgeLabel.cornerRadius = 9
        badgeLabel.textAlignment = .Center
        badgeLabel.clipsToBounds = true
        badgeLabel.backgroundColor = Color.dangerRed
        
        liveBadge.textAlignment = .Center
        liveBadge.cornerRadius = 8
        liveBadge.clipsToBounds = true
        liveBadge.backgroundColor = Color.dangerRed
        liveBadge.text = "LIVE"
        
        nameLabel.setContentCompressionResistancePriority(UILayoutPriorityDefaultLow, forAxis: .Horizontal)
        
        let button = Button(type: .Custom)
        button.highlightedColor = Color.grayLightest
        button.addTarget(self, action: #selector(WrapCell.select as WrapCell -> () -> ()), forControlEvents: .TouchUpInside)
        addSubview(button)
        addSubview(coverView)
        addSubview(badgeLabel)
        addSubview(nameLabel)
        addSubview(liveBadge)
        addSubview(dateLabel)
        
        button.snp_makeConstraints { $0.edges.equalTo(self) }
        
        coverView.snp_makeConstraints {
            $0.leading.equalTo(self).inset(10)
            $0.centerY.equalTo(self)
            $0.size.equalTo(50)
        }
        
        badgeLabel.snp_makeConstraints {
            $0.leading.equalTo(coverView.snp_trailing).inset(19)
            $0.top.equalTo(coverView)
            $0.width.greaterThanOrEqualTo(badgeLabel.snp_height)
        }
        
        nameLabel.snp_makeConstraints {
            nameBadgeLeading = $0.leading.equalTo(badgeLabel.snp_trailing).offset(7).priorityLow().constraint
            nameLiveLeading = $0.leading.equalTo(liveBadge.snp_trailing).offset(7).priorityHigh().constraint
            $0.bottom.equalTo(coverView.snp_centerY)
            $0.trailing.lessThanOrEqualTo(self).inset(12)
        }
        
        liveBadge.snp_makeConstraints {
            $0.leading.equalTo(badgeLabel.snp_trailing).offset(7)
            $0.centerY.equalTo(nameLabel)
            $0.width.equalTo(40)
            $0.height.equalTo(20)
        }
        
        dateLabel.snp_makeConstraints {
            $0.leading.equalTo(liveBadge)
            $0.top.equalTo(coverView.snp_centerY)
        }
        
        swipeAction = specify(SwipeAction(view: self), {
            $0.shouldBeginPanning = { [weak self] (action) -> Bool in
                guard let wrap = self?.entry as? Wrap else { return false }
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
            
            $0.didBeginPanning = { [weak self] (action) -> Void in
                guard let weakSelf = self else { return }
                weakSelf.delegate?.wrapCellDidBeginPanning(weakSelf)
            }
            
            $0.didEndPanning = { [weak self] (action, performedAction) -> Void in
                guard let weakSelf = self else { return }
                weakSelf.delegate?.wrapCellDidEndPanning(weakSelf, performedAction: performedAction)
            }
            
            $0.didPerformAction = { [weak self] (action, direction) -> Void in
                guard let weakSelf = self else { return }
                if let wrap = weakSelf.entry as? Wrap {
                    if action.direction == .Right {
                        weakSelf.delegate?.wrapCell(weakSelf, presentChatViewControllerForWrap: wrap)
                    } else if action.direction == .Left {
                        weakSelf.delegate?.wrapCell(weakSelf, presentCameraViewControllerForWrap: wrap)
                    }
                }
            }
        })
    }
    
    override func didDequeue() {
        super.didDequeue()
        swipeAction?.reset()
    }
    
    override func setup(entry: AnyObject?) {
        guard let wrap = entry as? Wrap else { return }
        nameLabel.text = wrap.name
        coverView.url = wrap.asset?.small
        badgeLabel.value = wrap.numberOfUnreadInboxItems
        if (wrap.isPublic) {
            dateLabel.text = "\(wrap.contributor?.name ?? "") \(wrap.updatedAt.timeAgoStringAtAMPM())"
            coverView.isFollowed = wrap.isContributing
            coverView.isOwner = wrap.contributor?.current ?? false
        } else {
            dateLabel.text = wrap.updatedAt.timeAgoStringAtAMPM()
            coverView.isFollowed = false
        }
        updateBadgeNumber()
        liveBadge.hidden = wrap.liveBroadcasts.isEmpty
        if wrap.liveBroadcasts.isEmpty {
            nameLiveLeading.updatePriorityLow()
            nameBadgeLeading.updatePriorityHigh()
        } else {
            nameLiveLeading.updatePriorityHigh()
            nameBadgeLeading.updatePriorityLow()
        }
    }
    
    func updateBadgeNumber() {
        guard let wrap = entry as? Wrap else { return }
        badgeLabel.value = wrap.numberOfUnreadInboxItems + wrap.numberOfUnreadMessages
    }
}