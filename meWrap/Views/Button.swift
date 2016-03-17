//
//  Button.swift
//  meWrap
//
//  Created by Yura Granchenko on 28/01/16.
//  Copyright © 2016 Ravenpod. All rights reserved.
//

import Foundation

protocol Highlightable: class {
    var highlighted: Bool { get set }
}

protocol Selectable: class {
    var selected: Bool { get set }
}

extension UIControl: Highlightable, Selectable {}

extension UILabel: Highlightable, Selectable {
    var selected: Bool {
        get { return highlighted }
        set { highlighted = newValue }
    }
}

class Button : UIButton {
    
    static let minTouchSize: CGFloat = 44.0
    
    var animated: Bool = false
    var spinner: UIActivityIndicatorView?
    
    @IBOutlet var highlightings: [UIView] = []
    @IBOutlet var selectings: [UIView] = []
    
    @IBInspectable var insets: CGSize = CGSizeZero
    @IBInspectable var spinnerColor: UIColor?
    
    @IBInspectable lazy var normalColor: UIColor = self.backgroundColor ?? UIColor.clearColor()
    @IBInspectable lazy var highlightedColor: UIColor = self.defaultHighlightedColor()
    @IBInspectable lazy var selectedColor: UIColor = self.backgroundColor ?? UIColor.clearColor()
    @IBInspectable lazy var disabledColor: UIColor = self.backgroundColor ?? UIColor.clearColor()
    
    @IBInspectable var localize: Bool = false {
        willSet {
            if newValue == true {
                setTitle(titleForState(.Normal)?.ls, forState: .Normal)
            }
        }
    }
    
    @IBInspectable var preset: String? {
        willSet {
            if let newValue = newValue {
                titleLabel?.font = titleLabel?.font.fontWithPreset(newValue)
                FontPresetter.defaultPresetter.addReceiver(self)
            }
        }
    }
    
    @IBInspectable var touchArea: CGSize = CGSizeMake(minTouchSize, minTouchSize)
    
    var loading: Bool = false {
        willSet {
            if loading != newValue {
                if newValue == true {
                    let spinner = UIActivityIndicatorView(activityIndicatorStyle: .White)
                    spinner.color = spinnerColor ?? titleColorForState(.Normal)
                    var spinnerSuperView: UIView = self
                    let contentWidth = sizeThatFits(size).width
                    if (self.width - contentWidth) < spinner.width {
                        if let superView = self.superview {
                            spinnerSuperView = superView
                        }
                        spinner.center = center
                        alpha = 0
                    } else {
                        let size = bounds.size
                        spinner.center = CGPointMake(size.width - size.height/2, size.height/2)
                    }
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
            for highlighting in highlightings {
                (highlighting as? Highlightable)?.highlighted = highlighted
            }
        }
    }
    
    override var selected: Bool {
        didSet {
            update()
            for selecting in selectings {
                (selecting as? Selectable)?.selected = selected
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
        let normalColor = self.normalColor
        let selectedColor = self.selectedColor
        let highlightedColor = self.highlightedColor
        let disabledColor = self.disabledColor
        var backgroundColor: UIColor?
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

class DebugButton: Button {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        hideIfNeeded()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        hideIfNeeded()
    }
    
    func hideIfNeeded() {
        #if !DEBUG
            hidden = true
        #endif
    }
}

class QAButton: DebugButton {
    
    override func hideIfNeeded() {
        #if DEBUG
            hidden = false
        #else
            hidden = Environment.isProduction
        #endif
    }
}