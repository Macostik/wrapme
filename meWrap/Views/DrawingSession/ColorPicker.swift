//
//  ColorPicker.swift
//  meWrap
//
//  Created by Sergey Maximenko on 2/25/16.
//  Copyright © 2016 Ravenpod. All rights reserved.
//

import UIKit

final class ColorPicker: UIView {
    
    var pickedColor: (UIColor -> Void)?
    
    internal lazy var targetLabel: Label = Label(icon: "A", size: 26)
    
    private var color: UIColor? {
        willSet {
            if let color = newValue where newValue != self.color {
                pickedColor?(color)
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        Dispatch.defaultQueue.fetch({ () -> [UIColor] in
            var colors = [UIColor]()
            var hue: CGFloat = 0
            while hue < 1 {
                colors.append(UIColor(hue:hue, saturation:1.0, brightness:1.0, alpha:1.0))
                hue += 0.001
            }
            return colors
        }) { [weak self] colors in
            if let picker = self {
                var x: CGFloat = 0
                let height: CGFloat = picker.height
                let width: CGFloat = picker.width / CGFloat(colors.count)
                for color in colors {
                    let view = UIView(frame:CGRectMake(x, 0, width, height))
                    view.backgroundColor = color
                    picker.addSubview(view)
                    x += width
                }
                
                picker.addSubview(picker.targetLabel)
                picker.targetLabel.snp_makeConstraints {
                    $0.centerY.equalTo(picker)
                    $0.leading.equalTo(picker)
                }
            }
        }
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        let touch = touches.first
        color = touch?.view?.backgroundColor
        guard let location = touch?.locationInView(self) else { return }
        targetLabel.snp_updateConstraints {
            $0.leading.equalTo(location)
        }
    }
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        guard let location = touches.first?.locationInView(self) else { return }
        for subview in subviews where subview.frame.contains(location) {
            color = subview.backgroundColor
            break
        }
        targetLabel.snp_updateConstraints {
            $0.leading.equalTo(location)
        }
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        color = nil
    }
    
    override func touchesCancelled(touches: Set<UITouch>?, withEvent event: UIEvent?) {
        color = nil
    }
}