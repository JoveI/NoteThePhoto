//
//  ShutterButton.swift
//  CameraProba6
//
//  Created by Jovan Ivanovski on 8/15/15.
//  Copyright © 2015 Jovan Ivanovski. All rights reserved.
//

import UIKit

class ShutterButton: UIButton {

    var outterCircleColor: UIColor?
    var middleCircleColor: UIColor?
    var innerCircleColor: UIColor?
    
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        let innerCircle = UIBezierPath(ovalInRect: CGRect(x: 7, y:7 , width: 46, height: 46))
        let middleCircle = UIBezierPath(ovalInRect: CGRect(x: 5, y: 5, width: 50, height: 50))
        let outterCircle = UIBezierPath(ovalInRect: CGRect(x: 0, y: 0, width: 60, height: 60))
        
        if outterCircleColor == nil {
            UIColor.whiteColor().setFill()
            outterCircle.fill()
            UIColor.blackColor().setFill()
            middleCircle.fill()
            UIColor.whiteColor().setFill()
            innerCircle.fill()
        }
        else {
            self.outterCircleColor!.setFill()
            outterCircle.fill()
            self.middleCircleColor!.setFill()
            middleCircle.fill()
            self.innerCircleColor!.setFill()
            innerCircle.fill()
        }
    }

}
