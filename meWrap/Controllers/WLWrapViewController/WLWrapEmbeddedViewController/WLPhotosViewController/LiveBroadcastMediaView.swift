//
//  LiveBroadcastMediaView.swift
//  meWrap
//
//  Created by Sergey Maximenko on 11/20/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit

class LiveBroadcastMediaView: StreamReusableView {

    @IBOutlet weak var imageView: ImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    
    override func setup(entry: AnyObject!) {
        if let broadcast = entry as? LiveBroadcast {
            nameLabel.text = "\(broadcast.broadcaster?.name ?? "") \("is_live_streaming".ls)"
            titleLabel.text = broadcast.title
            imageView.url = broadcast.broadcaster?.avatar?.small
        }
    }
}
