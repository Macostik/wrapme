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
    private lazy var imageView: UIImageView = specify(UIImageView()) {
        self.superview?.insertSubview($0, belowSubview: self)
        $0.snp_makeConstraints { $0.edges.equalTo(self) }
        self._imageView = $0
    }
    
    override func drawRect(rect: CGRect) {
        session.drawing?.render()
    }
    
    private var line: Line?
    
    @IBAction func panning(sender: UIPanGestureRecognizer) {
        
        let state = sender.state
        
        if session.drawing == nil {
            let line = Line()
            line.brush = session.brush
            session.beginDrawing(line)
            self.line = line
        }
        
        line?.addPoint(sender.locationInView(self))
        
        if (state == .Ended || state == .Cancelled) {
            if let line = line where line.intersectsRect(bounds) {
                line.interpolate()
                session.endDrawing()
                render()
            } else {
                session.cancelDrawing()
            }
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