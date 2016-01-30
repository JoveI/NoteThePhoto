//
//  PhotoAssetViewController.swift
//  CameraProba6
//
//  Created by Jovan Ivanovski on 8/21/15.
//  Copyright © 2015 Jovan Ivanovski. All rights reserved.
//

import UIKit
import Photos

class PhotoAssetViewController: UIViewController, PHPhotoLibraryChangeObserver  {
    
    //MARK: - Properties
    
    var asset: PHAsset!
    var index: Int!
    var assetsFetchResult: PHFetchResult!
    var assetCollection: PHAssetCollection!
    
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var noteThePhotoButton: UIBarButtonItem!
    @IBOutlet weak var favoriteButton: UIBarButtonItem!
    @IBOutlet weak var deleteButton: UIBarButtonItem!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var showImageInfoButton: UIBarButtonItem!
    @IBOutlet weak var infoImageView: UIImageView!
    
    private var lastImageViewSize: CGSize = CGSize()
    
    //Image properties
    var data: NSData!
    var UTI: String!
    var country: String!
    var city: String!
    var weatherType: String!
    var weatherString: String!
    var weatherTypeID: Int!
    var temp: String!
    let celsius: String = "\u{02103}"
    let fahrenheit: String = "\u{02109}"
    var dateAndTime: String!
    var otherCamImagaDateTime: Bool = false
    var userImageDescription: String!
    var isImageDescriptionInFocus: Bool = false
    var textLayer: CATextLayer!
    var finalText: String!
    var wi: WeatherInfo!
    
    private var image: UIImage!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        self.updateImage()
        
        //Left and right swipe recognizer
        let rightSwipeRecognizer: UISwipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: "rightChangePhotoSwipeHandler:")
        let leftSwipeRecognizer: UISwipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: "leftChangePhotoSwipeHandler:")
        rightSwipeRecognizer.direction = .Right
        leftSwipeRecognizer.direction = .Left
        self.view.addGestureRecognizer(rightSwipeRecognizer)
        self.view.addGestureRecognizer(leftSwipeRecognizer)
        
        //register observer
        PHPhotoLibrary.sharedPhotoLibrary().registerChangeObserver(self)
        
        //scrollView delegate
        self.scrollView.delegate = self
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 6.0
        
