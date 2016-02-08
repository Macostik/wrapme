//
//  MessageDateView.swift
//  meWrap
//
//  Created by Yura Granchenko on 08/02/16.
//  Copyright © 2016 Ravenpod. All rights reserved.
//

import Foundation

class MessageDateView: StreamReusableView {
    
    @IBOutlet weak var dateLabel: UILabel!
    
    override func setup(entry: AnyObject) {
        guard let message = entry as? Message else { return }
        dateLabel.text = message.createdAt.stringWithDateStyle(.MediumStyle)
    }
}