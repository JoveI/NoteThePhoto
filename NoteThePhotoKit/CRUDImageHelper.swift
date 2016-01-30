//
//  CRUDImageHelper.swift
//  CameraProba6
//
//  Created by Jovan Ivanovski on 9/1/15.
//  Copyright © 2015 Jovan Ivanovski. All rights reserved.
//

import UIKit
import Photos
import CoreGraphics
import ImageIO
import MobileCoreServices

let ImageAssetAdjustmentFormatIdentifier = "com.ji.finki.CameraProba6.adjustmentFormatID"

public class CRUDImageHelper: NSObject {
    
    // MARK: Image Creation
    public class func createNewStitchWith(image: UIImage, inCollection collection: PHAssetCollection) {
        
        var imagePlaceholder: PHObjectPlaceholder!
        PHPhotoLibrary.sharedPhotoLibrary().performChanges({
            // 3
            let assetChangeRequest =
            PHAssetChangeRequest.creationRequestForAssetFromImage(
                image)
            imagePlaceholder =
                assetChangeRequest.placeholderForCreatedAsset
            
            
            
            // 4
            let assetCollectionChangeRequest =
            PHAssetCollectionChangeRequest(
                forAssetCollection: collection)
            assetCollectionChangeRequest!.addAssets(
                [imagePlaceholder])
            }, completionHandler: { _, _ in
                // Fetch the asset and add modification data to it
                let fetchResult = PHAsset.fetchAssetsWithLocalIdentifiers(
                    [imagePlaceholder.localIdentifier], options: nil)
                let imageAsset = fetchResult[0] as! PHAsset
                
                self.editStitchContentWith(imageAsset,
                    image: image)
        })
    }
    
    // MARK: Stitch Content
    class func editStitchContentWith(imageAsset: PHAsset, image: UIImage) {
        
        //let imageJPEG = UIImageJPEGRepresentation(image, 0.9)
        let assetID = imageAsset.localIdentifier
        let assetsData = NSKeyedArchiver.archivedDataWithRootObject(assetID)
        
        //print("can: \(imageAsset.canPerformEditOperation(PHAssetEditOperation.Content))")
        
        // 2
        imageAsset.requestContentEditingInputWithOptions(nil)
            {  contentEditingInput, _ in
                
                //Moe proba
                //get the full image
                let url = contentEditingInput?.fullSizeImageURL
                let imageJPEG: NSData = UIImageJPEGRepresentation(image, 1.0)!
                //let data: NSData = NSData(contentsOfURL: (contentEditingInput?.fullSizeImageURL)!)!
                //let inputImage = CIImage(contentsOfURL: url!)
                //let inputUIImage = UIImage(data: data)
                //print("jpeg: \(metadataFromImageData(imageJPEG))")
                
                //get the original photo metadata
                let originalImageMetadata: NSData = NSData(contentsOfURL: url!)!
                let imageSource = CGImageSourceCreateWithData(originalImageMetadata, nil)!
                let metadata: NSDictionary = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil)!
                let mutableMetadata: NSMutableDictionary = metadata.mutableCopy() as! NSMutableDictionary
                let tiffDictionary: NSMutableDictionary = mutableMetadata.objectForKey(kCGImagePropertyTIFFDictionary as NSString)!.mutableCopy() as! NSMutableDictionary
                tiffDictionary.setObject("stitch", forKey: kCGImagePropertyTIFFImageDescription as NSString)
                mutableMetadata.setObject(tiffDictionary, forKey: kCGImagePropertyTIFFDictionary as NSString)
                
                print("mutable: \(mutableMetadata)")
                
                let imgDataProvider: CGDataProviderRef = CGDataProviderCreateWithCFData(originalImageMetadata)!
                let imageRef: CGImageRef = CGImageCreateWithJPEGDataProvider(imgDataProvider, nil, true, CGColorRenderingIntent.RenderingIntentDefault)!
                
                let srcRef: CGImageSourceRef = CGImageSourceCreateWithData(originalImageMetadata, nil)!
                let UTI: CFStringRef = CGImageSourceGetType(srcRef)!
                
                //save to disk
                let dataRef: CFMutableDataRef = CFDataCreateMutable(nil, 0)
                let destination: CGImageDestinationRef = CGImageDestinationCreateWithData(dataRef, UTI, 0, nil)!
                CGImageDestinationAddImage(destination, imageRef, mutableMetadata)
                //CGImageDestinationFinalize(destination)
                
                //let newData = NSData(data: dataRef)
                
                //let m: CGImageMetadataRef = CGImageMetadataCreateFromXMPData(newData)!
                //CGImageDestinationAddImageAndMetadata(destination, imageRef, m, nil)
                
                // 3
                let adjustmentData = PHAdjustmentData(formatIdentifier:
                    ImageAssetAdjustmentFormatIdentifier, formatVersion: "1.0",
                    data: assetsData)
                
                if CGImageDestinationFinalize(destination) {
                    let contentEditingOutput = PHContentEditingOutput(contentEditingInput: contentEditingInput!)
                    //imageJPEG?.writeToURL(contentEditingOutput.renderedContentURL, atomically: true)
                    contentEditingOutput.adjustmentData = adjustmentData
                    let imageData: NSData = dataRef
                    do {
                        try imageData.writeToURL(contentEditingOutput.renderedContentURL, options: NSDataWritingOptions.DataWritingAtomic)
                        PHPhotoLibrary.sharedPhotoLibrary().performChanges({
                            let request = PHAssetChangeRequest(forAsset: imageAsset)
                            request.contentEditingOutput = contentEditingOutput
                            }, completionHandler: { success, error in
                                if success == false {
                                    print("compl. handl. error: \(error)")
                                }
                            }
                        )
                    }
                    catch {
                        print("error: \(error)")
                    }
                }
                
                //      // 4
                //      let contentEditingOutput = PHContentEditingOutput(
                //        contentEditingInput: contentEditingInput!)
                //      stitchJPEG!.writeToURL(
                //        contentEditingOutput.renderedContentURL, atomically: true)
                //      contentEditingOutput.adjustmentData = adjustmentData
                //      // 5
                //      PHPhotoLibrary.sharedPhotoLibrary().performChanges({
                //        let request = PHAssetChangeRequest(forAsset: stitch)
                //        request.contentEditingOutput = contentEditingOutput
                //      }, completionHandler: nil)
        }
    }
    
    //MARK - Helper Functions
    class func metadataFromImageData(imageData: NSData) -> NSDictionary {
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
