//
//  LiveBroadcastViewersViewController.swift
//  meWrap
//
//  Created by Sergey Maximenko on 1/12/16.
//  Copyright © 2016 Ravenpod. All rights reserved.
//

import UIKit

class LiveBroadcastViewerCell: StreamReusableView {
    
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let cellHeight: CGFloat = 56
        dataSource.addMetrics(StreamMetrics(identifier: "LiveBroadcastViewerCell", size: cellHeight))
        if let broadcast = broadcast {
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