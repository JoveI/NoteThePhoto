//
//  CameraViewController.swift
//  CameraProba6
//
//  Created by Jovan Ivanovski on 8/15/15.
//  Copyright © 2015 Jovan Ivanovski. All rights reserved.
//

import UIKit
import AVFoundation
import CoreGraphics
import ImageIO
import MobileCoreServices
import Photos
import CoreLocation

var SessionRunningAndDeviceAuthorizedContext = "SessionRunningAndDeviceAuthorizedContext"
var CapturingStillImageContext = "CapturingStillImageContext"

//flash photos
let FLASH_OFF: String = "FlashOff.png"
let FLASH_AUTO: String = "FlashAuto.png"
let FLASH_ON: String = "FlashOn.png"


class CameraViewController: UIViewController {
    
    // MARK: - Properties
    
    private var sessionQueue: dispatch_queue_t!
    private var session: AVCaptureSession?
    private var videoDeviceInput: AVCaptureDeviceInput?
    private var stillImageOutput: AVCaptureStillImageOutput?
    private var imageToBeSaved: UIImage!
    private let imageView = UIImageView(frame: CGRectZero)
    
    private var filter: CIFilter!
    
    var meta: [String : AnyObject]!
    var newD: NSData!
    
    var assetCollection: PHAssetCollection!
    var imageAsset: PHAsset!
    
    private var deviceAuthorized: Bool = false
    private var backgroundRecordId: UIBackgroundTaskIdentifier = UIBackgroundTaskInvalid
    private var sessionRunningAndDeviceAuthorized: Bool {
        get {
            return (self.session?.running != nil && self.deviceAuthorized)
        }
    }
    
    private var runtimeErrorHandlingObserver: AnyObject?
    private var lockInterfaceRotation: Bool = false
    
    //flash properties
    private var flash_off: Bool?
    private var flash_auto: Bool?
    private var flash_on: Bool?
    
    @IBOutlet weak var previewView: AVCameraPreviewView!
    @IBOutlet weak var shutterButton: ShutterButton!
    @IBOutlet weak var flashButton: UIButton!
    @IBOutlet weak var switchCameraButton: UIButton!
    
    //Image description
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
    
    var wi: WeatherInfo!
    var getWeather: WeatherDataHelper = WeatherDataHelper()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        let session: AVCaptureSession = AVCaptureSession()
        self.session = session
        self.previewView.session = session
        self.session?.sessionPreset = AVCaptureSessionPresetPhoto
        
        self.checkDeviceAuthorizationStatus()
        
        let sessionQueue: dispatch_queue_t = dispatch_queue_create("session queue", DISPATCH_QUEUE_SERIAL)
        self.sessionQueue = sessionQueue
        
        dispatch_async(sessionQueue) {
            self.backgroundRecordId = UIBackgroundTaskInvalid
            
            let videoDevice: AVCaptureDevice = CameraViewController.deviceWithMediaType(AVMediaTypeVideo, preferringPosition: AVCaptureDevicePosition.Back)
            
            var videoDeviceInput: AVCaptureDeviceInput?
            do {
                videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
            }
            catch let error as NSError {
                print(error)
                videoDeviceInput = nil
                let alert = UIAlertController(title: "Error", message: "\(error)", preferredStyle: UIAlertControllerStyle.Alert)
                let action = UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil)
                alert.addAction(action)
                self.presentViewController(alert, animated: true, completion: nil)
            }
            catch {
                fatalError()
            }
            
            //add the input
            if session.canAddInput(videoDeviceInput) {
                session.addInput(videoDeviceInput)
                self.videoDeviceInput = videoDeviceInput
                
                dispatch_async(dispatch_get_main_queue()) {
                    //check later, orientation!!!
                }
            }
            
            //add the output for the still image
            let stillImageOutput: AVCaptureStillImageOutput = AVCaptureStillImageOutput()
            if session.canAddOutput(stillImageOutput) {
                stillImageOutput.outputSettings = [AVVideoCodecKey: AVVideoCodecJPEG]
                session.addOutput(stillImageOutput)
                
                self.stillImageOutput = stillImageOutput
            }
            
            
            //Set flash mode off
            CameraViewController.setFlashMode(AVCaptureFlashMode.Off, device: videoDevice)
            self.flash_off = true
            self.flash_auto = false
            self.flash_on = false
            
