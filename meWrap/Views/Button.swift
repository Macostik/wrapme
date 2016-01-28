//
//  Button.swift
//  meWrap
//
//  Created by Yura Granchenko on 28/01/16.
//  Copyright © 2016 Ravenpod. All rights reserved.
//

import Foundation

class Button : UIButton {
    
    let minTouchSize: CGFloat = 44.0
    
    var animated: Bool = false
    var spinner: UIActivityIndicatorView?
    
    @IBOutlet var highlightings: [UIView]?
    @IBOutlet var selectings: [UIView]?
    
    @IBInspectable var insets: CGSize = CGSizeZero
    @IBInspectable var spinnerColor: UIColor?
    
    @IBInspectable lazy var normalColor: UIColor = self.backgroundColor ?? UIColor.clearColor()
    @IBInspectable lazy var highlightedColor: UIColor = self.defaultHighlightedColor()
    @IBInspectable lazy var selectedColor: UIColor = self.backgroundColor ?? UIColor.clearColor()
    @IBInspectable lazy var disabledColor: UIColor = self.backgroundColor ?? UIColor.clearColor()
    
    @IBInspectable var localize: Bool = false {
        willSet {
            if newValue == true {
                if let text = titleLabel?.text where !text.isEmpty {
                    super.setTitle(text.ls, forState: .Normal)
                }
            }
        }
    }
    
    @IBInspectable var preset: String? {
        willSet {
            if let newValue = newValue {
                titleLabel?.font = titleLabel?.font .fontWithPreset(newValue)
                FontPresetter.defaultPresetter.addReceiver(self)
            }
        }
    }
    
    @IBInspectable var touchArea: CGSize {
        return CGSizeMake(minTouchSize, minTouchSize)
    }
    
    var loading: Bool = false {
        willSet {
            if loading != newValue {
                if  newValue == true {
                    let spinner = UIActivityIndicatorView(activityIndicatorStyle: .White)
                    if let spinnerColor = spinnerColor {
                        spinner.color = spinnerColor
                    } else {
                        spinner.color = titleColorForState(.Normal)
                    }
                    var center = CGPointZero
                    var spinnerSuperView = self
                    let contentWidth = sizeThatFits(size).width
                    if (self.width - contentWidth) < spinner.width {
                        if let superView = self.superview as? Button {
                            spinnerSuperView = superView
                        }
                        center = self.center
                        alpha = 0
                    } else {
                        let size = bounds.size
                        center = CGPointMake(size.width - size.height/2, size.height/2)
                    }
                    spinner.center = center
                    spinnerSuperView.addSubview(spinner)
                    spinner.startAnimating()
                    self.spinner = spinner
                    userInteractionEnabled = false
                } else {
                    if spinner?.superview != self {
                        alpha = 1
                    }
                    spinner?.removeFromSuperview()
                    userInteractionEnabled = true
                }
            }
        }
    }
    
    override var highlighted: Bool {
        didSet {
            update()
            guard let highlightings = highlightings else { return }
            for highlighting in highlightings {
                if let highlighting = highlighting as? UIControl {
                    highlighting.highlighted = highlighted
                } else if let highlighting = highlighting as? UILabel {
                    highlighting.highlighted = highlighted
                }
            }
        }
    }
    
    override var selected: Bool {
        didSet {
            update()
            guard let selectings = selectings else { return }
            for selecting in selectings {
                if let selecting = selecting as? UIControl {
                    selecting.selected = selected
                } else if let selecting = selecting as? UILabel {
                    selecting.highlighted = selected
                }
            }
        }
    }
    
    override var enabled: Bool {
        didSet {
            update()
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        update()
    }
    
    func defaultHighlightedColor() -> UIColor {
        return self.backgroundColor ?? UIColor.clearColor()
    }
    
    func update() {
        var backgroundColor = self.backgroundColor
        if enabled {
            if highlighted {
                backgroundColor = highlightedColor
            } else {
                backgroundColor = selected ? selectedColor : normalColor
            }
        } else {
            backgroundColor = disabledColor
        }
        if !CGColorEqualToColor(backgroundColor?.CGColor, self.backgroundColor?.CGColor) {
            setBackgroundColor(backgroundColor!, animated: animated)
        }
    }
    
    override func setTitle(title: String?, forState state: UIControlState) {
        guard let title = title else { return }
        if localize == true {
            super.setTitle(title.ls, forState: state)
        } else {
            super.setTitle(title, forState: state)
        }
    }
    
    override func intrinsicContentSize() -> CGSize {
        let intrinsicSize = super.intrinsicContentSize()
        return CGSizeMake(intrinsicSize.width + insets.width, intrinsicSize.height + insets.height)
    }
    
    func presetterDidChangeContentSizeCategory(presetter: FontPresetter) {
        guard let preset = preset else { return }
        titleLabel?.font = titleLabel?.font.fontWithPreset(preset)
    }
    
    override func pointInside(point: CGPoint, withEvent event: UIEvent?) -> Bool {
        var rect = bounds
        if rect.width < touchArea.width {
            let dx = touchArea.width - rect.width
            rect.size.width     += dx
            rect.origin.x       -= dx/2
        }
        if rect.height < touchArea.height {
            let dy = touchArea.height - rect.height
            rect.size.height    += dy
            rect.origin.y       -= dy
        }
        return CGRectContainsPoint(rect, point)
    }
}

class SegmentButton: Button {

    override var highlighted: Bool {
        set { }
        get {
            return super.highlighted
        }
    }
}

class PressButton: Button {
    
   override func defaultHighlightedColor() -> UIColor {
        return normalColor.colorByAddingValue(0.1) ?? UIColor.clearColor()
    }
}

class QAButton: Button {
    override func awakeFromNib() {
        super.awakeFromNib()
        #if DEBUG
            hidden = false
        #else
            hidden = Environment.currentEnvironment.isProduction
        #endif
    }
}

class DebugButton: Button {
    override func awakeFromNib() {
        super.awakeFromNib()
        #if !DEBUG
            hidden = true
        #endif
    }
}
