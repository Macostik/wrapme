//
//  HistoryDateSeparator.swift
//  meWrap
//
//  Created by Sergey Maximenko on 11/19/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import Foundation

class HistoryDateSeparator: StreamReusableView {
    
    @IBOutlet weak var dateLabel: UILabel!
    
    override func setup(entry: AnyObject!) {
        if let candy = entry as? Candy {
            dateLabel.text = candy.createdAt.stringWithDateStyle(.MediumStyle)
        }
    }
    
}