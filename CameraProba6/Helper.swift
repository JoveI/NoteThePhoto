//
//  Helper.swift
//  CameraProba6BackUp3
//
//  Created by Jovan Ivanovski on 9/11/15.
//  Copyright © 2015 Jovan Ivanovski. All rights reserved.
//

import UIKit
import Photos
import CoreGraphics
import ImageIO
import MobileCoreServices
import AssetsLibrary


let StitchAdjustmentFormatIdentifier = "RW.stitch.adjustmentFormatID"

class Helper: NSObject {
    
    // MARK: Stitch Content
    class func editStitchContentWith(imgAsset: PHAsset, image: UIImage, data: NSData) {
        
        let changedData = "\(kCGImagePropertyTIFFImageDescription) changed"
        let adjustmentData = PHAdjustmentData(formatIdentifier:
            kCGImagePropertyTIFFImageDescription as String, formatVersion: "1.0",
            data: changedData.dataUsingEncoding(NSUTF8StringEncoding)!)
        
        let jpeg = UIImageJPEGRepresentation(image, 1.0)
        
        if imgAsset.canPerformEditOperation(PHAssetEditOperation.Content) {
            
            imgAsset.requestContentEditingInputWithOptions(nil)
                {  contentEditingInput, info in
                    
                    //Moe proba
                    //get the full image
                    //let url = contentEditingInput?.fullSizeImageURL
                    
                    //get the original photo metadata
                    //let originalImageMetadata: NSData = NSData(contentsOfURL: url!)!
                    let imageSource = CGImageSourceCreateWithData(data, nil)!
                    let metadata: NSDictionary = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil)!
                    let mutableMetadata: NSMutableDictionary = metadata.mutableCopy() as! NSMutableDictionary
                    let tiffDictionary: NSMutableDictionary = mutableMetadata.objectForKey(kCGImagePropertyTIFFDictionary as NSString)!.mutableCopy() as! NSMutableDictionary
                    tiffDictionary.setObject("stitch", forKey: kCGImagePropertyTIFFImageDescription as NSString)
                    mutableMetadata.setObject(tiffDictionary, forKey: kCGImagePropertyTIFFDictionary as NSString)
                    
                    let validMetadataKeys: [String] = [kCGImagePropertyTIFFDictionary as String, kCGImagePropertyGIFDictionary as String,kCGImagePropertyJFIFDictionary as String,kCGImagePropertyExifDictionary as String,kCGImagePropertyPNGDictionary as String,kCGImagePropertyIPTCDictionary as String,kCGImagePropertyGPSDictionary as String,kCGImagePropertyRawDictionary as String,kCGImagePropertyCIFFDictionary as String,kCGImageProperty8BIMDictionary as String,kCGImagePropertyDNGDictionary as String,kCGImagePropertyExifAuxDictionary as String]
                    
                    let validMetadata: NSMutableDictionary = NSMutableDictionary()
                    
                    mutableMetadata.enumerateKeysAndObjectsUsingBlock { key, object, stop in
                        if validMetadataKeys.contains(key as! String) {
                            validMetadata[key as! String] = object
                        }
                    }
                    
                    //print("valid: \(validMetadata)")
                    
                    let imgDataProvider: CGDataProviderRef = CGDataProviderCreateWithCFData(data)!
                    let imageRef: CGImageRef = CGImageCreateWithJPEGDataProvider(imgDataProvider, nil, true, CGColorRenderingIntent.RenderingIntentDefault)!
                    
                    let UTI: CFStringRef = CGImageSourceGetType(imageSource)!
                    
                    //save to disk
                    let newImageDataRef: CFMutableDataRef = CFDataCreateMutable(nil, 0)
                    let destination: CGImageDestinationRef = CGImageDestinationCreateWithData(newImageDataRef, UTI, 0, nil)!
                    CGImageDestinationAddImage(destination, imageRef, validMetadata)
                    
                    
                    if CGImageDestinationFinalize(destination) {
                        //let newImageData: NSData = newImageDataRef
                        let contentEditingOutput = PHContentEditingOutput(contentEditingInput: contentEditingInput!)
                        contentEditingOutput.adjustmentData = adjustmentData
                        jpeg!.writeToURL(contentEditingOutput.renderedContentURL, atomically: true)
                        // 5
                        PHPhotoLibrary.sharedPhotoLibrary().performChanges({
                            let request = PHAssetChangeRequest(forAsset: imgAsset)
                            request.contentEditingOutput = contentEditingOutput
                            }, completionHandler: { success, error in
                                
                                if success == false {
                                    //print("info: \(info.description)")
                                    print("\(error)")
                                }
                                
                            }
                        )
                    }
            }
        }
    }
    
    
    //Moe proba
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
    
    
}
