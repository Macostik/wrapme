//
//  LoadingView.swift
//  meWrap
//
//  Created by Sergey Maximenko on 11/14/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import Foundation

class LoadingView: StreamReusableView {
    
    static var Identifier = "LoadingView"
    static var DefaultSize: CGFloat = 66.0
    
    class func metrics() -> StreamMetrics {
        return StreamMetrics(identifier: Identifier, size: DefaultSize)
    }
    
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    var animating: Bool {
        get {
            return spinner.isAnimating()
        }
        set {
            if newValue {
                spinner.startAnimating()
            } else {
                spinner.stopAnimating()
            }
        }
    }
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        animating = superview != nil
    }
}