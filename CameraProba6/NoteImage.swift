//
//  NoteImage.swift
//  CameraProba6
//
//  Created by Jovan Ivanovski on 8/25/15.
//  Copyright © 2015 Jovan Ivanovski. All rights reserved.
//

import UIKit

public class NoteImage: UIImage {
    
    public var location: String! {
        get {
            return self.location
        }
        set {
            self.location = newValue
        }
    }
    public var dateTime: NSDate! {
        get {
            return self.dateTime
        }
        set {
            self.dateTime = newValue
        }
    }
    public var note: String! {
        get {
            return self.note
        }
        set {
            self.note = newValue
        }
    }

}
