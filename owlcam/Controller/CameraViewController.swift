//
//  CameraViewController.swift
//  owlcam
//
//  Created by Pil Gwon Kim on 2017. 2. 1..
//  Copyright © 2017년 pilgwon. All rights reserved.
//

import UIKit
import Photos
import AVFoundation
import StoreKit

class CameraViewController: UIViewController {
    @IBOutlet var previewView: UIView!
    @IBOutlet var lightView: UIView!
    @IBOutlet var colorPickerWrapperView: UIView!
    @IBOutlet var colorPickerScrollView: UIScrollView!
    @IBOutlet var lastPhotoView: UIImageView!
    @IBOutlet var currentColorView: UIView!
    @IBOutlet var removeColorButton: UIButton!
    
    var stillImageOutput: AVCaptureStillImageOutput!
    var lastImage: UIImage! = nil
    var isColorPickerButtonShowing: Bool = false
    var addColorView: UIView!
    var currentColorIndex: Int!
    var availColors: Array<UIColor>!
    var isColorEditing: Bool = false
    var colorViews: Array<UIView>! = []
    var totalTakePictureCount: Int = 0
    var reviewAsked: Bool = false
    
    let colorWrapperViewTag: Int = 100
    let colorViewTag: Int = 200
    let colorButtonTag: Int = 300
    let colorRemoveButtonTag: Int = 400
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.initComponents()
        self.loadCurrentColor()
        self.fetchLastPhoto()
    }
    
    func initComponents() {
        // set currentColorView
        self.currentColorView.layer.cornerRadius = self.currentColorView.frame.size.width/2
        self.currentColorView.layer.masksToBounds = true
        self.currentColorView.layer.borderColor = UIColor.lightGray.cgColor
        self.currentColorView.layer.borderWidth = 1.0
        
        // set lastPhotoView
        self.lastPhotoView.layer.cornerRadius = 5
        self.lastPhotoView.layer.masksToBounds = true
        self.lastPhotoView.layer.borderColor = UIColor.lightGray.cgColor
        self.lastPhotoView.layer.borderWidth = 1.0
    }
    
    func loadCurrentColor() {
        self.currentColorIndex = 0
        
        var ac: Array<String>! = defaultColors
        let defaults = UserDefaults.standard
        if let colors = defaults.array(forKey: defaultsKeys.currentColorKey) as? Array<String> {
            if colors.count > 0 {
                // color code to uicolor
                ac = colors
            }
        }
        // set availColors = ac
        availColors = []
        for c in ac {
            let color: UIColor = UIColor.init(hexString: c)
            availColors.append(color)
        }
        
        self.currentColorChanged(color: self.availColors[self.currentColorIndex])
        self.drawAvailColors()
    }
    
    func currentColorChanged(color: UIColor) {
        self.currentColorView.backgroundColor = color
        self.lightView.backgroundColor = color
    }
    
    let colorMargin = 15.0, colorSize = 40.0
    func drawAvailColors() {
        colorViews = []
        
        var left = 15.0
        // draw avail colors
        for (idx, color) in self.availColors.enumerated() {
            let wrapperView: UIView = UIView.init(frame: CGRect(x: left, y: 10, width: colorSize, height: colorSize))
            wrapperView.backgroundColor = UIColor.clear
            wrapperView.tag = colorWrapperViewTag + idx
            colorPickerScrollView.addSubview(wrapperView)
            colorViews.append(wrapperView)
            
            let colorView: UIView = UIView.init(frame: CGRect(x: 0, y: 0, width: colorSize, height: colorSize))
            colorView.backgroundColor = color
            colorView.layer.cornerRadius = colorView.frame.size.width / 2
            colorView.layer.borderColor = UIColor.lightGray.cgColor
            colorView.layer.borderWidth = 1.0
            colorView.layer.masksToBounds = true
            colorView.tag = colorViewTag + idx
            wrapperView.addSubview(colorView)
            
            let colorButton: UIButton = UIButton.init(frame: CGRect(x: 0, y: 0, width: colorSize, height: colorSize))
            colorButton.addTarget(self, action: #selector(colorButtonClicked), for: .touchUpInside)
            colorButton.tag = colorButtonTag + idx
            wrapperView.addSubview(colorButton)
            
            left += colorSize + colorMargin
        }
        
        // draw add-color-button
        addColorView = UIView(frame: CGRect(x: left, y: 10, width: colorSize, height: colorSize))
        colorPickerScrollView.addSubview(addColorView)
        
        let addColorImageView: UIImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: colorSize, height: colorSize))
        addColorImageView.image = #imageLiteral(resourceName: "color_wheel")
        addColorImageView.layer.cornerRadius = addColorImageView.frame.size.width / 2
        addColorImageView.layer.borderColor = UIColor.lightGray.cgColor
        addColorImageView.layer.borderWidth = 1.0
        addColorImageView.layer.masksToBounds = true
        addColorView.addSubview(addColorImageView)
        
        let addColorButton: UIButton = UIButton(frame: CGRect(x: 0, y: 0, width: colorSize, height: colorSize))
        addColorButton.addTarget(self, action: #selector(addColorButtonClicked), for: .touchUpInside)
        addColorView.addSubview(addColorButton)
        
        let w = CGFloat(left + colorSize + colorMargin)
        colorPickerScrollView.contentSize = CGSize(width: w, height: colorPickerScrollView.frame.size.height)
        colorPickerScrollView.contentOffset = CGPoint(x: 0, y: 0)
    }
    
    @IBAction func removeButtonClicked() {
        if self.currentColorIndex >= defaultColors.count {
            self.availColors.remove(at: self.currentColorIndex)
            self.saveColor()
            
            let colorView = self.colorViews[self.currentColorIndex]
            UIView.animate(withDuration: 0.2, animations: {
                colorView.frame.origin.y += self.colorPickerScrollView.frame.size.height
            }, completion: { (b) in
                UIView.animate(withDuration: 0.2, animations: {
                    for idx in self.currentColorIndex+1..<self.colorViews.count {
                        let cv = self.colorViews[idx]
                        cv.frame.origin.x -= CGFloat(self.colorSize + self.colorMargin)
                    }
                    self.addColorView.frame.origin.x -= CGFloat(self.colorSize + self.colorMargin)
                }, completion: { (b) in
                    self.colorViews.remove(at: self.currentColorIndex)
                    colorView.removeFromSuperview()
                    
                    if self.currentColorIndex >= self.availColors.count {
                        self.currentColorIndex = self.availColors.count - 1
                    }
                    if self.currentColorIndex >= defaultColors.count {
                        self.removeColorButton.isHidden = false
                    } else {
                        self.removeColorButton.isHidden = true
                    }
                    self.currentColorChanged(color: self.availColors[self.currentColorIndex])
                })
            })
        }
    }
    
    func colorButtonClicked(button: UIButton) {
        self.currentColorIndex = button.tag - colorButtonTag
        self.currentColorChanged(color: self.availColors[self.currentColorIndex])
        if self.currentColorIndex >= defaultColors.count {
            self.removeColorButton.isHidden = false
        } else {
            self.removeColorButton.isHidden = true
        }
    }
    
    func saveColor() {
        var ac: Array<String>! = []
        let defaults = UserDefaults.standard
        for c in self.availColors {
            ac.append(c.hexString())
        }
        defaults.setValue(ac, forKey: defaultsKeys.currentColorKey)
        defaults.synchronize()
    }
    
    func addColorButtonClicked() {
        // make random color
        let color = UIColor.randomColor()
        availColors.append(color)
        self.saveColor()
        
        // add new color picker view
        let wrapperView: UIView = UIView.init(frame: CGRect(x: Double(addColorView.frame.origin.x), y: 10.0 + Double(self.colorPickerScrollView.frame.size.height), width: colorSize, height: colorSize))
        wrapperView.backgroundColor = UIColor.clear
        wrapperView.tag = colorWrapperViewTag + availColors.count - 1
        colorPickerScrollView.addSubview(wrapperView)
        colorViews.append(wrapperView)
        
        let colorView: UIView = UIView.init(frame: CGRect(x: 0, y: 0, width: colorSize, height: colorSize))
        colorView.backgroundColor = color
        colorView.layer.cornerRadius = colorView.frame.size.width / 2
        colorView.layer.borderColor = UIColor.lightGray.cgColor
        colorView.layer.borderWidth = 1.0
        colorView.layer.masksToBounds = true
        colorView.tag = colorViewTag + availColors.count - 1
        wrapperView.addSubview(colorView)
        
        let colorButton: UIButton = UIButton.init(frame: CGRect(x: 0, y: 0, width: colorSize, height: colorSize))
        colorButton.addTarget(self, action: #selector(colorButtonClicked), for: .touchUpInside)
        colorButton.tag = colorButtonTag + availColors.count - 1
        wrapperView.addSubview(colorButton)
        
        // animate
        UIView.animate(withDuration: 0.3) {
            self.addColorView.frame.origin.x += CGFloat(self.colorSize) + CGFloat(self.colorMargin)
            let width = Double(self.addColorView.frame.origin.x) + self.colorSize + self.colorMargin
            self.colorPickerScrollView.contentSize = CGSize(width: CGFloat(width), height: self.colorPickerScrollView.frame.size.height)
            let offset = CGFloat(width) - self.colorPickerScrollView.frame.size.width > 0 ? CGFloat(width) - self.colorPickerScrollView.frame.size.width : 0
            self.colorPickerScrollView.contentOffset = CGPoint(x: offset, y: 0)
            wrapperView.frame.origin.y = 10
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let session: AVCaptureSession = AVCaptureSession()
        session.sessionPreset = AVCaptureSessionPresetPhoto
        
        let devices = AVCaptureDevice.devices().filter{ ($0 as AnyObject).hasMediaType(AVMediaTypeVideo) && ($0 as AnyObject).position == AVCaptureDevicePosition.front }
        if let captureDevice = devices.first as? AVCaptureDevice {
            do {
                try session.addInput(AVCaptureDeviceInput(device: captureDevice))
            } catch {
                print("ERROR: \(error)")
            }
            session.sessionPreset = AVCaptureSessionPresetPhoto
            session.startRunning()
            
            self.stillImageOutput = AVCaptureStillImageOutput()
            self.stillImageOutput.outputSettings = [AVVideoCodecKey:AVVideoCodecJPEG]
            if session.canAddOutput(self.stillImageOutput) {
                session.addOutput(self.stillImageOutput)
            }
            
            if let previewLayer = AVCaptureVideoPreviewLayer(session: session) {
                previewLayer.bounds = view.bounds
                previewLayer.position = CGPoint(x: view.bounds.midX, y: view.bounds.midY)
                previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
                let cameraPreview = UIView(frame: CGRect(x: 0.0, y: 0.0, width: view.bounds.size.width, height: view.bounds.size.height))
                cameraPreview.layer.addSublayer(previewLayer)
                self.previewView.addSubview(cameraPreview)
            }
        }
    }
    
    func fetchLastPhoto() {
        let imageManager = PHImageManager.default()
        
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        
        if let collection = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumRecentlyAdded, options: nil).firstObject {
            let assets = PHAsset.fetchAssets(in: collection, options: fetchOptions)
            if assets.count > 0 {
                imageManager.requestImage(for: assets.lastObject!, targetSize: self.lastPhotoView.frame.size, contentMode: .aspectFill, options: nil, resultHandler: { (image, _) in
                    self.updateLastImage(img: image!)
                })
            }
        }
    }
    
    func updateLastImage(img: UIImage) {
        self.lastImage = img
        self.lastPhotoView.image = img
    }
    
    @IBAction func showLightView() {
        self.lightView.alpha = 1
    }
    
    @IBAction func hideLightView() {
        UIView.animate(withDuration: 0.3) {
            self.lightView.alpha = 0
        }
    }
    
    @IBAction func saveToCamera() {
        if let videoConnection = stillImageOutput.connection(withMediaType: AVMediaTypeVideo) {
            stillImageOutput.captureStillImageAsynchronously(from: videoConnection, completionHandler: { (samplerBuffer, err) in
                let imageDataJpeg = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(samplerBuffer)
                let pickedImage: UIImage = UIImage(data: imageDataJpeg!)!
                self.updateLastImage(img: pickedImage)
                UIImageWriteToSavedPhotosAlbum(pickedImage, self, #selector(self.imageSaved), nil)
                self.hideLightView()
                self.fetchLastPhoto()
                
                self.totalTakePictureCount += 1
                if self.totalTakePictureCount > 3 {
                    if #available(iOS 10.3, *) {
                        self.askReview()
                    }
                }
            })
        }
    }
    
    @available(iOS 10.3, *)
    func askReview() {
        if reviewAsked == false {
            reviewAsked = true
            
            let ver = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String
            if UserDefaults.standard.object(forKey: ver) != nil {
                return
            }
            
            SKStoreReviewController.requestReview()
            UserDefaults.standard.set("Y", forKey: ver)
        }
    }
    
    @objc func imageSaved(image: UIImage, error: NSError, ctx: Any) {
        self.fetchLastPhoto()
    }
    
    @IBAction func colorPickerButtonClicked() {
        if isColorPickerButtonShowing {
            isColorPickerButtonShowing = false
            UIView.animate(withDuration: 0.3, animations: {
                self.colorPickerWrapperView.frame.origin.y = self.view.frame.size.height - 80
                self.colorPickerWrapperView.alpha = 0
                self.removeColorButton.frame.origin.y = self.view.frame.size.height - 80 - self.colorPickerWrapperView.frame.size.height
                self.removeColorButton.isHidden = true
                self.hideLightView()
            })
        } else {
            isColorPickerButtonShowing = true
            UIView.animate(withDuration: 0.3, animations: {
                self.colorPickerWrapperView.frame.origin.y = self.view.frame.size.height - 80 - self.colorPickerWrapperView.frame.size.height
                self.colorPickerWrapperView.alpha = 1
                self.removeColorButton.frame.origin.y = self.view.frame.size.height - 80 - self.colorPickerWrapperView.frame.size.height - self.removeColorButton.frame.size.height
                if self.currentColorIndex >= defaultColors.count {
                    self.removeColorButton.isHidden = false
                } else {
                    self.removeColorButton.isHidden = true
                }
                self.lightView.alpha = 1
            })
        }
    }
    
    @IBAction func openPhotoLibraryButtonClicked() {
        let vc: PhotoWrapperViewController = self.storyboard?.instantiateViewController(withIdentifier: "PhotoWrapperViewController") as! PhotoWrapperViewController
        let navController = UINavigationController(rootViewController: vc)
        self.present(navController, animated: true, completion: nil)
    }
}
