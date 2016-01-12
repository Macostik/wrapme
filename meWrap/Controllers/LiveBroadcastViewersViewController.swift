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
        
        if let broadcast = broadcast {
            let metrics = StreamMetrics(identifier: "LiveBroadcastViewerCell")
            metrics.size = LiveBroadcastViewerCell.DefaultHeight
            metrics.finalizeAppearing = { [unowned broadcast] item, view in
                if let view = view as? LiveBroadcastViewerCell, let user = item.entry as? User {
                    view.avatarView.url = user.avatar?.small
                    view.nameLabel.text = user == broadcast.broadcaster ? "\(user.name ?? "") (\("broadcaster".ls))" : user.name
                }
            }
            dataSource.addMetrics(metrics)
            update()
        }
    }
    
    func update() {
        if let broadcast = broadcast {
            let cellHeight = LiveBroadcastViewerCell.DefaultHeight
            let viewers = broadcast.viewers
            numberOfViewersLabel.text = "\(viewers.count) \("live_viewers".ls)"
            contentHeightConstraint.constant = 44 + min(cellHeight * 5, cellHeight * CGFloat(viewers.count))
            view.layoutIfNeeded()
            dataSource.items = viewers.sort({ $0.name > $1.name })
        }
    }
    
    @IBAction func close(sender: AnyObject) {
        presentingViewController?.dismissViewControllerAnimated(false, completion: nil)
    }
}

extension LiveBroadcastViewersViewController: SlideInteractiveTransitionDelegate {
    func slideInteractiveTransitionDidFinish(controller: SlideInteractiveTransition) {
        presentingViewController?.dismissViewControllerAnimated(false, completion: nil)
    }
}