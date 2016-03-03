//
//  Refresher.swift
//  meWrap
//
//  Created by Sergey Maximenko on 11/12/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit

enum RefresherStyle {
    case White, Orange
}

class Refresher: UIControl {
    
    private var inset: CGFloat = 0
    
    private var scrollView: UIScrollView? {
        return superview as? UIScrollView
    }
    
    override var enabled: Bool {
        didSet {
            hidden = !enabled
        }
    }
    
    convenience init(scrollView: UIScrollView) {
        self.init(frame: scrollView.bounds.offsetBy(dx: 0, dy: -scrollView.height))
        autoresizingMask = [.FlexibleLeftMargin, .FlexibleRightMargin, .FlexibleBottomMargin, .FlexibleWidth]
        translatesAutoresizingMaskIntoConstraints = true
        backgroundColor = Color.orange
        scrollView.addSubview(self)
        inset = scrollView.contentInset.top
        contentMode = .Center
        scrollView.panGestureRecognizer.addTarget(self, action:"dragging:")
        spinner.hidesWhenStopped = true
        addSubview(contentView)
        contentView.addSubview(spinner)
        contentView.addSubview(candyView)
        strokeLayer.frame = candyView.frame
        let size = strokeLayer.bounds.size.width/2
        strokeLayer.path = UIBezierPath(arcCenter: CGPointMake(size, size), radius: size - 1, startAngle: -CGFloat(M_PI_2), endAngle: 2*CGFloat(M_PI) - CGFloat(M_PI_2), clockwise: true).CGPath
        contentView.layer.addSublayer(strokeLayer)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        spinner.center = contentView.centerBoundary
        candyView.center = contentView.centerBoundary
        strokeLayer.frame = candyView.frame
    }
    
    private lazy var spinner: UIActivityIndicatorView = {
        let spinner = UIActivityIndicatorView(activityIndicatorStyle: .White)
        spinner.hidesWhenStopped = true
        return spinner
    } ()
    
    private lazy var contentView: UIView = {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: Refresher.ContentSize, height: Refresher.ContentSize))
        view.backgroundColor = UIColor.clearColor()
        view.autoresizingMask = .FlexibleTopMargin
        view.translatesAutoresizingMaskIntoConstraints = true
        return view
    }()
    
    private lazy var candyView: UILabel = {
        let candyView = UILabel(frame: CGRectMake(0, 0, 36, 36))
        candyView.font = UIFont(name: "icons", size: 24)
        candyView.text = "e"
        candyView.textAlignment = .Center
        candyView.clipsToBounds = true
        candyView.layer.cornerRadius = candyView.width/2
        candyView.layer.borderWidth = 1
        candyView.alpha = 0.25
        candyView.hidden = true
        return candyView
    }()
    
    private lazy var strokeLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.strokeEnd = 0.0
        layer.fillColor = UIColor.clearColor().CGColor
        layer.lineWidth = 1
        layer.actions = ["strokeEnd":NSNull(),"hidden":NSNull()]
        return layer
    }()
    
    private var refreshable: Bool = false {
        didSet {
            if refreshable != oldValue {
                candyView.alpha = refreshable ? 1.0 : 0.25
            }
        }
    }
    
    private var _refreshing: Bool = false
    
    func setRefreshing(refreshing: Bool, animated: Bool) {
        if _refreshing != refreshing {
            if refreshing {
                if refreshable {
                    _refreshing = true
                    spinner.startAnimating()
                    setInset(Refresher.ContentSize, animated: animated)
                    scrollView?.setMinimumContentOffsetAnimated(animated)
                    UIView.performWithoutAnimation({ () -> Void in
                        self.sendActionsForControlEvents(.ValueChanged)
                    })
                }
            } else {
                _refreshing = false
                scrollView?.contentInset.top = 0 + inset
                scrollView?.contentOffset = CGPointMake(0, -(Refresher.ContentSize + inset))
                scrollView?.setContentOffset(CGPointMake(0, -inset), animated: animated)
                spinner.stopAnimating()
            }
        }
    }
    
    private func setInset(inset: CGFloat, animated: Bool) {
        if let scrollView = scrollView {
            UIView.performAnimated(animated, animation: { () -> (Void) in
                scrollView.contentInset.top = inset + self.inset
            })
        }
    }

    
    func dragging(sender: UIPanGestureRecognizer) {
        guard let scrollView = scrollView where enabled else {
            return
        }
        let offset = scrollView.contentOffset.y + inset
        
        var hidden = true
        
        if sender.state == .Began {
            hidden = offset > 0;
            refreshable = false
            if (!hidden) {
                contentView.center = CGPointMake(width/2.0, height - Refresher.ContentSize/2.0)
            }
        } else if offset <= 0 && sender.state == .Changed {
            hidden = false
            let ratio = max(0, min(1, -offset / (1.3 * Refresher.ContentSize)))
            if (strokeLayer.strokeEnd != ratio) {
                strokeLayer.strokeEnd = ratio
            }
            refreshable = (ratio == 1);
        } else if sender.state == .Ended && refreshable {
            Dispatch.mainQueue.async { () -> Void in
                self.setRefreshing(true, animated: true)
                self.refreshable = false
            }
        }
        
        if (hidden != candyView.hidden) {
            candyView.hidden = hidden
            strokeLayer.hidden = hidden
        }
    }

    private static var ContentSize: CGFloat = 44
    
    var style: RefresherStyle = .White {
        didSet {
            let color: UIColor?
            if style == .Orange {
                color = Color.orange
                backgroundColor = UIColor.whiteColor()
            } else {
                color = UIColor.whiteColor()
                backgroundColor = Color.orange
            }
            if let color = color {
                candyView.textColor = color
                spinner.color = color
                strokeLayer.strokeColor = color.CGColor
                candyView.layer.borderColor = color.CGColor
            }
        }
    }

}