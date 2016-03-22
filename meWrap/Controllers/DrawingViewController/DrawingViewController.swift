//
//  DrawingViewController.swift
//  meWrap
//
//  Created by Sergey Maximenko on 2/25/16.
//  Copyright © 2016 Ravenpod. All rights reserved.
//

import Foundation
import SnapKit

class DrawingViewController: BaseViewController {
    
    var didFinish: (UIImage -> Void)?
    var didCancel: (Void -> Void)?
    
    var image: UIImage?
    
    private lazy var session: DrawingSession = self.canvas.session
    @IBOutlet weak var canvas: DrawingCanvas!
    @IBOutlet weak var brushCanvas: DrawingCanvas!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var undoButton: UIButton!
    @IBOutlet weak var colorsView: ColorPicker!
    
    class func draw(image: UIImage, finish: UIImage -> Void) -> DrawingViewController {
        let presentingViewController = UIWindow.mainWindow.rootViewController
        let drawingViewController = DrawingViewController()
        drawingViewController.setImage(image, finish: { (image) -> Void in
            finish(image)
            presentingViewController?.dismissViewControllerAnimated(false, completion: nil)
            }, cancel: { presentingViewController?.dismissViewControllerAnimated(false, completion: nil) })
        presentingViewController?.presentViewController(drawingViewController, animated: false, completion: nil)
        return drawingViewController
    }
    
    convenience init() {
        self.init(nibName: "DrawingViewController", bundle: nil)
    }
    
    func setImage(image: UIImage, finish: (UIImage -> Void), cancel: (Void -> Void)) {
        self.image = image
        didFinish = finish
        didCancel = cancel
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        colorsView.pickedColor = { [weak self] color in
            self?.session.brush.color = color
            self?.updateBrushView()
        }
        
        if let image = image {
            let ratio = image.size.width/image.size.height
            imageView.snp_makeConstraints { $0.width.equalTo(imageView.snp_height).multipliedBy(ratio) }
            imageView.image = image
        }
        view.layoutIfNeeded()
        
        session.delegate = self
        session.interpolated = false
        session.brush = DrawingBrush(width: 10, opacity: 1, color: UIColor.redColor())
        updateBrushView()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateBrushView()
    }
    
    private func updateBrushView() {
        let session = brushCanvas.session
        session.erase()
        session.brush = self.session.brush
        session.beginDrawing()
        session.addPoint(brushCanvas.centerBoundary)
        session.endDrawing()
        brushCanvas.render()
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return [.Portrait, .PortraitUpsideDown]
    }
    
    @IBAction func cancel(sender: AnyObject) {
        didCancel?()
    }
    
    @IBAction func decreaseBrush(sender: UIButton) {
        let size = session.brush.width
        if size > 3 {
            self.session.brush.width = size - 0.25
            updateBrushView()
            if sender.tracking && sender.touchInside {
                performSelector(#selector(DrawingViewController.decreaseBrush(_:)), withObject:sender, afterDelay:0.0)
            }
        }
    }
    
    @IBAction func increaseBrush(sender: UIButton) {
        let size = session.brush.width
        if size < 51 {
            session.brush.width = size + 0.25
            updateBrushView()
            if sender.tracking && sender.touchInside {
                performSelector(#selector(DrawingViewController.increaseBrush(_:)), withObject:sender, afterDelay:0.0)
            }
        }
    }
    
    @IBAction func undo(sender: AnyObject) {
        canvas.undo()
        undoButton.hidden = session.empty
    }
    
    @IBAction func finish(sender: Button) {
        
        guard var image = imageView.image where !session.empty else {
            didCancel?()
            return
        }
        
        let size = CGSizeMake(image.size.width * image.scale, image.size.height * image.scale)
        image = UIImage.draw(size, opaque:false, scale:1, drawing: { size in
            image.drawInRect(CGRectMake(0, 0, size.width, size.height))
            CGContextScaleCTM(UIGraphicsGetCurrentContext(), size.width / canvas.width, size.height / canvas.height)
            session.render()
        })
        didFinish?(image)
    }
}

extension DrawingViewController: DrawingSessionDelegate {
    
    func drawingSessionDidBeginDrawing(session: DrawingSession) { }
    
    func drawingSession(session: DrawingSession, isAcceptableLine line: DrawingLine) -> Bool {
        return line.intersectsRect(CGRectInset(canvas.bounds, -line.brush.width/2, -line.brush.width/2))
    }
    
    func drawingSession(session: DrawingSession, didEndDrawing line: DrawingLine) {
        line.interpolate()
        undoButton.hidden = session.empty
    }
}