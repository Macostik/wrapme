//
//  AlertController.swift
//  meWrap
//
//  Created by Sergey Maximenko on 11/29/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import Foundation
import WatchKit

class AlertController: WKInterfaceController {
    
    @IBOutlet weak var errorLabel: WKInterfaceLabel!
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
        if let error = context as? NSError {
            errorLabel.setText(error.localizedDescription)
        } else if let text = context as? String {
            errorLabel.setText(text)
        }
        
        performSelector(#selector(WKInterfaceController.popController), withObject: nil, afterDelay: 3)
    }
}