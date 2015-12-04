//
//  ImageView.swift
//  meWrap
//
//  Created by Sergey Maximenko on 11/28/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit

class ImageView: UIImageView {
    
    private var originalBackgroundColor = UIColor.clearColor()
    
    private weak var _defaultIconView: UILabel?
    @IBOutlet weak var defaultIconView: UILabel! {
        get {
            if let iconView = _defaultIconView {
                return iconView
            } else {
                let iconView = UILabel()
                iconView.translatesAutoresizingMaskIntoConstraints = false
                iconView.hidden = true
                iconView.font = UIFont(name:"icons", size:defaultIconSize)
                iconView.textAlignment = .Center
                iconView.textColor = defaultIconColor
                iconView.text = defaultIconText
                addSubview(iconView)
                addConstraint(NSLayoutConstraint(item: iconView, attribute: .CenterX, relatedBy: .Equal, toItem: self, attribute: .CenterX, multiplier: 1, constant: 0))
                addConstraint(NSLayoutConstraint(item: iconView, attribute: .CenterY, relatedBy: .Equal, toItem: self, attribute: .CenterY, multiplier: 1, constant: 0))
                _defaultIconView = iconView
                return iconView
            }
        }
        set {
            _defaultIconView = newValue
        }
    }
    
    @IBInspectable var defaultIconSize: CGFloat = 24
    
    @IBInspectable var defaultIconText: String?
    
    @IBInspectable var defaultIconColor = UIColor.whiteColor()
    
    @IBInspectable var defaultBackgroundColor: UIColor?
    
    var url: String? {
        didSet {
            image = nil
            if let url = url where !url.isEmpty {
                setDefaultIconViewHidden(true)
                ImageFetcher.defaultFetcher.enqueue(url, receiver: self)
            } else {
                setDefaultIconViewHidden(false)
            }
        }
    }
    
    var success: ((image: UIImage?, cached: Bool) -> Void)?
    
    var failure: FailureBlock?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        if let color = backgroundColor {
            originalBackgroundColor = color
        }
    }
    
    func setURL(url: String?, success: ((image: UIImage?, cached: Bool) -> Void)?, failure: FailureBlock?) {
        self.success = success
        self.failure = failure
        self.url = url
    }
    
    private func setDefaultIconViewHidden(hidden: Bool) {
        defaultIconView.hidden = hidden
        if hidden {
            backgroundColor = originalBackgroundColor
        } else {
            if let color = defaultBackgroundColor {
                backgroundColor = color
            }
        }
    }
}

extension ImageView: ImageFetching {
    func fetcherTargetUrl(fetcher: ImageFetcher) -> String? {
        return url
    }
    func fetcher(fetcher: ImageFetcher, didFailWithError error: NSError) {
        setDefaultIconViewHidden(false)
        failure?(error)
        failure = nil
        success = nil
    }
    func fetcher(fetcher: ImageFetcher, didFinishWithImage image: UIImage, cached: Bool) {
        setDefaultIconViewHidden(true)
        self.image = image
        if !cached {
            addAnimation(CATransition.transition(kCATransitionFade))
        }
        success?(image: image, cached: cached)
        failure = nil
        success = nil
    }
}