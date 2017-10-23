//
//  PhotoWrapperViewController.swift
//  owlcam
//
//  Created by Pil Gwon Kim on 2017. 2. 2..
//  Copyright © 2017년 pilgwon. All rights reserved.
//

import UIKit
import Photos

class PhotoWrapperViewController: UIPageViewController, UIPageViewControllerDataSource {
    
    var photos: Array<PHAsset>!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.automaticallyAdjustsScrollViewInsets = false
        self.navigationController?.hidesBarsOnTap = true
        
        self.dataSource = self
        
        self.initDoneBarButton()
        self.loadPhotos()
        
    }
    
    func initDoneBarButton() {
        let doneButton: UIBarButtonItem = UIBarButtonItem(title: "닫기", style: .plain, target: self, action: #selector(dismissVC))
        self.navigationItem.rightBarButtonItem = doneButton
    }
    
    func dismissVC() {
        self.dismiss(animated: true, completion: nil)
    }
    
    func loadPhotos() {
        let photoOptions = PHFetchOptions()
        photoOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        
        if let collection = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumRecentlyAdded, options: nil).firstObject {
            let assets = PHAsset.fetchAssets(in: collection, options: photoOptions)
            photos = []
            assets.enumerateObjects({ (asset, index, stop) in
                self.photos.append(asset)
            })
            
            let viewControllers = [self.viewControllerAtIndex(index: photos.count-1) as PhotoDetailViewController]
            self.setViewControllers(viewControllers, direction: .forward, animated: true, completion: nil)
        }
    }
    
    func viewControllerAtIndex(index: Int) -> PhotoDetailViewController {
        let vc: PhotoDetailViewController = self.storyboard?.instantiateViewController(withIdentifier: "PhotoDetailViewController") as! PhotoDetailViewController
        
        vc.pageIndex = index
        vc.asset = photos[index]
        
        return vc
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        let vc = viewController as! PhotoDetailViewController
        var index = vc.pageIndex as Int
        
        if index == 0 || index == NSNotFound {
            return nil
        }
        
        index -= 1
        
        return self.viewControllerAtIndex(index: index)
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        let vc = viewController as! PhotoDetailViewController
        var index = vc.pageIndex as Int
        
        if index == NSNotFound {
            return nil
        }
        
        index += 1
        
        if index == self.photos.count {
            return nil
        }
        
        return self.viewControllerAtIndex(index: index)
    }
    
    override var prefersStatusBarHidden: Bool {
        return self.navigationController?.isNavigationBarHidden == true
    }
    
    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        return .fade
    }
    
}