            //Swipe gesture recognizer
            let rightSwipe: UISwipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: "rightSwipeHandler:")
            rightSwipe.direction = .Right
            self.previewView.addGestureRecognizer(rightSwipe)
            
        }
        
        //Location Manager
        self.locationManager = CLLocationManager()
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        self.locationManager.requestWhenInUseAuthorization()
        
        locationManager.startUpdatingLocation()
    }
    
    override func viewWillAppear(animated: Bool) {
        dispatch_async(sessionQueue) {
            
            self.addObserver(self, forKeyPath: "sessionRunningAndDeviceAuthorized", options: [.Old, .New], context: &SessionRunningAndDeviceAuthorizedContext)
            self.addObserver(self, forKeyPath: "capturingStillImage", options:[.Old , .New], context: &CapturingStillImageContext)
            
            NSNotificationCenter.defaultCenter().addObserver(self, selector: "subjectAreaDidChange:", name: AVCaptureDeviceSubjectAreaDidChangeNotification, object: self.videoDeviceInput?.device)
            
            weak var weakSelf = self
            
            self.runtimeErrorHandlingObserver = NSNotificationCenter.defaultCenter().addObserverForName(AVCaptureSessionRuntimeErrorNotification, object: self.session, queue: nil) {
                (note: NSNotification) in
                
                let strongSelf: CameraViewController = weakSelf!
                dispatch_async(strongSelf.sessionQueue) {
                    if let session = strongSelf.session {
                        session.startRunning()
                    }
                }
            }
            
            self.session?.startRunning()
        }
        
    }
    
    override func viewWillDisappear(animated: Bool) {
        dispatch_async(sessionQueue) {
            if let session = self.session {
                session.stopRunning()
                
                NSNotificationCenter.defaultCenter().removeObserver(session, name: AVCaptureDeviceSubjectAreaDidChangeNotification, object: self.videoDeviceInput?.device)
                NSNotificationCenter.defaultCenter().removeObserver(self.runtimeErrorHandlingObserver!)
                
                self.removeObserver(self, forKeyPath: "sessionRunningAndDeviceAuthorized", context: &SessionRunningAndDeviceAuthorizedContext)
                self.removeObserver(self, forKeyPath: "capturingStillImage", context: &CapturingStillImageContext)
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        
        (self.previewView.layer as! AVCaptureVideoPreviewLayer).connection.videoOrientation = AVCaptureVideoOrientation(rawValue: UIDevice.currentDevice().orientation.rawValue)!
        
    }
    
    override func shouldAutorotate() -> Bool {
        return !self.lockInterfaceRotation
        //return false
        //return UIDevice.currentDevice().orientation == UIDeviceOrientation.Portrait
    }
    
    
    //observeValueForKeyPath:ofObject:change:context:
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if context == &CapturingStillImageContext {
            let isCapturingStillImage: Bool = change![NSKeyValueChangeNewKey]!.boolValue
            if isCapturingStillImage {
                self.runStillImageCaptureAnimation()
            }
        }
        else {
            return super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
        }
    }
    
    
    // MARK: - Actions
    
    @IBAction func captureStillImage(sender: ShutterButton) {
        dispatch_async(self.sessionQueue) {
            
            // Update the orientation on the still image output video connection before capturing.
            let videoOrientation = (self.previewView.layer as! AVCaptureVideoPreviewLayer).connection.videoOrientation
            self.stillImageOutput!.connectionWithMediaType(AVMediaTypeVideo).videoOrientation = videoOrientation
            
            
            self.stillImageOutput!.captureStillImageAsynchronouslyFromConnection(self.stillImageOutput!.connectionWithMediaType(AVMediaTypeVideo)) { (imageDataSampleBuffer: CMSampleBuffer!, error: NSError!) in
                
                if error == nil {
                    
                    
                    let data: NSData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(imageDataSampleBuffer)
                    
                    self.imageData = data
                    let imageUI = UIImage(data: data)
                    
                    dispatch_async(dispatch_get_main_queue()) {
                        if self.videoDeviceInput?.device.position == AVCaptureDevicePosition.Back {
                            
                            self.imageToBeSaved = imageUI
                            self.performSegueWithIdentifier("appStillImageSegue", sender: self)
                            
                        }
                        else if self.videoDeviceInput?.device.position == AVCaptureDevicePosition.Front {
                            let mirroredImage = UIImage(CGImage: (imageUI?.CGImage)!, scale: (imageUI?.scale)!, orientation: UIImageOrientation.LeftMirrored)
                            
                            self.imageToBeSaved = mirroredImage
                            self.performSegueWithIdentifier("appStillImageSegue", sender: self)
                            
                        }
                    }
                }
            }
        }
    }
    
    @IBAction func changeFlashMode(sender: UIButton) {
        let device: AVCaptureDevice = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
        
        if flash_off == true && flash_auto == false && flash_on == false {
            flash_off = false
            flash_auto = true
            flash_on = false
            flashButton.setImage(UIImage(named: FLASH_AUTO), forState: UIControlState.Normal)
            CameraViewController.setFlashMode(AVCaptureFlashMode.Auto, device: device)
        }
        else if flash_off == false && flash_auto == true && flash_on == false {
            flash_off = false
            flash_auto = false
            flash_on = true
            flashButton.setImage(UIImage(named: FLASH_ON), forState: UIControlState.Normal)
            CameraViewController.setFlashMode(AVCaptureFlashMode.On, device: device)
        }
        else if flash_off == false && flash_auto == false && flash_on == true {
            flash_off = true
            flash_auto = false
            flash_on = false
            flashButton.setImage(UIImage(named: FLASH_OFF), forState: UIControlState.Normal)
            CameraViewController.setFlashMode(AVCaptureFlashMode.Off, device: device)
        }
        
    }
    
    
    @IBAction func switchCamera(sender: UIButton) {
        
        dispatch_async(self.sessionQueue) {
            
            let currentVideoDevice: AVCaptureDevice = self.videoDeviceInput!.device
            let currentDevicePosition: AVCaptureDevicePosition = currentVideoDevice.position
            var preferredPosition: AVCaptureDevicePosition = AVCaptureDevicePosition.Unspecified
            
            switch currentDevicePosition {
                
            case AVCaptureDevicePosition.Front:
                preferredPosition = AVCaptureDevicePosition.Back
                
            case AVCaptureDevicePosition.Back:
                preferredPosition = AVCaptureDevicePosition.Front
                
            case AVCaptureDevicePosition.Unspecified:
                preferredPosition = AVCaptureDevicePosition.Back
            }
            
            let device: AVCaptureDevice = CameraViewController.deviceWithMediaType(AVMediaTypeVideo, preferringPosition: preferredPosition)
            
            var videoDeviceInput: AVCaptureDeviceInput?
            
            do {
                videoDeviceInput = try AVCaptureDeviceInput(device: device)
            }
            catch let error as NSError {
                print(error)
                videoDeviceInput = nil
                let alert = UIAlertController(title: "Error", message: "\(error)", preferredStyle: UIAlertControllerStyle.Alert)
                let action = UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil)
                alert.addAction(action)
                self.presentViewController(alert, animated: true, completion: nil)
            }
            catch {
                fatalError()
            }
            
            self.session!.beginConfiguration()
            
            self.session!.removeInput(self.videoDeviceInput)
            if self.session!.canAddInput(videoDeviceInput) {
                
                NSNotificationCenter.defaultCenter().removeObserver(self, name: AVCaptureDeviceSubjectAreaDidChangeNotification, object: self.videoDeviceInput?.device)
                
                NSNotificationCenter.defaultCenter().addObserver(self, selector: "subjectAreaDidChange", name: AVCaptureDeviceSubjectAreaDidChangeNotification, object: device)
                
                self.session!.addInput(videoDeviceInput)
                self.videoDeviceInput = videoDeviceInput
            }
            else {
                self.session!.addInput(self.videoDeviceInput)
            }
            
            self.session!.commitConfiguration()
        }
        
    }
    
    
    // focusAndExposeTapGestureRecognizer
    @IBAction func focusTapGestureRecognizer(tapGestureRecognizer: UITapGestureRecognizer) {
                
        let devicePoint: CGPoint = (self.previewView.layer as! AVCaptureVideoPreviewLayer).captureDevicePointOfInterestForPoint(tapGestureRecognizer.locationInView(tapGestureRecognizer.view))
        
        self.focusWithMode(AVCaptureFocusMode.AutoFocus, exposureMode: AVCaptureExposureMode.AutoExpose, point: devicePoint, monitorSubjectAreaChange: true)
    }
    
    
    // MARK: - Selector
    func subjectAreaDidChange(notification: NSNotification) {
        let devicePoint: CGPoint = CGPoint(x: 0.5, y: 0.5)
        self.focusWithMode(AVCaptureFocusMode.ContinuousAutoFocus, exposureMode: AVCaptureExposureMode.ContinuousAutoExposure, point: devicePoint, monitorSubjectAreaChange: false)
    }
    
    func rightSwipeHandler(gesture: UISwipeGestureRecognizer) {
        self.performSegueWithIdentifier("PhotoLibrary", sender: self)
    }
    
    
    // MARK: - Custom Functions
    
    func focusWithMode(focusMode: AVCaptureFocusMode, exposureMode: AVCaptureExposureMode, point: CGPoint,
        monitorSubjectAreaChange: Bool) {
            
            dispatch_async(self.sessionQueue) {
                
                let device: AVCaptureDevice = self.videoDeviceInput!.device
                
                do {
                    
                    try device.lockForConfiguration()
                    
                    if device.focusPointOfInterestSupported && device.isFocusModeSupported(focusMode) {
                        device.focusMode = focusMode
                        device.focusPointOfInterest = point
                    }
                    
                    if device.exposurePointOfInterestSupported && device.isExposureModeSupported(exposureMode) {
                        device.exposureMode = exposureMode
                        device.exposurePointOfInterest = point
                    }
                    
                    device.subjectAreaChangeMonitoringEnabled = monitorSubjectAreaChange
                    
                    device.unlockForConfiguration()
                    
                }
                catch {
                    print("error while setting focus: \(error)")
                }
            }
    }
    
    func checkDeviceAuthorizationStatus() {
        let mediaType = AVMediaTypeVideo
        
        AVCaptureDevice.requestAccessForMediaType(mediaType) { (granted: Bool) in
            if granted {
                self.deviceAuthorized = true
            }
            else {
                dispatch_async(dispatch_get_main_queue()) {
                    let alert: UIAlertController = UIAlertController(title: "NoteThePhoto", message: "NoteThePhoto does not have permission to access the camera", preferredStyle: UIAlertControllerStyle.Alert)
                    
                    let action: UIAlertAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Default) {
                        (action_new: UIAlertAction) in
                        exit(0)
                    }
                    
                    alert.addAction(action)
                    self.presentViewController(alert, animated: true, completion: nil)
                }
                self.deviceAuthorized = false
            }
        }
    }
    
    class func deviceWithMediaType(mediaType: String, preferringPosition: AVCaptureDevicePosition) -> AVCaptureDevice {
        var devices = AVCaptureDevice.devicesWithMediaType(mediaType)
        var captureDevice: AVCaptureDevice = devices[0] as! AVCaptureDevice
        
        for device in devices {
            if device.position == preferringPosition {
                captureDevice = device as! AVCaptureDevice
                break
            }
        }
        
        return captureDevice
    }
    
    func runStillImageCaptureAnimation() {
        dispatch_async(dispatch_get_main_queue()) {
            self.previewView.layer.opacity = 0.0
            UIView.animateWithDuration(0.26,
                animations: {
                    self.previewView.layer.opacity = 1.0
                }
            )
        }
    }
    
    class func setFlashMode(flashMode: AVCaptureFlashMode, device: AVCaptureDevice) {
        if device.hasFlash && device.isFlashModeSupported(flashMode) {
            do {
                try device.lockForConfiguration()
                device.flashMode = flashMode
                device.unlockForConfiguration()
            }
            catch{
                print("flash mode error: \(error)")
            }
        }
    }

    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        
        if segue.identifier == "appStillImageSegue" {
            let appStillImageVC = segue.destinationViewController as! EditPhotoViewController
            appStillImageVC.image = imageToBeSaved
            
            appStillImageVC.wi = wi
            appStillImageVC.data = imageData
            
            appStillImageVC.latitude = latitude
            appStillImageVC.longitude = longitude
            
            appStillImageVC.placemarkCountry = self.placemarkCountry
            appStillImageVC.placemarkCity = self.placemarkCity
            
            if self.dateTime != nil {
                appStillImageVC.dateTime = self.dateTime
            }
            else {
                let dateFormater: NSDateFormatter = NSDateFormatter()
                let today: NSDate = NSDate()
                dateFormater.dateFormat = "dd.MM.yyyy HH:mm:SS"
                let dateTimeTemp = dateFormater.stringFromDate(today)
                appStillImageVC.dateTime = dateTimeTemp
            }
        }
        
    }
    
    
}


