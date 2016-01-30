//
//  AVCameraPreviewView.swift
//  CameraProba6
//
//  Created by Jovan Ivanovski on 8/15/15.
//  Copyright © 2015 Jovan Ivanovski. All rights reserved.
//

import UIKit
import Foundation
import AVFoundation

class AVCameraPreviewView: UIView {
    
    var session: AVCaptureSession? {
        get {
            return (self.layer as! AVCaptureVideoPreviewLayer).session
        }
        set(session) {
            (self.layer as! AVCaptureVideoPreviewLayer).session = session
        }
    }
    
    override class func layerClass() -> AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }

    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        // Drawing code
    }
    */

}
