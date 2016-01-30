//
//  AssetsViewController.swift
//  CameraProba6
//
//  Created by Jovan Ivanovski on 8/21/15.
//  Copyright © 2015 Jovan Ivanovski. All rights reserved.
//

import UIKit
import Photos

extension NSIndexSet {
    func aapl_indexPathsFromIndexesWithSection(section: Int) -> [NSIndexPath] {
        var indexPaths: [NSIndexPath] = []
        indexPaths.reserveCapacity(self.count)
        self.enumerateIndexesUsingBlock {idx, stop in
            indexPaths.append(NSIndexPath(forItem: idx, inSection: section))
        }
        return indexPaths
    }
}


private let reuseIdentifier = "Cell"

class AssetsViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout, PHPhotoLibraryChangeObserver  {
    
    //MARK: - Properties
    
    let AssetCollectionViewCellReuseIdentifier = "AssetCell"
    
    var assetsFetchResults: PHFetchResult?
    var assetCollection: PHAssetCollection!
    var collectionTitle: String!
    
    
    @IBOutlet var myCollectionView: UICollectionView!
    @IBOutlet weak var collectionNavigationTitle: UINavigationItem!
    
    private var assetThumbnailSize = CGSizeZero
    
    //Variables needed for caching
    private let imageManager: PHCachingImageManager = PHCachingImageManager()
    private var cachingIndexes: [NSIndexPath] = []
    private var lastCacheFrameCenter: CGFloat = 0 //latest scroll position
    
    var viewDidLayoutSubviewsForTheFirstTime = false
    
    // MARK: UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        PHPhotoLibrary.sharedPhotoLibrary().registerChangeObserver(self)
        collectionView!.allowsMultipleSelection = true
        
        resetCache()
        
