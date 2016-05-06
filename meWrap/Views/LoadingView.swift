//
//  LoadingView.swift
//  meWrap
//
//  Created by Sergey Maximenko on 11/14/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import Foundation
import SnapKit

final class LoadingView: StreamReusableView {
    
    static var DefaultSize: CGFloat = 66.0
    
    class func metrics() -> StreamMetrics<LoadingView> {
        return StreamMetrics<LoadingView>(size: DefaultSize)
    }
    
    override func layoutWithMetrics(metrics: StreamMetricsProtocol) {
        spinner.color = Color.orange
        spinner.hidesWhenStopped = true
        addSubview(spinner)
        spinner.snp_makeConstraints { $0.center.equalTo(self) }
    }
    
    private var spinner = UIActivityIndicatorView(activityIndicatorStyle: .Gray)
    
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