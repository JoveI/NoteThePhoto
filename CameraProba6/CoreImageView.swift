//
//  CoreImageView.swift
//  CameraProba6BackUp3
//
//  Created by Jovan Ivanovski on 9/3/15.
//  Copyright © 2015 Jovan Ivanovski. All rights reserved.
//

import UIKit
import GLKit

class CoreImageView: GLKView {
    
    var image: CIImage? {
        didSet {
            display()
        }
    }
    let coreImageContext: CIContext
    
    override convenience init(frame: CGRect) {
        let eaglContext = EAGLContext(API: EAGLRenderingAPI.OpenGLES2)
        self.init(frame: frame, context: eaglContext)
    }
    
    override init(frame: CGRect, context eaglContext: EAGLContext) {
        coreImageContext = CIContext(EAGLContext: eaglContext)
        super.init(frame: frame, context: eaglContext)
        // We will be calling display() directly, hence this needs to be false
        enableSetNeedsDisplay = false
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
//    override func drawRect(rect: CGRect) {
//        if let img = image {
//            let scale = self.window?.screen.scale ?? 1.0
//            let destRect = CGRectApplyAffineTransform(bounds, CGAffineTransformMakeScale(scale, scale))
//            coreImageContext.drawImage(img, inRect: destRect, fromRect: img.extent)
//        }
//    }


}
