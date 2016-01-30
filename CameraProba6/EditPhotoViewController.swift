//
//  EditPhotoViewController.swift
//  CameraProba6BackUp3
//
//  Created by Jovan Ivanovski on 9/3/15.
//  Copyright © 2015 Jovan Ivanovski. All rights reserved.
//

import UIKit
import Photos
import AssetsLibrary

class EditPhotoViewController: UIViewController {
    
    
    //MARK: - Properties
    
    @IBOutlet weak var stillImageView: UIImageView!
    @IBOutlet weak var acceptButton: UIButton!
    @IBOutlet weak var discardButton: UIButton!
    @IBOutlet weak var editButton: UIButton!
    @IBOutlet weak var weatherImageView: UIImageView!
    
    var image: UIImage!
    //public var image: NoteImage!
    var meta: [String : AnyObject]!
    var assetCollection: PHAssetCollection!
    var newData: NSData!
    var imgAsset: PHAsset!
    var isImageAssetPicked: Bool = false
    
    var data: NSData!
    var UTI: String!
    var placemarkCountry: String!
    var placemarkCity: String!
    let celsius: String = "\u{02103}"
    let fahrenheit: String = "\u{02109}"
    var locationManager: CLLocationManager!
    var latitude: CLLocationDegrees!
    var longitude: CLLocationDegrees!
    var imageData: NSData!
    var location: CLLocation!
    var dateTime: String!
    var imageDescription: String!
    var userDescription: String!
    var wi: WeatherInfo!
    
    private var isStillImageInFocus: Bool = true
    var textLayer: CATextLayer!
    var textView: UITextView!
    var isWriting: Bool = false
    var activityIndicator: UIActivityIndicatorView!
    
    let al: ALAssetsLibrary = ALAssetsLibrary()
    var albumFound : Bool = false
    var photosAsset: PHFetchResult!
    var assetThumbnailSize:CGSize!
    var collection: PHAssetCollection!
    var assetCollectionPlaceholder: PHObjectPlaceholder!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        stillImageView.image = image
        
        let tapGesture = UITapGestureRecognizer(target: self, action: "tapHandler:")
        tapGesture.numberOfTapsRequired = 1
        self.view.addGestureRecognizer(tapGesture)
        
        let swipe = UISwipeGestureRecognizer(target: self, action: "swipe")
        swipe.direction = .Left
        self.view.addGestureRecognizer(swipe)
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    /*
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    // Get the new view controller using segue.destinationViewController.
    // Pass the selected object to the new view controller.
    }
    */
    

    
    //MARK: - Actions
    
