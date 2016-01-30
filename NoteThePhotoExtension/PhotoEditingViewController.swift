//
//  PhotoEditingViewController.swift
//  NoteThePhotoExtension
//
//  Created by Jovan Ivanovski on 9/14/15.
//  Copyright © 2015 Jovan Ivanovski. All rights reserved.
//

import UIKit
import Photos
import PhotosUI
import AssetsLibrary

class PhotoEditingViewController: UIViewController, PHContentEditingController {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var infoImageView: UIImageView!
    
    var input: PHContentEditingInput?

    var data: NSData!
    var metadata: NSMutableDictionary!
    var newData: NSData!
    var imageToSave: UIImage!
    var imageToDeleteURL: NSURL!
    
    var al: ALAssetsLibrary = ALAssetsLibrary()
    private var isStillImageInFocus: Bool = true
    var wi: WeatherInfo!
    var dateTime: String!
    var textLayer: CATextLayer!
    var string: String!
    var userDescription: String!
    var isWriting: Bool = false
    var textView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        let leftSwipe = UISwipeGestureRecognizer(target: self, action: "leftSwipeHandler:")
        leftSwipe.direction = .Left
        self.view.addGestureRecognizer(leftSwipe)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: "tapHandler:")
        tapGesture.numberOfTapsRequired = 1
        self.view.addGestureRecognizer(tapGesture)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - PHContentEditingController

    func canHandleAdjustmentData(adjustmentData: PHAdjustmentData?) -> Bool {
        // Inspect the adjustmentData to determine whether your extension can work with past edits.
        // (Typically, you use its formatIdentifier and formatVersion properties to do this.)
        return false
    }

    func startContentEditingWithInput(contentEditingInput: PHContentEditingInput?, placeholderImage: UIImage) {
        // Present content for editing, and keep the contentEditingInput for use when closing the edit session.
        // If you returned YES from canHandleAdjustmentData:, contentEditingInput has the original image and adjustment data.
        // If you returned NO, the contentEditingInput has past edits "baked in".
        input = contentEditingInput
        
        self.imageView.image = input?.displaySizeImage
        
        let url: NSURL = (input?.fullSizeImageURL)!
        
        let data = NSData(contentsOfURL: url)
        
        self.data = data
        
        self.imageToSave = UIImage(data: self.data)
        
        //let mutableData = NSMutableData(data: data!)
        let imageSource: CGImageSourceRef = CGImageSourceCreateWithData(data!, nil)!
        
        let metadata: NSDictionary = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil)!
        let mutableMetadata: NSMutableDictionary = metadata.mutableCopy() as! NSMutableDictionary
        self.metadata = mutableMetadata
        
        print("mm: \(mutableMetadata)")
        
        let parseMetadataResult = ImageProcessingHelper.parseMetadata(mutableMetadata)
        self.dateTime = parseMetadataResult.dateAndTime
        self.wi = parseMetadataResult.wi
        self.string = parseMetadataResult.string
        self.userDescription = parseMetadataResult.userDescription
        
