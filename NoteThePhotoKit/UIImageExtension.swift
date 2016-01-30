//
//  UIImageExtension.swift
//  CameraProba6
//
//  Created by Jovan Ivanovski on 8/27/15.
//  Copyright © 2015 Jovan Ivanovski. All rights reserved.
//

import Foundation
import UIKit

public extension UIImage {
//    
//    var location: String? {
//        get {
//            if let loc = self.location {
//                return loc
//            }
//            return ""
//        }
//        set {
//            self.location = newValue
//        }
//    }
//    
//    var dateTime: NSDate? {
//        get {
//            if let dt = self.dateTime {
//                return dt
//            }
//            return NSDate()
//        }
//        set {
//            self.dateTime = newValue
//        }
//    }
//    
//    var note: String? {
//        get {
//            if let n = self.note {
//                return n
//            }
//            return ""
//        }
//        set {
//            self.note = newValue
//        }
//    }
    
    func alpha(value:CGFloat)->UIImage
    {
        UIGraphicsBeginImageContextWithOptions(self.size, false, 0.0)
        
        let ctx = UIGraphicsGetCurrentContext();
        let area = CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height);
        
        CGContextScaleCTM(ctx, 1, -1);
        CGContextTranslateCTM(ctx, 0, -area.size.height);
        CGContextSetBlendMode(ctx, CGBlendMode.Multiply);
        CGContextSetAlpha(ctx, value);
        CGContextDrawImage(ctx, area, self.CGImage);
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        return newImage;
    }
    
}