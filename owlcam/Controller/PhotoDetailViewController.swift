//
//  PhotoDetailViewController.swift
//  owlcam
//
//  Created by Pil Gwon Kim on 2017. 2. 2..
//  Copyright © 2017년 pilgwon. All rights reserved.
//

import UIKit
import Photos

class PhotoDetailViewController: UIViewController, UIScrollViewDelegate {
    @IBOutlet var photoScrollView: UIScrollView!
    @IBOutlet var photoImageView: UIImageView!
    
    var asset: PHAsset!
    var pageIndex: Int!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // set scrollview
        photoScrollView.delegate = self
        photoScrollView.minimumZoomScale = 1.0
        photoScrollView.maximumZoomScale = 4.0
        photoScrollView.zoomScale = 1.0
        
        // get recent(latest) photo
        PHImageManager.default().requestImage(for: asset, targetSize: self.photoImageView.frame.size, contentMode: .aspectFill, options: nil) { (image, info) in
            self.photoImageView.image = image
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        photoScrollView.zoomScale = 1.0
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.photoImageView
    }
    
    
}
