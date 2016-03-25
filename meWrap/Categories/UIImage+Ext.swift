//
//  UIImage+Ext.swift
//  meWrap
//
//  Created by Sergey Maximenko on 11/22/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

import UIKit

extension UIImage {
    
    class func drawLaunchImages() {
        
        guard let view = NSBundle.mainBundle().loadNibNamed("LaunchScreen", owner: nil, options: nil).first as? UIView else {
            return
        }
        
        let names = ["Default.png", "Default@2x.png", "Default-667h@2x.png", "Default-736h@3x.png", "Default-568h@2x.png", "Default-Portrait.png", "Default-Portrait@2x.png"]
        let sizes = [CGSizeMake(320, 480), CGSizeMake(320, 480), CGSizeMake(375, 667), CGSizeMake(414, 736), CGSizeMake(320, 568), CGSizeMake(768, 1024), CGSizeMake(768, 1024)]
        let scales: [CGFloat] = [1,2,2,3,2,1,2]
        
        for (index, name) in names.enumerate() {
            let size = sizes[index]
            view.frame = CGRectMake(0, 0, size.width, size.height);
            
            view.layoutIfNeeded()
            
            let image = UIImage.draw(size, opaque: false, scale: scales[index], drawing: { (size) -> Void in
                view.drawViewHierarchyInRect(view.bounds, afterScreenUpdates: true)
            })
            
            let path = "/Users/sergeymaximenko/Downloads/Default/\(NSLocale.currentLocale().objectForKey(NSLocaleLanguageCode) ?? "")/"
            try! NSFileManager.defaultManager().createDirectoryAtPath(path, withIntermediateDirectories: true, attributes: nil)
            UIImagePNGRepresentation(image)?.writeToFile(path + name, atomically: true)
        }
    }
    
    class func draw(size: CGSize, opaque: Bool = false, scale: CGFloat = UIScreen.mainScreen().scale, @noescape drawing: CGSize -> Void) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, opaque, scale)
        drawing(size)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
    
    func resize(bounds: CGSize, aspectFill: Bool) -> UIImage {
        let xr = bounds.width / size.width
        let yr = bounds.height / size.height
        let ratio: CGFloat = aspectFill ? max(xr, yr) : min(xr, yr)
        return resize(CGSize(width: size.width * ratio, height: size.height * ratio))
    }
    
    func resize(size: CGSize) -> UIImage {
        let result = transformForOrientation(size)
        return resize(size, transform: result.transform, transpose: result.transpose)
    }
    
    func resize(size: CGSize, transform: CGAffineTransform, transpose: Bool) -> UIImage {
        let newRect = CGRect(origin: CGPoint.zero, size: size).integral
        let transposedRect = CGRectMake(0, 0, size.height, size.width)
        let image = CGImage
        
        let bitmap = CGBitmapContextCreate(nil,
            Int(newRect.size.width),
            Int(newRect.size.height),
            CGImageGetBitsPerComponent(image),
            0,
            CGImageGetColorSpace(image),
            CGImageGetBitmapInfo(image).rawValue)
        
        CGContextConcatCTM(bitmap, transform)
        CGContextSetInterpolationQuality(bitmap, .Default)
        CGContextDrawImage(bitmap, transpose ? transposedRect : newRect, image)
        
        if let image = CGBitmapContextCreateImage(bitmap) {
            return UIImage(CGImage:image)
        } else {
            return self
        }
    }
    
    func transformForOrientation(size: CGSize) -> (transform: CGAffineTransform, transpose: Bool) {
        var transform = CGAffineTransformIdentity
        var transpose = false
        switch imageOrientation {
        case .Down, .DownMirrored:
            transform = CGAffineTransformTranslate(transform, size.width, size.height)
            transform = CGAffineTransformRotate(transform, CGFloat(M_PI))
        case .Left, .LeftMirrored:
            transpose = true
            transform = CGAffineTransformTranslate(transform, size.width, 0)
            transform = CGAffineTransformRotate(transform, CGFloat(M_PI_2))
        case .Right, .RightMirrored:
            transpose = true
            transform = CGAffineTransformTranslate(transform, 0, size.height)
            transform = CGAffineTransformRotate(transform, CGFloat(-M_PI_2))
        default: break
        }
        
        switch imageOrientation {
        case .UpMirrored, .DownMirrored:
            transform = CGAffineTransformTranslate(transform, size.width, 0)
            transform = CGAffineTransformScale(transform, -1, 1)
        case .LeftMirrored, .RightMirrored:
            transform = CGAffineTransformTranslate(transform, size.height, 0)
            transform = CGAffineTransformScale(transform, -1, 1)
        default: break
        }
        
        return (transform, transpose)
    }
    
    func thumbnail(size: CGFloat) -> UIImage {
        let resultSize = CGSize(width: size, height: size)
        let image = resize(resultSize, aspectFill: true)
        return image.crop(resultSize.rectCenteredInSize(image.size))
    }
    
    func crop(bounds: CGRect) -> UIImage {
        if let image = CGImageCreateWithImageInRect(CGImage, bounds) {
            return UIImage(CGImage:image)
        } else {
            return self
        }
    }
}