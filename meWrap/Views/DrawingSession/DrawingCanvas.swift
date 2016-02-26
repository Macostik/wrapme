//
//  DrawingCanvas.swift
//  meWrap
//
//  Created by Sergey Maximenko on 2/25/16.
//  Copyright © 2016 Ravenpod. All rights reserved.
//

import Foundation
import SnapKit

class DrawingCanvas: UIView {
    
    var session = DrawingSession()
    
    deinit {
        _imageView?.removeFromSuperview()
    }
    
    private weak var _imageView: UIImageView?
    private lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        self.superview?.insertSubview(imageView, belowSubview: self)
        imageView.snp_makeConstraints(closure: { $0.edges.equalTo(self) })
        self._imageView = imageView
        return imageView
    }()
    
    override func drawRect(rect: CGRect) {
        session.line?.render()
    }
    
    @IBAction func panning(sender: UIPanGestureRecognizer) {
        
        let state = sender.state
        
        if !session.drawing {
            session.beginDrawing()
        }
        
        session.addPoint(sender.locationInView(self))
        
        if (state == .Ended || state == .Cancelled) {
            session.endDrawing()
            render()
        }
        
        setNeedsDisplay()
    }
    
    func render() {
        imageView.image = UIImage.draw(size) { _ in
            session.render()
        }
    }
    
    func undo() {
        session.undo()
        render()
    }
    
    func erase() {
        session.erase()
        imageView.image = nil
    }
}