//
//  ActivityStatusView.swift
//  meWrap
//
//  Created by Sergey Maximenko on 5/19/16.
//  Copyright © 2016 Ravenpod. All rights reserved.
//

import Foundation

enum ActivityStatus {
    case None, Upload, History, Offline
}

final class ActivityStatusView: UIView {
    
    private let count = Label(preset: .Smaller, weight: .Bold, textColor: UIColor.whiteColor())
    
    private let cloud = Label(icon: "j", size: 24, textColor: UIColor.whiteColor())
    
    convenience init() {
        self.init(frame: CGRect.zero)
        
        cloud.hidden = true
        count.hidden = true
        add(cloud) { (make) in
            make.leading.top.bottom.equalTo(self)
        }
        add(count) { (make) in
            make.leading.equalTo(cloud.snp_trailing).inset(-3)
            make.trailing.equalTo(self)
            make.centerY.equalTo(cloud)
        }
        
        let uploader = Uploader.candyUploader
        
        uploader.didStart.subscribe(self) { [unowned self] _ in
            self.update()
        }
        uploader.didChange.subscribe(self) { [unowned self] _ in
            self.update()
        }
        uploader.didStop.subscribe(self) { [unowned self] _ in
            self.update()
        }
        
        Network.network.subscribe(self) { [unowned self] _ in
            self.update()
        }
        
        NotificationCenter.defaultCenter.historyNotifier.subscribe(self) { [unowned self] _ in
            self.update()
        }
        update()
        clipsToBounds = true
        cloud.clipsToBounds = true
    }
    
    private weak var cloudIcon: UIView? {
        didSet {
            oldValue?.removeFromSuperview()
            if let icon = cloudIcon {
                cloud.add(icon, { (make) in
                    make.center.equalTo(cloud)
                })
            }
        }
    }
    
    var status: ActivityStatus = .None {
        willSet {
            guard newValue != status else { return }
            switch newValue {
            case .None:
                cloudIcon = nil
            case .Upload:
                cloudIcon = Label(icon: "k", size: 10, textColor: Color.orange)
                cloudIcon?.addAnimation(specify(CABasicAnimation(keyPath: "transform")) {
                    $0.fromValue = NSValue(CATransform3D: CATransform3DMakeTranslation(0, 20, 0))
                    $0.toValue = NSValue(CATransform3D: CATransform3DMakeTranslation(0, -20, 0))
                    $0.removedOnCompletion = false
                    $0.duration = 0.5
                    $0.repeatCount = FLT_MAX
                    })
            case .History:
                cloudIcon = Label(icon: "A", size: 10, textColor: Color.orange)
                cloudIcon?.addAnimation(specify(CABasicAnimation(keyPath: "transform.rotation.z")) {
                    $0.removedOnCompletion = false
                    $0.toValue = M_PI
                    $0.duration = 0.4
                    $0.repeatCount = FLT_MAX
                    $0.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
                    })
            case .Offline:
                cloudIcon = Label(icon: "~", size: 10, textColor: Color.orange)
                cloudIcon?.transform = CGAffineTransformMakeRotation(CGFloat(M_PI_4))
            }
            cloud.hidden = newValue == .None
        }
    }
    
    func update() {
        let isOnline = Network.network.reachable
        let uploadCount = Uploader.candyUploader.count
        let queryingHistory = NotificationCenter.defaultCenter.queryingHistory
        count.text = "\(uploadCount)"
        count.hidden = uploadCount == 0
        alpha = isOnline ? 1 : 0.3
        if isOnline {
            if uploadCount > 0 {
                status = .Upload
            } else if queryingHistory {
                status = .History
            } else {
                status = .None
            }
        } else {
            status = .Offline
        }
    }
}