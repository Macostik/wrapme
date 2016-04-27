//
//  ImageEditor.swift
//  meWrap
//
//  Created by Sergey Maximenko on 2/25/16.
//  Copyright © 2016 Ravenpod. All rights reserved.
//

import Foundation

class ImageEditor {
    
    class func editImage(image: UIImage, completion: UIImage -> Void) {
        let presentingViewController = UINavigationController.main
        let controller = editControllerWithImage(image, completion: { image in
            completion(image)
            presentingViewController.dismissViewControllerAnimated(false, completion: nil)
            }, cancel: {
                presentingViewController.dismissViewControllerAnimated(false, completion: nil)
            })
        presentingViewController.presentViewController(controller, animated: false, completion: nil)
    }
    
    private static var token: dispatch_once_t = 0
    
    class func editControllerWithImage(image: UIImage, completion: UIImage -> Void, cancel: Block) -> AdobeUXImageEditorViewController {
        
        dispatch_once(&token) {
            AdobeImageEditorCustomization.setSupportedIpadOrientations([UIInterfaceOrientation.Portrait.rawValue, UIInterfaceOrientation.PortraitUpsideDown.rawValue, UIInterfaceOrientation.LandscapeLeft.rawValue, UIInterfaceOrientation.PortraitUpsideDown.rawValue, UIInterfaceOrientation.LandscapeRight.rawValue])
            AdobeImageEditorCustomization.setToolOrder([
                kAdobeImageEditorEnhance,
                kAdobeImageEditorEffects,
                kAdobeImageEditorStickers,
                kAdobeImageEditorOrientation,
                kAdobeImageEditorCrop,
                kAdobeImageEditorColorAdjust,
                kAdobeImageEditorLightingAdjust,
                kAdobeImageEditorSharpness,
                kAdobeImageEditorDraw,
                kAdobeImageEditorText,
                kAdobeImageEditorRedeye,
                kAdobeImageEditorWhiten,
                kAdobeImageEditorBlemish,
                kAdobeImageEditorBlur,
                kAdobeImageEditorMeme,
                kAdobeImageEditorFrames,
                kAdobeImageEditorFocus,
                kAdobeImageEditorSplash,
                kAdobeImageEditorVignette
                ])
            AdobeUXAuthManager.sharedManager().setAuthenticationParametersWithClientID("a7929bf566694d579acb507eae697db1", withClientSecret: "b6fa1e1c-4f8c-4001-88a9-0251a099f890")
        }
        let controller = AdobeUXImageEditorViewController(image:image)
        controller.enqueueHighResolutionRenderWithImage(image) { (result, error) -> Void in
            if let result = result {
                completion(result)
            } else {
                cancel()
            }
        }
        return controller
    }
    
}