    /* Saving the image */
    @IBAction func acceptAction(sender: UIButton) {
        
        if isImageAssetPicked == true {
            //Helper.editStitchContentWith(self.imgAsset, image: self.image, data: self.data)
            
            let imageSource = CGImageSourceCreateWithData(self.data, nil)!
            let metadata: NSDictionary = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil)!
            let mutableMetadata: NSMutableDictionary = metadata.mutableCopy() as! NSMutableDictionary
            let tiffDictionary: NSMutableDictionary = mutableMetadata.objectForKey(kCGImagePropertyTIFFDictionary as NSString)!.mutableCopy() as! NSMutableDictionary
            
            let tiffImageDescription = tiffDictionary.objectForKey(kCGImagePropertyTIFFImageDescription as NSString) as! String
            
            var newImageDescription: String!
            
            if let userDescRange = tiffImageDescription.rangeOfString("±") {
             
                let previousDesc = tiffImageDescription[tiffImageDescription.startIndex...userDescRange.startIndex]
                
                newImageDescription = "\(previousDesc)\(userDescription)"
                
            }
            
            if newImageDescription != nil {
                tiffDictionary.setObject(newImageDescription, forKey: kCGImagePropertyTIFFImageDescription as NSString)
            }
            
            mutableMetadata.setObject(tiffDictionary, forKey: kCGImagePropertyTIFFDictionary as NSString)
            
            
            al.writeImageToSavedPhotosAlbum(image?.CGImage, metadata: mutableMetadata as [NSObject : AnyObject], completionBlock: {
                
                _, _ in
                
                PHPhotoLibrary.sharedPhotoLibrary().performChanges({
                    PHAssetChangeRequest.deleteAssets([self.imgAsset])
                    }, completionHandler: { success, error in
                        if success {
                            
                        }
                    }
                )
                
            })
            
            
        }
        else {
            
            let firstImageSource: CGImageSourceRef = CGImageSourceCreateWithData(data, nil)!
            
            let metadata: NSDictionary = CGImageSourceCopyPropertiesAtIndex(firstImageSource, 0, nil)!
            let mutableMetadata: NSMutableDictionary = metadata.mutableCopy() as! NSMutableDictionary
            
            let tiffDictionary: NSMutableDictionary = mutableMetadata.objectForKey(kCGImagePropertyTIFFDictionary as NSString)!.mutableCopy() as! NSMutableDictionary
            var gpsDictionary: [String : AnyObject] = [String : AnyObject]()
            var iptcDictionary: [String : AnyObject] = [String : AnyObject]()
            
            if self.placemarkCountry != nil && self.placemarkCity != nil {
                iptcDictionary[kCGImagePropertyIPTCProvinceState as String] = self.placemarkCountry
                iptcDictionary[kCGImagePropertyIPTCCity as String] = self.placemarkCity
            }
            else {
                if self.wi != nil {
                    if self.wi.country != nil && self.wi.city != nil {
                        
                        iptcDictionary[kCGImagePropertyIPTCProvinceState as String] = self.wi.country
                        iptcDictionary[kCGImagePropertyIPTCCity as String] = self.wi.city
                        
                    }
                }
            }
            
            gpsDictionary[kCGImagePropertyGPSLatitude as String] = self.latitude
            gpsDictionary[kCGImagePropertyGPSLongitude as String] = self.longitude
            
            
            if self.wi != nil {
                if imageDescription == nil && self.wi != nil && self.dateTime != nil {
                    if userDescription == nil {
                        imageDescription = "Taken on \(dateTime)^\(self.wi.weatherType), \(self.wi.temp) \(celsius)\(self.wi.weatherTypeID)±"
                    }
                    else {
                        imageDescription = "Taken on \(dateTime)^\(self.wi.weatherType), \(self.wi.temp) \(celsius)\(self.wi.weatherTypeID)±\(userDescription)"
                    }
                    tiffDictionary.setObject(self.imageDescription, forKey: kCGImagePropertyTIFFImageDescription as NSString)
                }
            }
            else {
                if imageDescription == nil && self.dateTime != nil && userDescription == nil {
                    imageDescription = "Taken on \(dateTime)^"
                }
                else if imageDescription == nil && self.dateTime != nil && userDescription != nil {
                    imageDescription = "Taken on \(dateTime)^\(userDescription)"
                }
                tiffDictionary.setObject(self.imageDescription, forKey: kCGImagePropertyTIFFImageDescription as NSString)
            }
            
            if userDescription != nil && imageDescription == nil {
                imageDescription = "\(userDescription)"
                tiffDictionary.setObject(self.imageDescription, forKey: kCGImagePropertyTIFFImageDescription as NSString)
            }
            
            tiffDictionary.setObject(self.dateTime, forKey: kCGImagePropertyTIFFDateTime as NSString)
            
            mutableMetadata.setObject(gpsDictionary, forKey: kCGImagePropertyGPSDictionary as NSString)
            mutableMetadata.setObject(iptcDictionary, forKey: kCGImagePropertyIPTCDictionary as NSString)
            mutableMetadata.setObject(tiffDictionary, forKey: kCGImagePropertyTIFFDictionary as NSString)
            
            al.writeImageToSavedPhotosAlbum(image?.CGImage, metadata: mutableMetadata as [NSObject : AnyObject], completionBlock: nil)
            
        }
        self.performSegueWithIdentifier("photoEditingToCameraViewSegue", sender: self)
        
    }
    
    /* Discard the image without saving it */
    @IBAction func discardAction(sender: UIButton) {
        self.performSegueWithIdentifier("photoEditingToCameraViewSegue", sender: self)
    }
    
    @IBAction func editAction(sender: UIButton) {
        if isStillImageInFocus == true {
            
            self.weatherImageView = ImageProcessingHelper.showImageInfo(self.weatherImageView, wi: self.wi, dateTime: self.dateTime)
            
            isStillImageInFocus = false
            addText()
            
        }
        else {
            
            UIView.animateWithDuration(0.3,
                animations: {
                    self.stillImageView.alpha = 1.0
                    self.weatherImageView.alpha = 0.0
                    self.weatherImageView.image = nil
                    if self.textLayer != nil {
                        self.textLayer.backgroundColor = nil
                        self.textLayer.removeFromSuperlayer()
                    }
                }
            )
            isStillImageInFocus = true
            
        }
    }
    
    // MARK:- Handlers, Selectors
    func swipe() {
        if isStillImageInFocus == false {
            UIView.animateWithDuration(0.3,
                animations: {
                    self.stillImageView.alpha = 1.0
                    self.weatherImageView.alpha = 0.0
                    self.weatherImageView.image = nil
                    if self.textLayer != nil {
                        self.textLayer.backgroundColor = nil
                        self.textLayer.removeFromSuperlayer()
                    }
                }
            )
            isStillImageInFocus = true
        }
        else {
            self.weatherImageView = ImageProcessingHelper.showImageInfo(self.weatherImageView, wi: wi, dateTime: dateTime)
            addText()
            isStillImageInFocus = false
        }
    }
    
    /* Allow the user to add info for the image */
    func tapHandler(tap: UITapGestureRecognizer) {
        
        if isWriting == false && weatherImageView.alpha > 0.0 {
            isWriting = true
            textView = UITextView()
            textView.frame = CGRect(origin: CGPoint(x: 0, y: tap.locationInView(weatherImageView).y), size: CGSize(width: self.view.frame.width, height: 100))
            textView.backgroundColor = UIColor.darkGrayColor().colorWithAlphaComponent(0.6)
            if userDescription != nil {
                textView.text = userDescription
            }
            textView.textColor = UIColor.whiteColor()
            textView.textContainerInset = UIEdgeInsets(top: 0, left: 6, bottom: 0, right: 0)
            let fontName: CFStringRef = "Noteworthy-Light"
            textView.font = CTFontCreateWithName(fontName, 18, nil)
            textView.textContainer.lineBreakMode = NSLineBreakMode.ByWordWrapping
            textView.becomeFirstResponder()
            self.weatherImageView.addSubview(textView)
        }
        else {
            isWriting = false
            if textView != nil {
                userDescription = textView.text
                textView.removeFromSuperview()
            }
            if textLayer != nil {
                textLayer.backgroundColor = nil
                textLayer.removeFromSuperlayer()
            }
            addText()
        }
        
    }
    
    
    // MARK: - Helper Functions
    
    /* Add text sublayer with the updated user info to the image */
    func addText() {
        textLayer = CATextLayer()
        textLayer.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height)        
        
        // 2
        var string = "\n\n"
        if self.placemarkCountry != nil && self.placemarkCity != nil {
            string += "\(self.placemarkCountry), \(self.placemarkCity)\n"
        }
        else {
            if self.wi != nil {
                if self.wi.country != nil && self.wi.city != nil {
                    string += "\(self.wi.country), \(self.wi.city)\n"
                }
            }
            else {
                string += "Country and city not available\n"
            }
        }
        if self.dateTime.rangeOfString("Taken") != nil {
            string += "\(dateTime)\n"
        }
        else {
            string += " Taken on \(dateTime)\n"
        }
        if self.wi != nil {
            string += " \(self.wi.weatherType), \(self.wi.temp) \(celsius)\n"
        }
        else {
            string += "Weather information not available\n"
        }
        if userDescription != nil {
            string += "\n"
            string += "\(userDescription)"
        }
        
        textLayer.string = string
        
        let fontSize: CGFloat = 18
        
        // 3
        let fontName: CFStringRef = "Noteworthy-Light"
        textLayer.fontSize = 18
        textLayer.font = CTFontCreateWithName(fontName, fontSize, nil)
        
        // 4
        textLayer.foregroundColor = UIColor.blackColor().CGColor
        textLayer.wrapped = true
        textLayer.alignmentMode = kCAAlignmentCenter
        textLayer.backgroundColor = UIColor.clearColor().CGColor
        textLayer.contentsScale = UIScreen.mainScreen().scale
        weatherImageView.layer.addSublayer(textLayer)
    }
    
    /* Add the user info to the tiff dictionary */
    func setTiffDictionary(tiffDictionary: NSMutableDictionary) {
        
        if self.wi != nil {
            if imageDescription == nil && self.wi != nil && self.dateTime != nil {
                if userDescription == nil {
                    imageDescription = "Taken on \(dateTime)^\(self.wi.weatherType), \(self.wi.temp) \(celsius)\(self.wi.weatherTypeID)±"
                }
                else {
                    imageDescription = "Taken on \(dateTime)^\(self.wi.weatherType), \(self.wi.temp) \(celsius)\(self.wi.weatherTypeID)±\(userDescription)"
                }
                tiffDictionary.setObject(self.imageDescription, forKey: kCGImagePropertyTIFFImageDescription as NSString)
            }
        }
        else {
            if imageDescription == nil && self.dateTime != nil && userDescription == nil {
                imageDescription = "Taken on \(dateTime)^"
            }
            else if imageDescription == nil && self.dateTime != nil && userDescription != nil {
                imageDescription = "Taken on \(dateTime)^\(userDescription)"
            }
            tiffDictionary.setObject(self.imageDescription, forKey: kCGImagePropertyTIFFImageDescription as NSString)
        }
        
        if userDescription != nil && imageDescription == nil {
            imageDescription = "\(userDescription)"
            tiffDictionary.setObject(self.imageDescription, forKey: kCGImagePropertyTIFFImageDescription as NSString)
        }
        
    }
    
}