/* Get the location where the image was taken */

extension CameraViewController: CLLocationManagerDelegate {
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        let location: CLLocation = locations[locations.count - 1] as CLLocation
        self.location = location
        let locationCoordinate = location.coordinate
        latitude = locationCoordinate.latitude
        longitude = locationCoordinate.longitude
        
        //get the time
        let dateFormater: NSDateFormatter = NSDateFormatter()
        dateFormater.dateStyle = NSDateFormatterStyle.LongStyle
        dateFormater.timeStyle = NSDateFormatterStyle.MediumStyle
        dateTime = "\(dateFormater.stringFromDate(location.timestamp))"
        
        CLGeocoder().reverseGeocodeLocation(location, completionHandler: { (placemarks, error) -> Void in
            if (error != nil) {
                
                print("Reverse geocoding error:" + error!.localizedDescription)
                return
                
            }
            
            if placemarks!.count > 0 {
                
                let pm = placemarks![0] as CLPlacemark
                self.placemarkCountry = "\(pm.country)"
                self.placemarkCity = "\(pm.locality)"
                
                self.locationManager.stopUpdatingLocation()
            }
            else {
                print("Error with data, placemark nil")
            }
        })
        
        let weatherUrlString = "http://api.openweathermap.org/data/2.5/weather?lat=\(latitude)&lon=\(longitude)"
        getWeather.getWeatherData(weatherUrlString) { result in
            if result?.temp != nil {
                self.wi = result
            }
        }
        
    }
    
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        print("Error while updating location " + error.localizedDescription)
    }
    
}

