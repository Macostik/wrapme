//
//  CandyCell.swift
//  meWrap
//
//  Created by Sergey Maximenko on 11/19/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import Foundation

class CandyCell: StreamReusableView {
    
    @IBOutlet weak var imageView: ImageView!
    
    @IBOutlet weak var commentLabel: UILabel!
    
    @IBOutlet weak var videoIndicatorView: UIView!
    
    override func loadedWithMetrics(metrics: StreamMetrics!) {
        guard !metrics.disableMenu else {
            return
        }
        
        FlowerMenu.sharedMenu().registerView(self, constructor: constructFlowerMenu)
    }
    
    func constructFlowerMenu(menu: FlowerMenu) {
        guard let candy = entry as? Candy where !(candy.wrap?.requiresFollowing ?? true) else {
            return
        }
        
        
        
        menu.entry = candy
    }
    
    func deleteCandy(candy: AnyObject?) {
        if let candy = candy as? Candy {
            
        }
    }
    
    func reportCandy(candy: AnyObject?) {
        if let candy = candy as? Candy {
            
        }
    }
    
    func editCandy(candy: AnyObject?) {
        if let candy = candy as? Candy {
            
        }
    }
    
    func drawCandy(candy: AnyObject?) {
        if let candy = candy as? Candy {
            
        }
    }
    
    func downloadCandy(candy: AnyObject?) {
        if let candy = candy as? Candy {
            
        }
    }
    
    override func didDequeue() {
        super.didDequeue()
        imageView.image = nil
    }
    
    override func setup(entry: AnyObject!) {
        
        userInteractionEnabled = true
        
        guard let candy = entry as? Candy else {
            videoIndicatorView.hidden = true
            imageView.url = nil
            commentLabel.superview?.hidden = true
            return
        }
        
        videoIndicatorView.hidden = candy.mediaType != .Video;
        commentLabel.text = candy.latestComment?.text
        commentLabel.superview?.hidden = commentLabel.text?.isEmpty ?? true
        
        guard let asset = candy.picture else {
            return
        }
        
        if asset.justUploaded {
            StreamView.lock()
            alpha = 0.0
            UIView.animateWithDuration(0.5, animations: {[weak self] () -> Void in
                self?.alpha = 1
                }, completion: { (_) -> Void in
                    asset.justUploaded = false
                    StreamView.unlock()
            })
        }
        
        imageView.url = asset.small
    }
}