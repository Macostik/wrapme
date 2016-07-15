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

class Button : UIButton, FontPresetable {
    
    convenience init(icon: String, size: CGFloat, textColor: UIColor = .whiteColor()) {
        self.init()
        titleLabel?.font = UIFont.icons(size)
        setTitle(icon, forState: .Normal)
        setTitleColor(textColor, forState: .Normal)
        setTitleColor(textColor.darkerColor(), forState: .Highlighted)
    }
    
    convenience init(preset: Font, weight: Font.Weight = .Light, textColor: UIColor = Color.grayDarker) {
        self.init()
        titleLabel?.font = UIFont.fontWithPreset(preset, weight: weight)
        self.preset = preset.rawValue
        setTitleColor(textColor, forState: .Normal)
        makePresetable(preset)
    }
    
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
    
    var presetableFont: UIFont? {
        get { return titleLabel?.font }
        set { titleLabel?.font = newValue }
    }
    
    @IBInspectable var preset: String? {
        willSet {
            makePresetable(newValue)
        }
    }
    
    @IBInspectable var touchArea: CGSize = CGSizeMake(minTouchSize, minTouchSize)
    
    var loading: Bool = false {
        willSet {
            if loading != newValue {
                if newValue == true {
                    let spinner = UIActivityIndicatorView(activityIndicatorStyle: .White)
                    spinner.color = spinnerColor ?? titleColorForState(.Normal)
                    let contentWidth = sizeThatFits(size).width
                    if (self.width - contentWidth) < spinner.width {
                        superview?.addSubview(spinner)
                        spinner.center = center
                        alpha = 0
                    } else {
                        addSubview(spinner)
                        let size = bounds.size
                        spinner.center = CGPointMake(size.width - size.height/2, size.height/2)
                    }
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
            highlightings.all({ ($0 as? Highlightable)?.highlighted = highlighted })
        }
    }
    
    override var selected: Bool {
        didSet {
            update()
            selectings.all({ ($0 as? Selectable)?.selected = selected })
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
    
    override func pointInside(point: CGPoint, withEvent event: UIEvent?) -> Bool {
        var rect = bounds
        rect = rect.insetBy(dx: -max(0, touchArea.width - rect.width)/2, dy: -max(0, touchArea.height - rect.height)/2)
        return rect.contains(point)
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
    
    override func layoutSubviews() {
        super.layoutSubviews()
        #if !DEBUG
            hidden = true
        #endif
    }
}

class QAButton: DebugButton {
    
    override func layoutSubviews() {
        super.layoutSubviews()
        #if DEBUG
            hidden = false
        #else
            hidden = Environment.isProduction
        #endif
    }
}

extension Button {
    
    static func candyAction(action: String, color: UIColor, size: CGFloat = 20) -> Button {
        let button = Button(icon: action, size: size)
        button.cornerRadius = 22
        button.normalColor = color
        button.highlightedColor = color.darkerColor()
        button.update()
        return button
    }
    
    static func expandableCandyAction(action: String, size: CGFloat = 20) -> Button {
        let button = Button(icon: action, size: size)
        button.setTitleColor(Color.grayLight, forState: .Highlighted)
        button.setBorder(color: UIColor.whiteColor())
        button.cornerRadius = 22
        return button
    }
}

final class AnimatedButton: Button {
    
    let circleView = UIView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        adjustsImageWhenHighlighted = false
        circleView.userInteractionEnabled = false
        insertSubview(circleView, atIndex: 0)
        circleView.snp_makeConstraints { (make) in
            make.center.equalTo(self)
            make.size.equalTo(self).multipliedBy(0.86)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        sendSubviewToBack(circleView)
        circleView.cornerRadius = cornerRadius * 0.86
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var highlighted: Bool {
        didSet {
            animate(duration: 0.12) {
                if highlighted {
                    let scale = cornerRadius/circleView.cornerRadius
                    circleView.transform = CGAffineTransformMakeScale(scale, scale)
                    circleView.backgroundColor = circleView.backgroundColor?.colorWithAlphaComponent(1)
                } else {
                    circleView.transform = CGAffineTransformIdentity
                    circleView.backgroundColor = circleView.backgroundColor?.colorWithAlphaComponent(0.88)
                }
                layoutIfNeeded()
            }
        }
    }
}

