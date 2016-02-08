//
//  LiveBroadcastViewersViewController.swift
//  meWrap
//
//  Created by Sergey Maximenko on 1/12/16.
//  Copyright © 2016 Ravenpod. All rights reserved.
//

import UIKit

class LiveBroadcastViewerCell: StreamReusableView {
    
    static let DefaultHeight: CGFloat = 56
    
    @IBOutlet weak var avatarView: ImageView!
    
    @IBOutlet weak var nameLabel: UILabel!
    
    override func setup(entry: AnyObject!) {
        if let user = entry as? User {
            avatarView.url = user.avatar?.small
            nameLabel.text = user.name
        }
    }
}

class LiveBroadcastViewersViewController: UIViewController {
    
    @IBOutlet weak var streamView: StreamView!
    
    @IBOutlet weak var numberOfViewersLabel: UILabel!
    
    private lazy var dataSource: StreamDataSource = StreamDataSource(streamView: self.streamView)
    
    @IBOutlet weak var contentHeightConstraint: NSLayoutConstraint!
    
    var broadcast: LiveBroadcast?
    
    private lazy var slideTransition: SlideInteractiveTransition = SlideInteractiveTransition(contentView: self.streamView.superview!)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        slideTransition.delegate = self
        
        let metrics = StreamMetrics(identifier: "LiveBroadcastViewerCell")
        metrics.size = LiveBroadcastViewerCell.DefaultHeight
        dataSource.addMetrics(metrics)
        update()
    }
    
    func update() {
        if let broadcast = broadcast {
            let cellHeight = LiveBroadcastViewerCell.DefaultHeight
            let viewers = broadcast.viewers
            numberOfViewersLabel.text = "\(viewers.count) \("live_viewers".ls)"
            contentHeightConstraint.constant = 48 + min(cellHeight * 5, cellHeight * CGFloat(viewers.count))
            view.layoutIfNeeded()
            dataSource.items = viewers.sort({ $0.name > $1.name })
        }
    }
    
    @IBAction func close(sender: AnyObject) {
        removeFromContainerAnimated(false)
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
}

extension LiveBroadcastViewersViewController: SlideInteractiveTransitionDelegate {
    func slideInteractiveTransitionDidFinish(controller: SlideInteractiveTransition) {
        removeFromContainerAnimated(false)
    }
}