//        noteThePhotoButton.enabled = false
//        noteThePhotoButton.style = UIBarButtonItemStyle.Plain
//        noteThePhotoButton.title = ""
        
    }
    
    deinit {
        PHPhotoLibrary.sharedPhotoLibrary().unregisterChangeObserver(self)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // Update the interface buttons
        favoriteButton.enabled =
            asset.canPerformEditOperation(.Properties)
        deleteButton.enabled = asset.canPerformEditOperation(.Delete)
        updateFavoriteButton()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
//        self.navigationController?.interactivePopGestureRecognizer?.enabled = false
//        self.navigationController?.interactivePopGestureRecognizer?.delegate = self
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
//        self.navigationController?.interactivePopGestureRecognizer?.enabled = true
//        self.navigationController?.interactivePopGestureRecognizer?.delegate = nil
    }
    
    
    //MARK: - Actions
    
    @IBAction func noteThePhotoButtonHandler(sender: UIBarButtonItem) {
        performSegueWithIdentifier("noteThePhotoSegue", sender: self)
    }
    
    @IBAction func favoriteButtonAction(sender: UIBarButtonItem) {
        PHPhotoLibrary.sharedPhotoLibrary().performChanges ({
            let request = PHAssetChangeRequest(forAsset: self.asset)
            request.favorite = !self.asset.favorite
            }, completionHandler: { success, error in
                if success {
                    
                }
            }
        )
    }
    
    @IBAction func deleteButtonAction(sender: UIBarButtonItem) {
        PHPhotoLibrary.sharedPhotoLibrary().performChanges({
            PHAssetChangeRequest.deleteAssets([self.asset])
            }, completionHandler: { success, error in
                if success {
                    
                }
            }
        )
    }
    
    @IBAction func showImageInfoAction(sender: UIBarButtonItem) {
        
        imageInfo()
        
    }
    
    
    //MARK: - PHPhotoLibraryChangeObserver
    
    func photoLibraryDidChange(changeInstance: PHChange) {
        // Call might come on any background queue. Re-dispatch to the main queue to handle it.
        dispatch_async(dispatch_get_main_queue()) {
            
            // check if there are changes to the album we're interested on (to its metadata, not to its collection of assets)
            let changeDetails = changeInstance.changeDetailsForObject(self.asset)
            if changeDetails != nil {
                
                if changeDetails!.objectWasDeleted {
                    self.navigationController?.popViewControllerAnimated(true)
                    return
                }
                
                // it changed, we need to fetch a new one
                self.asset = changeDetails!.objectAfterChanges as! PHAsset
                
                if changeDetails!.assetContentChanged {
                    self.updateImage()
                }
                
                self.updateFavoriteButton()
            }
            
        }
    }
    
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        
        if segue.identifier == "noteThePhotoSegue" {
            let editPhotoVC = segue.destinationViewController as! EditPhotoViewController
            editPhotoVC.data = self.data
            editPhotoVC.UTI = self.UTI
            editPhotoVC.image = image
            editPhotoVC.assetCollection = self.assetCollection
            editPhotoVC.imgAsset = self.asset
            editPhotoVC.isImageAssetPicked = true
            editPhotoVC.wi = self.wi
            editPhotoVC.userDescription = self.userImageDescription
            editPhotoVC.dateTime = self.dateAndTime
        }
        
    }
    
    //MARK: - Handlers
    
    func rightChangePhotoSwipeHandler(rightSwipe: UISwipeGestureRecognizer) {
        if index - 1 > -1 {
            if let newAsset = self.assetsFetchResult![index - 1] as? PHAsset {
                asset = newAsset
                index = index - 1
            }
        }
        self.updateImage()
        if isImageDescriptionInFocus == true {
            imageInfo()
        }
    }
    
    func leftChangePhotoSwipeHandler(leftSwipe: UISwipeGestureRecognizer) {
        if index + 1 < assetsFetchResult.count {
            if let newAsset = self.assetsFetchResult![index + 1] as? PHAsset {
                asset = newAsset
                index = index + 1
            }
        }
        self.updateImage()
        if isImageDescriptionInFocus == true {
            imageInfo()
        }
    }
    
    
    //MARK: - Private functions
    
    /* Get the info for the image and change the current image to be the new one */
    private func updateImage() {
        
        let scale = UIScreen.mainScreen().scale
        let targetSize = CGSizeMake(CGRectGetWidth(self.imageView.bounds) * scale, CGRectGetHeight(self.imageView.bounds) * scale)
        
        let options = PHImageRequestOptions()
        
        // Download from cloud if necessary
        options.networkAccessAllowed = true
        options.deliveryMode = .HighQualityFormat
        options.progressHandler = {progress, error, stop, info in
            dispatch_async(dispatch_get_main_queue()) {
                self.progressView.progress = Float(progress)
                self.progressView.hidden = (progress <= 0.0 || progress >= 1.0)
            }
        }
        
        
        PHImageManager.defaultManager().requestImageDataForAsset(self.asset, options: options) { imageData, dataUTI, orientation, info in
            
            self.data = imageData
            self.UTI = dataUTI
            
            let meta = self.metadataFromImageData(imageData!)
            //print("\(meta)")
            var string = "\n"
            var countryNA = false
            
            //reset the weather info
            self.wi = nil
            
            if let exifDictionary = meta[kCGImagePropertyExifDictionary as String] as? [String : AnyObject] {
                
                if let tmpDateTime = exifDictionary[kCGImagePropertyExifDateTimeOriginal as String] as? String {
                    self.dateAndTime = tmpDateTime
                }
                
            }
            
            if let iptcDictionary = meta[kCGImagePropertyIPTCDictionary as String] as? [String : AnyObject] {
                
                if let tmpCountry = iptcDictionary[kCGImagePropertyIPTCProvinceState as String] as? String {
                    self.country = tmpCountry
                    string += "\(self.country)"
                    self.wi = WeatherInfo()
                    self.wi.country = tmpCountry
                }
                else {
                    countryNA = true
                }
                
                if let tmpCity = iptcDictionary[kCGImagePropertyIPTCCity as String] as? String {
                    self.city = tmpCity
                    string += ", \(self.city)\n"
                    self.wi.city = tmpCity
                }
                else {
                    if countryNA == true {
                        string += "Country and city info not available\n"
                    }
                }
            }
            else {
                string += "Country and city info not available\n"
            }
            
            if let tiffDictionary = meta[kCGImagePropertyTIFFDictionary as String] as? [String : AnyObject] {
                
                if let tiffTmpDateTime = tiffDictionary[kCGImagePropertyTIFFDateTime as String] as? String {
                    self.dateAndTime = tiffTmpDateTime
                    self.otherCamImagaDateTime = true
                }
                
                if let tmpImageDescription = tiffDictionary[kCGImagePropertyTIFFImageDescription as String] as? String {
                    
                    if let dateAndTimeRange = tmpImageDescription.rangeOfString("^") {
                        
                        self.dateAndTime = tmpImageDescription[tmpImageDescription.startIndex..<dateAndTimeRange.startIndex] as String
                        
                        self.otherCamImagaDateTime = false
                        
                        string += "\(self.dateAndTime)\n"
                        
                        if let weatherRange = tmpImageDescription.rangeOfString("\(self.celsius)") {
                            
                            let weatherStringStartIndex = dateAndTimeRange.startIndex.advancedBy(1)
                            
                            self.weatherString = tmpImageDescription[weatherStringStartIndex...weatherRange.startIndex] as String
                            
                            string += "\(self.weatherString)\n\n"
                            
                            
                            
                            let typeIDStartIndex = weatherRange.startIndex.advancedBy(1)
                            
                            if let typeIDRange = tmpImageDescription.rangeOfString("±") {
                                
                                self.weatherTypeID =  Int(tmpImageDescription[typeIDStartIndex..<typeIDRange.startIndex])
                                
                                let userDescStartIndex = typeIDRange.startIndex.advancedBy(1)
                                
                                self.userImageDescription = tmpImageDescription[userDescStartIndex..<tmpImageDescription.endIndex] as String
                                
                                if self.userImageDescription != nil {
                                    string += "\(self.userImageDescription)"
                                }
                            }
                            
                            if let weatherTypeRange = self.weatherString.rangeOfString(",") {
                                self.weatherType = self.weatherString[self.weatherString.startIndex..<weatherTypeRange.startIndex] as
                                String
                                
                                if let tempRange = self.weatherString.rangeOfString(self.celsius) {
                                    let tempStartIndex = weatherTypeRange.startIndex.advancedBy(1)
                                    self.temp = self.weatherString[tempStartIndex..<tempRange.startIndex] as String
                                    
                                    if self.wi == nil {
                                        self.wi = WeatherInfo()
                                        
                                        self.wi.weatherType = self.weatherType
                                        self.wi.temp = self.temp
                                        self.wi.weatherTypeID = self.weatherTypeID
                                    }
                                    else {
                                        self.wi.weatherType = self.weatherType
                                        self.wi.temp = self.temp
                                        self.wi.weatherTypeID = self.weatherTypeID
                                    }
                                }
                                
                                if self.wi == nil {
                                    self.wi = WeatherInfo()
                                    
                                    self.wi.weatherType = self.weatherType
                                }
                                else {
                                    self.wi.weatherType = self.weatherType
                                }
                                
                                
                            }
                        }
                        else { //WeatherRange to be nil and thus weatherString is nil to
                            if self.otherCamImagaDateTime == true {
                                string += "Taken on \(self.dateAndTime)\nWeather info not available\n\n"
                            }
                            else {
                                string += "Weather info not available\n\n"
                                
                            }
                            
                            let startIndex = dateAndTimeRange.startIndex.advancedBy(1)
                            
                            let userDesc = tmpImageDescription[startIndex..<tmpImageDescription.endIndex] as String
                            
                            self.userImageDescription = userDesc
                            
                            string += userDesc
                        }
                    }
                    else { //DateTime from imageDesc. to be nil thus weatherString is also nil
                        if self.otherCamImagaDateTime == true {
                            string += "Taken on \(self.dateAndTime)\nWeather info not available\n\n"
                        }
                        else {
                            string += "Weather info not available\n\n"
                        }
                        
                        //Ovde user desc?
                        self.userImageDescription = tmpImageDescription
                    }
                }
                else { //Image Description to be nil => we only got the dateAndTime if it exist in the image metadata
                    if self.otherCamImagaDateTime == true {
                        string += "Taken on \(self.dateAndTime)\nWeather info not available\n\n"
                    }
                    else {
                        string += "Weather info not available\n\n"
                    }
                }
            }
            else { //Tiff dictionary is nil => we only got the dateAndTime if it exist in the image metadata
                if self.otherCamImagaDateTime == true {
                    string += "Taken on \(self.dateAndTime)\nWeather info not available\n\n"
                }
                else {
                    string += "Weather info not available\n\n"
                }
            }
            
            self.finalText = string
        }
        
        PHImageManager.defaultManager().requestImageForAsset(self.asset, targetSize: targetSize, contentMode: .AspectFit, options: options) {result, info in
            if result != nil {
                UIView.transitionWithView(self.imageView, duration: 0.6, options: UIViewAnimationOptions.TransitionCrossDissolve, animations: {
                    self.imageView.frame = self.scrollView.bounds
                    self.imageView.contentMode = UIViewContentMode.ScaleAspectFit
                    self.scrollView.contentSize = self.imageView.frame.size
                    self.imageView.image = result
                    }, completion: nil)
                self.image = result
                
            }
        }
    }
    
    func updateFavoriteButton() {
        if asset.favorite == true {
            favoriteButton.image = UIImage(named: "HeartsFilled-32")
        }
        else {
            favoriteButton.image = UIImage(named: "Hearts-32")
        }
    }
    
    //MARK - Helper Functions
    
    func metadataFromImageData(imageData: NSData) -> NSDictionary {
        var result: NSDictionary = NSDictionary()
        if let imageSource: CGImageSourceRef = CGImageSourceCreateWithData(imageData, nil) {
            let options: [String : AnyObject] = [kCGImageSourceShouldCache as String: NSNumber(bool: false)] as [String : AnyObject]
            if let imageProperties: CFDictionaryRef = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, options) {
                result = NSDictionary(dictionary: imageProperties)
            }
        }
        return result
    }
    
    /* Add text sublayer with the image info to the image */
    func addText() {
        textLayer = CATextLayer()
        textLayer.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height)
        
        textLayer.string = finalText
        
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
        self.infoImageView.layer.addSublayer(textLayer)
    }
    
    /* Show the image info */
    func imageInfo() {
        
        if isImageDescriptionInFocus == false {
            
            self.infoImageView = ImageProcessingHelper.showImageInfo(self.infoImageView, wi: wi, dateTime: self.dateAndTime)
            
            isImageDescriptionInFocus = true
            addText()
        }
            
        else {
            
            if textLayer != nil {
                textLayer.removeFromSuperlayer()
            }
            self.infoImageView.alpha = 0.0
            self.infoImageView.image = nil
            
            isImageDescriptionInFocus = false
        }
        

    }

}


extension PhotoAssetViewController: UIScrollViewDelegate {
    
    func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
}

extension PhotoAssetViewController: UIGestureRecognizerDelegate {
    
    func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool {
        return false
    }
    
}
