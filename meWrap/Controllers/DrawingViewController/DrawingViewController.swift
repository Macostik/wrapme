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
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var undoButton: UIButton!
    @IBOutlet weak var colorsView: ColorPicker!
    @IBOutlet var panGesture: UIPanGestureRecognizer!
    @IBOutlet var tapGesture: UITapGestureRecognizer!
    @IBOutlet weak var topView: UIView!
    
    @IBOutlet weak var textButton: Button!
    @IBOutlet weak var stickersButton: Button!
    
    class func draw(image: UIImage, wrap: Wrap?, finish: UIImage -> Void) -> DrawingViewController {
        let presentingViewController = UINavigationController.main
        let drawingViewController = DrawingViewController()
        NotificationCenter.defaultCenter.setActivity(wrap, type: .Drawing, inProgress: true)
        drawingViewController.setImage(image, finish: { (image) -> Void in
            finish(image)
            NotificationCenter.defaultCenter.setActivity(wrap, type: .Drawing, inProgress: false)
            presentingViewController.dismissViewControllerAnimated(false, completion: nil)
            }, cancel: {
                NotificationCenter.defaultCenter.setActivity(wrap, type: .Drawing, inProgress: false)
                presentingViewController.dismissViewControllerAnimated(false, completion: nil)
        })
        presentingViewController.presentViewController(drawingViewController, animated: false, completion: nil)
        return drawingViewController
    }
    
    convenience init() {
        self.init(nibName: "DrawingViewController", bundle: nil)
    }
    
    func setImage(image: UIImage, finish: (UIImage -> Void), cancel: (Void -> Void)) {
        self.image = image.resize(image.size)
        didFinish = finish
        didCancel = cancel
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.stickersButton.exclusiveTouch = true
        self.textButton.exclusiveTouch = true
        colorsView.setup()
        colorsView.pickedColor = { [weak self] color in
            self?.session.brush.color = color
            self?.textOverlayView?.transformView.textView.textColor = color
        }
        
        if let image = image {
            let ratio = image.size.width/image.size.height
            imageView.snp_makeConstraints { $0.width.equalTo(imageView.snp_height).multipliedBy(ratio) }
            imageView.image = image
        }
        view.layoutIfNeeded()
        
        session.delegate = self
        session.brush = DrawingBrush(width: 5, opacity: 1, color: UIColor.redColor())
 
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return [.Portrait, .PortraitUpsideDown]
    }
    
    @IBAction func cancel(sender: AnyObject) {
        if !session.empty {
            UIAlertController.confirmCancelingDrawChanges({ [weak self] _ in
                self?.didCancel?()
                }, failure: { _ in })
        } else {
             didCancel?()
        }
    }
    
    @IBAction func undo(sender: AnyObject) {
        canvas.undo()
        undoButton.hidden = session.empty
    }
    
    @IBAction func finish(sender: Button) {
        if let image = image where !session.empty {
            let size = CGSizeMake(image.size.width * image.scale, image.size.height * image.scale)
            let resultImage = UIImage.draw(size, opaque:false, scale:1, drawing: { size in
                image.drawInRect(0 ^ 0 ^ size)
                CGContextScaleCTM(UIGraphicsGetCurrentContext(), size.width / canvas.width, size.height / canvas.height)
                session.render()
            })
            didFinish?(resultImage)
        } else {
            didCancel?()
        }
    }
    
    private func setControlsHidden(hidden: Bool) {
        textButton.hidden = hidden
        stickersButton.hidden = hidden
        topView.hidden = hidden
        tapGesture.enabled = !hidden
        panGesture.enabled = !hidden
        canvas.userInteractionEnabled = hidden
    }
    
    @IBAction func stickers(sender: UIButton) {
        TextOverlayView.show(canvas.superview!, canvas: canvas, close: { [weak self] sticker in
            self?.didFinishWithOverlay(sticker)
            })
        setControlsHidden(true)
        colorsView.hidden = true
    }
    
    weak var textOverlayView: TextOverlayView?
    
    @IBAction func text(sender: UIButton) {
        let overlayView = TextOverlayView.show(canvas.superview!, canvas: canvas, type: .Text, close: { [weak self] overlay in
            self?.didFinishWithOverlay(overlay)
            })
        setControlsHidden(true)
        overlayView.transformView.textView.textColor = session.brush.color
        self.textOverlayView = overlayView
    }
    
    private func didFinishWithOverlay(overlay: TextOverlay?) {
        if let overlay = overlay {
            session.drawings.append(overlay)
            canvas.render()
            undoButton.hidden = session.empty
        }
        colorsView.hidden = false
        setControlsHidden(false)
    }
}

extension DrawingViewController: DrawingSessionDelegate {
    
    func drawingSessionDidBeginDrawing(session: DrawingSession) { }
    
    func drawingSessionDidEndDrawing(session: DrawingSession) {
        undoButton.hidden = session.empty
    }
}