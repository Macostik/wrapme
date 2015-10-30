//
//  BlurredView.swift
//  meWrap
//
//  Created by Yura Granchenko on 30/10/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import Foundation

class BlurredView: UIView {
    
    @IBInspectable var styleEffect: Int = 0
    @IBInspectable var blurAlpha: CGFloat = 1.0

    var blurEffectStyle : UIBlurEffectStyle {
         return UIBlurEffectStyle(rawValue: styleEffect)!
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setup()
    }
    
    func setup () {
        let blurEffect = UIBlurEffect(style: blurEffectStyle)
        let view = UIVisualEffectView(effect: blurEffect)
        view.alpha = blurAlpha
        view.backgroundColor = UIColor.clearColor()
        view.tintColor = UIColor.whiteColor()
        view.translatesAutoresizingMaskIntoConstraints = true
        view.frame = bounds
        self.insertSubview(view, atIndex: 0)
    }
}
