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
    
    class func draw(image: UIImage, wrap: Wrap?, finish: UIImage -> Void) -> DrawingViewController {
        let presentingViewController = UIWindow.mainWindow.rootViewController
        let drawingViewController = DrawingViewController()
        NotificationCenter.defaultCenter.setActivity(wrap, type: .Drawing, inProgress: true)
        drawingViewController.setImage(image, finish: { (image) -> Void in
            finish(image)
            NotificationCenter.defaultCenter.setActivity(wrap, type: .Drawing, inProgress: false)
            presentingViewController?.dismissViewControllerAnimated(false, completion: nil)
            }, cancel: {
                NotificationCenter.defaultCenter.setActivity(wrap, type: .Drawing, inProgress: false)
                presentingViewController?.dismissViewControllerAnimated(false, completion: nil)
        })
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
        }
        
        if let image = image {
            let ratio = image.size.width/image.size.height
            imageView.snp_makeConstraints { $0.width.equalTo(imageView.snp_height).multipliedBy(ratio) }
            imageView.image = image
        }
        view.layoutIfNeeded()
        
        session.delegate = self
        session.brush = DrawingBrush(width: 10, opacity: 1, color: UIColor.redColor())
 
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
    
    @IBAction func stickers(sender: UIButton) {
        StickersView.show(view, close: { [weak self] sticker in
            self?.session.drawings.append(sticker)
            self?.canvas.render()
            sender.hidden = false
            self?.colorsView.hidden = false
            self?.canvas.userInteractionEnabled = true
        })
        sender.hidden = true
        colorsView.hidden = true
        canvas.userInteractionEnabled = false
    }
}

extension DrawingViewController: DrawingSessionDelegate {
    
    func drawingSessionDidBeginDrawing(session: DrawingSession) { }
    
    func drawingSessionDidEndDrawing(session: DrawingSession) {
        undoButton.hidden = session.empty
    }
}