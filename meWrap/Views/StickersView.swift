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

    init(view: View, imageUrl: String) {
        super.init(frame: UIWindow.mainWindow.bounds)
        contentView.backgroundColor = UIColor.clearColor()
        transformView.backgroundColor = Color.orange
        transformView.imageView.url = imageUrl
        view.add(self)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    lazy var contentView: UIView = {
        let view = UIView()
        self.add(view, {
            $0.edges.equalTo(self)
        })
        return view
    }()
    
    lazy var transformView: TransformView = {
        let transformView = TransformView(frame: CGRectMake(0, 0, self.width/2, self.width/2))
        self.contentView.add(transformView)
        transformView.center = self.center
        return transformView
    }()
    var isRotate = false
    var isChangeBounds = false
    
    override func pointInside(point: CGPoint, withEvent event: UIEvent?) -> Bool {
        if (transformView.isContaintPoint(point, view: transformView.trashLabel, stickerView: self)) {
            self.removeFromSuperview()
            return true
        }
        isRotate = transformView.isContaintPoint(point, view: transformView.rotateLabel, stickerView: self)
        isChangeBounds = transformView.isContaintPoint(point, view: transformView.changeSizeLabel, stickerView: self)
        return isRotate || isChangeBounds
    }
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        super.touchesMoved(touches, withEvent: event)
        let touch = touches.first
        if let point = touch?.locationInView(self) {
            if isRotate {
                let defaultAngle = atan2(contentView.x - center.x, contentView.y - center.y)
                let differentAngle = atan2(point.x - center.x, point.y - center.y)
                let diff = (defaultAngle - differentAngle) - CGFloat(M_PI)
                contentView.transform = CGAffineTransformMakeRotation(diff)
            }
            if isChangeBounds {
                let offset = max(abs(abs(point.x) - center.x), abs(abs(point.y) - center.y)) * 2
                transformView.size = CGSizeMake(offset, offset)
                transformView.center = center
            }
        }
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
    
    let imageView = specify(ImageView() , {
        $0.defaultIconText = "t"
        $0.defaultIconColor = Color.grayLighter
        $0.defaultBackgroundColor = UIColor.blackColor()
        $0.url = ""
    })
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.add(imageView, {
            $0.edges.equalTo(self).inset(1)
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