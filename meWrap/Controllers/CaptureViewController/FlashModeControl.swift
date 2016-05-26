//
//  FlashModeControl.swift
//  meWrap
//
//  Created by Sergey Maximenko on 11/26/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit
import AVFoundation

private extension AVCaptureFlashMode {
    func stringValue() -> String {
        switch self {
        case .On: return "d"
        case .Off: return "c"
        case .Auto: return "b"
        }
    }
}

final class FlashModeButton: Button {

    var mode: AVCaptureFlashMode = .Off
    
    convenience init(mode: AVCaptureFlashMode) {
        self.init(frame: CGRect.zero)
        highlightedColor = Color.grayDarker
        titleLabel?.font = UIFont.icons(24)
        self.mode = mode
        setTitle(mode.stringValue(), forState: .Normal)
    }
}

final class FlashModeControl: UIControl {
    
    let buttons = [FlashModeButton(mode: .On), FlashModeButton(mode: .Off), FlashModeButton(mode: .Auto)]
    
    convenience init() {
        self.init(frame: CGRect.zero)
        clipsToBounds = true
        for button in buttons {
            addSubview(button)
            button.addTarget(self, touchUpInside: #selector(self.selectMode(_:)))
        }
        mode = .Off
    }
    
    var mode: AVCaptureFlashMode = .Off {
        didSet {
            completeSelecting()
        }
    }
    
    func completeSelecting() {
        for button in buttons {
            button.snp_remakeConstraints(closure: { (make) in
                make.edges.equalTo(self)
                make.size.equalTo(44)
            })
            button.alpha = button.mode == mode ? 1 : 0
        }
    }
    
    func selectMode(sender: FlashModeButton) {
        
        if sender.size != size {
            let changed = sender.mode != self.mode
            
            animate {
                UIView.animateWithDuration(0.3, animations: {
                    self.mode = sender.mode
                    self.layoutIfNeeded()
                    }, completion: { (_) in
                        
                })
            }
            
            if changed {
                sendActionsForControlEvents(.ValueChanged)
            }
        } else {
            let buttons = self.buttons.sort({
                return $0 == sender && $1 != sender
            })
            
            var leading = self.snp_leading
            
            animate {
                for button in buttons {
                    button.alpha = 1
                    button.snp_remakeConstraints(closure: { (make) in
                        make.top.bottom.equalTo(self)
                        make.leading.equalTo(leading)
                        make.size.equalTo(44)
                        if button == buttons.last {
                            make.trailing.equalTo(self)
                        }
                    })
                    leading = button.snp_trailing
                }
                layoutIfNeeded()
            }
        }
    }
}
