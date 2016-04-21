//
//  StickersView.swift
//  meWrap
//
//  Created by Yura Granchenko on 07/04/16.
//  Copyright © 2016 Ravenpod. All rights reserved.
//

import Foundation
import SnapKit

class StickersView: UIView {
    
    lazy var contentView: UIView = {
        let view = UIView()
        self.add(view, {
            $0.edges.equalTo(self)
        })
        view.backgroundColor = UIColor.clearColor()
        return view
    }()
    
    lazy var transformView: TransformView = {
        let transformView = TransformView(frame: CGRectMake(
            self.center.x - self.width/4,
            self.center.y - self.width/4,
            self.width/2, self.width/2))
        transformView.emojiLabel.font = UIFont.systemFontOfSize(self.width/2 - 5)
        return transformView
    }()
    var isRotate = false
    var isChangeBounds = false
    var isMove = false
    weak var emojiView: FullScreenEmojiView?
    var close: (Sticker? -> Void)?
    
    class func show(view: UIView, close: (Sticker? -> Void)) {
        let stickerView = StickersView(frame: view.bounds)
        view.add(stickerView)
        stickerView.close = close
        stickerView.setupEmojiView()
    }
    
    func setupEmojiView() {
        emojiView = FullScreenEmojiView.show(selectedBlock: { [weak self] emoji in
            self?.contentView.add(self?.transformView ?? UIView())
            self?.transformView.emojiLabel.text = emoji as? String
            }, close: { [weak self] in
                self?.removeFromSuperview()
                self?.close?(nil)
        })
    }
    
    override func pointInside(point: CGPoint, withEvent event: UIEvent?) -> Bool {
        isRotate = false; isChangeBounds = false; isMove = false
        if emojiView != nil {  return true }
        if (transformView.isContaintPoint(point, view: transformView.trashLabel, stickerView: self)) {
            self.removeFromSuperview()
            close?(nil)
            return true
        }
        isRotate = transformView.isContaintPoint(point, view: transformView.rotateLabel, stickerView: self)
        if isRotate == true { return isRotate }
        isChangeBounds = transformView.isContaintPoint(point, view: transformView.changeSizeLabel, stickerView: self)
        if isChangeBounds == true { return isChangeBounds }
        isMove = contentView.convertRect(transformView.frame, toView: self).contains(point)
        if isMove == true { return isMove }
        addStickerToCanvas()
        return false
    }

    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        super.touchesMoved(touches, withEvent: event)
        let touch = touches.first
        if let point = touch?.locationInView(self) {
            if isRotate {
                let defaultAngle = atan2(transformView.x - center.x, transformView.y - center.y)
                let differentAngle = atan2(point.x - center.x, point.y - center.y)
                let diff = (defaultAngle - differentAngle) + CGFloat(M_PI)
                transformView.transform = CGAffineTransformMakeRotation(diff)
            }
            if isChangeBounds {
                let offset = min(contentView.width, max(abs(abs(point.x) - center.x), abs(abs(point.y) - center.y)) * 2)
                transformView.size = CGSizeMake(offset, offset)
                transformView.emojiLabel.font = UIFont.systemFontOfSize(offset)
                transformView.center = center
            }
            if isMove {
                var limitX = point.x
                var limitY = point.y
                if point.x - transformView.width/2 < 0  {
                    limitX = x + transformView.width/2
                }
                if point.y - transformView.height/2 < 0  {
                    limitY = y + transformView.height/2
                }
                if point.x + transformView.width/2 > width {
                    limitX = width - transformView.width/2
                }
                if point.y + transformView.height/2 > height {
                    limitY = height - transformView.height/2
                }
                contentView.frame = CGRectMake(limitX - center.x, limitY - center.y, contentView.width, contentView.height)
            }
        }
    }
    
    private func addStickerToCanvas() {
        let name = transformView.emojiLabel.text ?? ""
        let frame = contentView.convertRect(transformView.frame, toView: self)
        let sticker = Sticker(name: name, fontSize: transformView.emojiLabel.font.pointSize, frame: frame, transform: transformView.transform)
        close?(sticker)
        self.removeFromSuperview()
    }
    
}

class TransformView: UIView {
    
    let trashLabel = specify(Label(icon: "n")) {
        $0.backgroundColor = Color.orange
        $0.circled = true
        $0.borderColor = UIColor.whiteColor()
        $0.borderWidth = 1
        $0.clipsToBounds = true
        $0.textAlignment = .Center
    }
    
    let rotateLabel = specify(Label(icon: "5")) {
        $0.backgroundColor = Color.orange
        $0.circled = true
        $0.borderColor = UIColor.whiteColor()
        $0.borderWidth = 1
        $0.clipsToBounds = true
        $0.textAlignment = .Center
    }
    
    let changeSizeLabel = specify(Label(icon: "v")) {
        $0.backgroundColor = Color.orange
        $0.circled = true
        $0.borderColor = UIColor.whiteColor()
        $0.borderWidth = 1
        $0.clipsToBounds = true
        $0.textAlignment = .Center
        $0.transform = CGAffineTransformMakeRotation(-37)
    }
    
    var emojiLabel = specify(Label() , {
        $0.backgroundColor = UIColor.clearColor()
        $0.textAlignment = .Center
        $0.borderColor = UIColor.whiteColor()
        $0.borderWidth = 1.0
    })
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.add(emojiLabel, {
            $0.edges.equalTo(self)
        })
        self.add(trashLabel, {
            $0.width.height.equalTo(40)
            $0.centerX.equalTo(self.snp_trailing)
            $0.centerY.equalTo(self.snp_top)
        })
        self.add(rotateLabel, {
            $0.width.height.equalTo(40)
            $0.centerX.equalTo(self.snp_trailing)
            $0.centerY.equalTo(self.snp_bottom)
        })
        self.add(changeSizeLabel, {
            $0.width.height.equalTo(40)
            $0.centerX.equalTo(self.snp_leading)
            $0.centerY.equalTo(self.snp_top)
        })
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func isContaintPoint(point: CGPoint, view: UIView, stickerView: StickersView) -> Bool {
        let rect = convertRect(view.frame, toCoordinateSpace: stickerView)
        return rect.contains(point)
    }
}

class Sticker: Drawing {
    
    let name: String
    let fontSize: CGFloat
    let frame: CGRect
    let transform: CGAffineTransform
    
    init(name: String = "", fontSize: CGFloat = 0.0, frame: CGRect = CGRectZero, transform: CGAffineTransform = CGAffineTransformIdentity) {
        self.name = name
        self.fontSize = fontSize
        self.frame = frame
        self.transform = transform
    }
    
    func render() {
        let paragraphStyle = specify(NSMutableParagraphStyle()) {
            $0.alignment = .Center
        }
        let context = UIGraphicsGetCurrentContext()
        CGContextSaveGState(context)
        CGContextSetTextMatrix(context, transform)
        let attrs = [NSFontAttributeName: UIFont.icons(fontSize), NSParagraphStyleAttributeName: paragraphStyle]
        name.drawWithRect(frame, options: .UsesLineFragmentOrigin, attributes: attrs, context: nil)
        CGContextRestoreGState(context)
    }
}
