//
//  WLReportCell.swift
//  meWrap
//
//  Created by Yura Granchenko on 17/09/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import Foundation
import UIKit

class WLReportCell : UICollectionViewCell {
    @IBOutlet weak var textLabel: UILabel!
    @IBOutlet weak var showArrowLabel: UILabel!
    @IBOutlet weak var button: UIButton!
    var select : ((WLReportCell, String) -> Void)?
    var entry : Entry? {
        didSet {
            textLabel.text = self.entry!.title
            textLabel.textColor = self.entry!.fontColor
            textLabel.font = textLabel.font.fontWithSize(self.entry!.fontSize)
            showArrowLabel.hidden = self.entry!.v_code.isEmpty
            button.hidden = showArrowLabel.hidden
        }
    }
   
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
    }
    
    @IBAction func postViolationRequest(sender: AnyObject) {
            select?(self, entry!.v_code)
    }
}