        viewDidLayoutSubviewsForTheFirstTime = true
                
    }
    
    deinit {
        PHPhotoLibrary.sharedPhotoLibrary().unregisterChangeObserver(self)
    }
    
    override func viewWillAppear(animated: Bool)  {
        super.viewWillAppear(animated)
        
        // Calculate Thumbnail Size
        let scale = UIScreen.mainScreen().scale
        let cellSize = (myCollectionView.collectionViewLayout as! UICollectionViewFlowLayout).itemSize
        assetThumbnailSize = CGSize(width: cellSize.width * scale, height: cellSize.height * scale)
        
        myCollectionView.reloadData()
        resetCache()
        
        collectionNavigationTitle.title = collectionTitle

    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if viewDidLayoutSubviewsForTheFirstTime == true {
            
            
            let item = self.collectionView(self.collectionView!, numberOfItemsInSection: 0) - 1
            let lastItemIndex = NSIndexPath(forItem: item, inSection: 0)
            if item > -1 {
                self.collectionView?.scrollToItemAtIndexPath(lastItemIndex, atScrollPosition: UICollectionViewScrollPosition.Top, animated: false)
            }
            
            viewDidLayoutSubviewsForTheFirstTime = false
        }
    }
    
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
        collectionView!.reloadData()
    }
    
    // MARK: UICollectionViewDelegate
    
    override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath)  {
        
    }
    
    override func collectionView(collectionView: UICollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath)  {
        if assetsFetchResults == nil {
            collectionView.deleteItemsAtIndexPaths([indexPath])
        }
    }
    
    
    // MARK: UICollectionViewDataSource
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let fetchResult = assetsFetchResults {
            return fetchResult.count
        }
        return 0
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(AssetCollectionViewCellReuseIdentifier, forIndexPath: indexPath) as! AssetCell
        
        // Populate Cell
        let reuseCount = ++cell.reuseCount
        let asset = currentAssetAtIndex(indexPath.item)
        
        let options = PHImageRequestOptions()
        options.networkAccessAllowed = true
        
        imageManager.requestImageForAsset(asset, targetSize: assetThumbnailSize, contentMode: .AspectFit, options: options) { result, info in
            if reuseCount == cell.reuseCount {
                cell.imageView.contentMode = UIViewContentMode.ScaleAspectFill
                cell.imageView.image = result
            }
        }
        
        return cell
    }
    
    // MARK: UICollectionViewDelegateFlowLayout
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        var thumbsPerRow: Int
        switch collectionView.bounds.size.width {
        case 0..<400:
            thumbsPerRow = 4
        case 400..<600:
            thumbsPerRow = 5
        case 600..<800:
            thumbsPerRow = 6
        case 800..<1200:
            thumbsPerRow = 7
        default:
            thumbsPerRow = 4
        }
        let width = myCollectionView.bounds.size.width / CGFloat(thumbsPerRow)
        return CGSize(width: width,height: width)
    }
    
    // MARK: Caching
    
    func resetCache() {
        imageManager.stopCachingImagesForAllAssets()
        cachingIndexes.removeAll(keepCapacity: true)
        lastCacheFrameCenter = 0
    }
    
    func updateCache() {
        //1. Determine whether or not you want to cache.
        let currentFrameCenter = CGRectGetMidY(collectionView!.bounds)
        if abs(currentFrameCenter - lastCacheFrameCenter) < (CGRectGetHeight(collectionView!.bounds) / 2) {
            return
        }
        lastCacheFrameCenter = currentFrameCenter
        let numberOffscreenAssetsToCache = 60
        
        //2. Get all the visible indexes, sorted from top to bottom.
        var visibleIndexes = collectionView!.indexPathsForVisibleItems() as [NSIndexPath]
        visibleIndexes.sortInPlace { a, b in
            a.item < b.item
        }
        if visibleIndexes.count == 0 {
            return
        }
        
        //3. Calculate the range of indexes you want to cache.
        var totalItemCount = assetsFetchResults?.count
        if let fetchResults = assetsFetchResults {
            totalItemCount = fetchResults.count
        }
        let lastItemToCache = min(totalItemCount!, visibleIndexes[visibleIndexes.count-1].item + numberOffscreenAssetsToCache/2)
        let firstItemToCache = max(0, visibleIndexes[0].item - numberOffscreenAssetsToCache / 3)
        
        //4. Stop caching items that were previously cached but are now out-of-range.
        let options = PHImageRequestOptions()
        options.networkAccessAllowed = true
        
        //4.1
        var indexesToStopCaching: [NSIndexPath] = []
        cachingIndexes = cachingIndexes.filter { index in
            if index.item < firstItemToCache || index.item > lastItemToCache {
                indexesToStopCaching.append(index)
                return false
            }
            return true
        }
        //4.2
        imageManager.stopCachingImagesForAssets(assetsAtIndexPaths(indexesToStopCaching), targetSize: assetThumbnailSize, contentMode: .AspectFill, options: options)
        
        //5. Start caching any new items that have entered the caching range.
        //5.1
        var indexesToStartCaching: [NSIndexPath] = []
        for i in firstItemToCache..<lastItemToCache {
            let matching = cachingIndexes.filter { index in
                index.item == i
            }
            if matching.count == 0 {
                let indexPath = NSIndexPath(forItem: i, inSection: 0)
                indexesToStartCaching.append(indexPath)
            }
        }
        cachingIndexes += indexesToStartCaching
        //5.2
        imageManager.startCachingImagesForAssets(assetsAtIndexPaths(indexesToStartCaching), targetSize: assetThumbnailSize, contentMode: .AspectFill, options: options)
    }
    
    
    func assetsAtIndexPaths(indexPaths: [NSIndexPath]) -> [PHAsset] {
        var assets: [PHAsset] = []
        for indexPath in indexPaths {
            assets.append(currentAssetAtIndex(indexPath.item))
        }
        
        return assets
    }
    
    override func scrollViewDidScroll(scrollView: UIScrollView) {
        updateCache()
    }
    
    //MARK: - Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        let indexPath = self.collectionView!.indexPathForCell(sender as! UICollectionViewCell)!
        let photoAssetVC = segue.destinationViewController as! PhotoAssetViewController
        photoAssetVC.asset = self.assetsFetchResults![indexPath.item] as! PHAsset
        photoAssetVC.assetsFetchResult = self.assetsFetchResults!
        photoAssetVC.assetCollection = self.assetCollection
        photoAssetVC.index = indexPath.item
    }
    
    //MARK: - PHPhotoLibraryChangeObserver
    
    func photoLibraryDidChange(changeInstance: PHChange) {
        // Call might come on any background queue. Re-dispatch to the main queue to handle it.
        dispatch_async(dispatch_get_main_queue()) {
            
            // check if there are changes to the assets (insertions, deletions, updates)
            let collectionChanges = changeInstance.changeDetailsForFetchResult(self.assetsFetchResults!)
            if collectionChanges != nil {
                
                // get the new fetch result
                self.assetsFetchResults = collectionChanges!.fetchResultAfterChanges
                
                let collectionView = self.collectionView!
                
                if !collectionChanges!.hasIncrementalChanges || collectionChanges!.hasMoves {
                    // we need to reload all if the incremental diffs are not available
                    collectionView.reloadData()
                    
                } else {
                    // if we have incremental diffs, tell the collection view to animate insertions and deletions
                    collectionView.performBatchUpdates({
                        var isDeleting =  false
                        let removedIndexes = collectionChanges!.removedIndexes
                        if (removedIndexes?.count ?? 0) != 0 {
                            collectionView.deleteItemsAtIndexPaths(removedIndexes!.aapl_indexPathsFromIndexesWithSection(0))
                            isDeleting = true
                        }
                        let insertedIndexes = collectionChanges!.insertedIndexes
                        if (insertedIndexes?.count ?? 0) != 0 {
                            collectionView.insertItemsAtIndexPaths(insertedIndexes!.aapl_indexPathsFromIndexesWithSection(0))
                            isDeleting = false
                        }
                        let changedIndexes = collectionChanges!.changedIndexes
                        if (changedIndexes?.count ?? 0) != 0 && isDeleting == false {
                            collectionView.reloadItemsAtIndexPaths(changedIndexes!.aapl_indexPathsFromIndexesWithSection(0))
                            isDeleting = false
                        }
                        }, completion: nil)
                }
                
                self.resetCache()
            }
        }
    }
    
    // MARK: Private Functions
    
    func currentAssetAtIndex(index:NSInteger) -> PHAsset {
        if let fetchResult = assetsFetchResults {
            return fetchResult[index] as! PHAsset
        } else {
            let tmp: PHAsset = PHAsset()
            return tmp
        }
    }
    
}
