//
//  AssetCollectionTableViewController.swift
//  CameraProba6
//
//  Created by Jovan Ivanovski on 8/21/15.
//  Copyright © 2015 Jovan Ivanovski. All rights reserved.
//

import UIKit
import Photos

class AssetCollectionTableViewController: UITableViewController, PHPhotoLibraryChangeObserver {
    
    //MARK: - Properties
    
    var collectionsFetchResults: [PHFetchResult] = []
    var collectionsLocalizedTitles: [String] = []
    
    private final let AllPhotosReuseIdentifier = "AllPhotosCell"
    private final let CollectionCellReuseIdentifier = "CollectionCell"
    
    private final let AllPhotosSegue = "showAllPhotos"
    private final let CollectionSegue = "showCollection"
    private final let FavoritesSegue = "showFavorites"
    
    override func awakeFromNib() {
        let smartAlbums = PHAssetCollection.fetchAssetCollectionsWithType(.SmartAlbum, subtype: .SmartAlbumFavorites, options: nil)
        let topLevelUserCollections = PHCollectionList.fetchTopLevelUserCollectionsWithOptions(nil)
        self.collectionsFetchResults = [smartAlbums, topLevelUserCollections]
        self.collectionsLocalizedTitles = [NSLocalizedString("Smart Albums", comment: ""), NSLocalizedString("Albums", comment: "")]
        
        PHPhotoLibrary.sharedPhotoLibrary().registerChangeObserver(self)
    }
    
    deinit {
        PHPhotoLibrary.sharedPhotoLibrary().unregisterChangeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Swipe gesture recognizer
        let rightSwipe: UISwipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: "rightSwipeHandler:")
        rightSwipe.direction = .Right
        self.view.addGestureRecognizer(rightSwipe)
    }
    
    //MARK: - Navigation, prepareForSegue
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == AllPhotosSegue {
            
            let indexPath = self.tableView.indexPathForCell(sender as! UITableViewCell)!
            
            let assetViewController = segue.destinationViewController as! AssetsViewController
            // Fetch all assets, sorted by date created.
            let options = PHFetchOptions()
            options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending:true)]
            let fetchReslult: PHFetchResult = PHAssetCollection.fetchTopLevelUserCollectionsWithOptions(nil)
            assetViewController.assetsFetchResults = PHAsset.fetchAssetsWithOptions(options)
            
            let collection = fetchReslult[indexPath.row] as! PHAssetCollection
            assetViewController.assetCollection = collection
            
            assetViewController.collectionTitle = "All Photos"
            
            
        } else if segue.identifier == FavoritesSegue {
            let assetViewController = segue.destinationViewController as! AssetsViewController
            
            let indexPath = self.tableView.indexPathForCell(sender as! UITableViewCell)!
            let fetchResult = self.collectionsFetchResults[indexPath.section - 1] as PHFetchResult
            let collection = fetchResult[indexPath.row] as! PHCollection
            if collection is PHAssetCollection {
                let assetCollection = collection as! PHAssetCollection
                let assetsFetchResult = PHAsset.fetchAssetsInAssetCollection(assetCollection, options: nil)
                assetViewController.assetsFetchResults = assetsFetchResult
                assetViewController.collectionTitle = collection.localizedTitle
                //assetGridViewController.assetsFetchResults = assetsFetchResult
                assetViewController.assetCollection = assetCollection
            }
        }
    }
    
    //MARK: - Selector
    
    func rightSwipeHandler(gesture: UISwipeGestureRecognizer) {
        performSegueWithIdentifier("backToCamera", sender: self)
    }
    
    //MARK: - UITableViewDataSource
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1 + self.collectionsFetchResults.count
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var numberOfRows = 0
        if section == 0 {
            numberOfRows = 1 // "All Photos" section
        } else {
            let fetchResult = self.collectionsFetchResults[section - 1] as PHFetchResult
            numberOfRows = fetchResult.count
        }
        return numberOfRows
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell: UITableViewCell
        var localizedTitle: String
        
        if indexPath.section == 0 {
            cell = tableView.dequeueReusableCellWithIdentifier(AllPhotosReuseIdentifier, forIndexPath: indexPath) as UITableViewCell
            localizedTitle = NSLocalizedString("All Photos", comment: "")
        } else {
            cell = tableView.dequeueReusableCellWithIdentifier(CollectionCellReuseIdentifier, forIndexPath: indexPath) as UITableViewCell
            let fetchResult = self.collectionsFetchResults[indexPath.section - 1] as PHFetchResult
            let collection = fetchResult[indexPath.row] as! PHCollection
            localizedTitle = collection.localizedTitle!
        }
        cell.textLabel?.text = localizedTitle
        
        return cell
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        var title: String? = nil
        if section > 0 {
            title = self.collectionsLocalizedTitles[section - 1]
        }
        return title
    }
    
    //MARK: - PHPhotoLibraryChangeObserver
    
    func photoLibraryDidChange(changeInstance: PHChange) {
        // Call might come on any background queue. Re-dispatch to the main queue to handle it.
        dispatch_async(dispatch_get_main_queue()) {
            
            var updatedCollectionsFetchResults: [PHFetchResult] = []
            
            for collectionsFetchResult in self.collectionsFetchResults {
                let changeDetails = changeInstance.changeDetailsForFetchResult(collectionsFetchResult)
                if changeDetails != nil {
                    if updatedCollectionsFetchResults.isEmpty {
                        updatedCollectionsFetchResults = self.collectionsFetchResults
                    }
                    let index = self.collectionsFetchResults.indexOf(collectionsFetchResult)
                    updatedCollectionsFetchResults[index!] = changeDetails!.fetchResultAfterChanges
                }
            }
            
            if !updatedCollectionsFetchResults.isEmpty {
                self.collectionsFetchResults = updatedCollectionsFetchResults
                self.tableView.reloadData()
            }
            
        }
    }
    
}