//        print("\(mutableMetadata)")
//        
//        let tiffDictionary: NSMutableDictionary = mutableMetadata.objectForKey(kCGImagePropertyTIFFDictionary as NSString)!.mutableCopy() as! NSMutableDictionary
//        
//        tiffDictionary.setObject("proba", forKey: kCGImagePropertyTIFFImageDescription as String)
//        
//        mutableMetadata.setObject(tiffDictionary, forKey: kCGImagePropertyTIFFDictionary as String)
//        
//        self.metadata = mutableMetadata
//        
//        let imgDataProvider: CGDataProviderRef = CGDataProviderCreateWithCFData(data)!
//        let imageRef: CGImageRef = CGImageCreateWithJPEGDataProvider(imgDataProvider, nil, true, CGColorRenderingIntent.RenderingIntentDefault)!
//        
//        let UTI: CFStringRef = CGImageSourceGetType(imageSource)!
//        
//        //save to disk
//        let newImageDataRef: CFMutableDataRef = CFDataCreateMutable(nil, 0)
//        let destination: CGImageDestinationRef = CGImageDestinationCreateWithData(newImageDataRef, UTI, 1, nil)!
//        CGImageDestinationAddImage(destination, imageRef, mutableMetadata)
//        
//        if CGImageDestinationFinalize(destination) {
//           
//            let newData: NSData = newImageDataRef
//            
//            self.newData = newData
//            
//            self.imageToSave = UIImage(data: newData)
//        }
    }

    func finishContentEditingWithCompletionHandler(completionHandler: ((PHContentEditingOutput!) -> Void)!) {
        // Update UI to reflect that editing has finished and output is being rendered.
        
        // Render and provide output on a background queue.
        dispatch_async(dispatch_get_global_queue(CLong(DISPATCH_QUEUE_PRIORITY_DEFAULT), 0)) {
            // Create editing output from the editing input.
            let output = PHContentEditingOutput(contentEditingInput: self.input!)
            
            self.imageToDeleteURL = output.renderedContentURL
            
            // Provide new adjustments and render output to given location.
            // output.adjustmentData = <#new adjustment data#>
            // let renderedJPEGData = <#output JPEG#>
            // renderedJPEGData.writeToURL(output.renderedContentURL, atomically: true)
            
            let tiffDictionary: NSMutableDictionary = self.metadata.objectForKey(kCGImagePropertyTIFFDictionary as NSString)!.mutableCopy() as! NSMutableDictionary
            
            let tiffImageDescription = tiffDictionary.objectForKey(kCGImagePropertyTIFFImageDescription as NSString) as! String
            
            var newImageDescription: String!
            
            if let userDescRange = tiffImageDescription.rangeOfString("±") {
                
                let previousDesc = tiffImageDescription[tiffImageDescription.startIndex...userDescRange.startIndex]
                
                newImageDescription = "\(previousDesc)\(self.userDescription)"
                
            }
            
            if newImageDescription != nil {
                tiffDictionary.setObject(newImageDescription, forKey: kCGImagePropertyTIFFImageDescription as NSString)
            }
            
            self.metadata.setObject(tiffDictionary, forKey: kCGImagePropertyTIFFDictionary as NSString)

            let meta = self.metadata
            let data = self.data
            
            self.al.writeImageDataToSavedPhotosAlbum(data, metadata: meta as [NSObject : AnyObject], completionBlock: { _,_ in
                
            })
            
//            PHPhotoLibrary.sharedPhotoLibrary().performChanges({
//                let imageAssetToDelete = PHAsset.fetchAssetsWithALAssetURLs([self.imageToDeleteURL], options: nil)
//                PHAssetChangeRequest.deleteAssets([imageAssetToDelete])
//                }, completionHandler: { success, error in
//                    if success {
//                        print("deleted")
//                    }
//                }
//            )

            
//            PHPhotoLibrary.sharedPhotoLibrary().performChanges({
//                let req = PHAssetChangeRequest.creationRequestForAssetFromImage(self.imageToSave)
//                }, completionHandler: { success, error in
//                    if success == true {
//                        print("snimena")
//                    }
//                    else {
//                        print("error saving image: \(error)")
//                    }
//                }
//            )
            
            // Call completion handler to commit edit to Photos.
            completionHandler?(output)
            
            // Clean up temporary files, etc.
        }
    }

    var shouldShowCancelConfirmation: Bool {
        // Determines whether a confirmation to discard changes should be shown to the user on cancel.
        // (Typically, this should be "true" if there are any unsaved changes.)
        return false
    }

    func cancelContentEditing() {
        // Clean up temporary files, etc.
        // May be called after finishContentEditingWithCompletionHandler: while you prepare output.
    }
    
    
    // MARK: - Actions
    

    
    // MARK - Helper Functions
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
    
    
    // MARK: - Handlers
    func leftSwipeHandler(gesture: UISwipeGestureRecognizer) {
            
        if isStillImageInFocus == true {
            
            self.infoImageView = ImageProcessingHelper.showImageInfo(self.infoImageView, wi: self.wi, dateTime: self.dateTime)
            
            isStillImageInFocus = false
            self.textLayer = ImageProcessingHelper.addText(self.textLayer, string: self.string, wi: self.wi, dateTime: self.dateTime, userDescription: self.userDescription, view: self.view)
            
            self.infoImageView.layer.addSublayer(self.textLayer)
            
        }
        else {
            
            UIView.animateWithDuration(0.3,
                animations: {
                    self.imageView.alpha = 1.0
                    self.infoImageView.alpha = 0.0
                    self.infoImageView.image = nil
                    if self.textLayer != nil {
                        self.textLayer.backgroundColor = nil
                        self.textLayer.removeFromSuperlayer()
                    }
                }
            )
            isStillImageInFocus = true
            
        }

    }
    
    func tapHandler(tap: UITapGestureRecognizer) {
        if isWriting == false && self.infoImageView.alpha > 0.0 {
            isWriting = true
            textView = UITextView()
            textView.frame = CGRect(origin: CGPoint(x: 0, y: tap.locationInView(imageView).y), size: CGSize(width: self.view.frame.width, height: 100))
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
            self.infoImageView.addSubview(textView)
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
            
            self.textLayer = ImageProcessingHelper.addText(self.textLayer, string: self.string, wi: self.wi, dateTime: self.dateTime, userDescription: self.userDescription, view: self.view)
            
            self.infoImageView.layer.addSublayer(self.textLayer)
        }
    }
}
