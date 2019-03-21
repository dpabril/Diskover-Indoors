//
//  NavigationController.swift
//  CS199 INS
//
//  Created by Abril & Aquino on 11/12/2018.
//  Copyright © 2018 Abril & Aquino. All rights reserved.
//

import UIKit
import SceneKit
import CoreMotion
import CoreLocation
import AVFoundation
import GRDB

class NavigationController: UIViewController, CLLocationManagerDelegate, AVCaptureMetadataOutputObjectsDelegate {
    
    // Variables for main navigation scene
    @IBOutlet weak var navigationView: SCNView!
    //@IBOutlet weak var altLabel: UILabel!
    //@IBOutlet weak var levelLabel: UILabel!
    //@IBOutlet weak var reachedDestLabel: UILabel!
    //@IBOutlet weak var averageVLabel: UILabel!
    //@IBOutlet weak var maxAveLabel: UILabel!
    //@IBOutlet weak var destTitleLabel: UILabel!
    @IBOutlet weak var recalibrateButton: UIButton!
    
    // Variables for use with recalibration
    @IBOutlet weak var recalibrationView: UIView!
    @IBOutlet weak var recalibrationFrame: UIImageView!
    var recalibrationFrameBox : UIView?
    var recalibrationFrameThreshold : CGSize?
    var captureSession : AVCaptureSession = AVCaptureSession()
    var videoPreviewLayer : AVCaptureVideoPreviewLayer?
    
    // Gesture recognizers
    @IBOutlet var panGestureRecognizer: UIPanGestureRecognizer!
    @IBOutlet var pinchGestureRecognizer: UIPinchGestureRecognizer!
    @IBOutlet var rotateGestureRecognizer: UIRotationGestureRecognizer!
    
    // Sensor object variables + Accelerometer noise|spike filter
    lazy var compassManager = CLLocationManager()
    lazy var altimeter = CMAltimeter()
    lazy var deviceMotionManager = CMMotionManager()
    lazy var filter = MirrorFilter(rate: 60.0, cutoff: 3.0, adaptive: false)
    
    // Variables needed to detect if user haved arrived to destination
    var pinX : Float = 0
    var pinY : Float = 0
    var shownArrived : Bool = false
    var shownVicinity : Bool = false
    
    // Acceleration and velocity variables
    var accelXs : [Double] = [0, 0, 0, 0]
    var accelYs : [Double] = [0, 0, 0, 0]
    var accelZs : [Double] = [0, 0, 0, 0]
    var prevVx : Double = 0
    var prevVy : Double = 0
    var prevVz : Double = 0
    var accelCount : Int = 0
    var xAccelZeroCount : Int = 0
    var yAccelZeroCount : Int = 0
    var zAccelZeroCount : Int = 0
    
    // Variables needed to calculate average velocity
    //var averageV : Double = 0
    //var count : Int = 1
    //var maxAve : Double = 0
    var pos : Double = 0
    
    // Scene variables
    var scene = SCNScene(named: "SceneObjects.scnassets/NavigationScene.scn")!
    var cameraLockedOnUser = false // change to cameraMovesWithUser
    var cameraTurnsWithUser = false
    var recalibrationViewIsDisplayed = false
    
    /*
     ====================================================================================================
     ~ CONTROLLER FUNCTIONS ~
     ====================================================================================================
     */
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        navigationView.scene = self.scene
        navigationView.pointOfView = self.scene.rootNode.childNode(withName: "sceneCamera", recursively: true)!
        
        self.recalibrationView.isHidden = true
        self.recalibrationView.isOpaque = false
        self.recalibrationView.alpha = 0.0
        self.view.sendSubviewToBack(self.recalibrationView)
        
        // Configuring the QR code scanner
        // > Get the back-facing camera for capturing videos
        var deviceDiscoverySession : AVCaptureDevice.DiscoverySession
        
        if (AVCaptureDevice.default(AVCaptureDevice.DeviceType.builtInDualCamera, for: AVMediaType.video, position: AVCaptureDevice.Position.back) != nil) {
            deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInDualCamera], mediaType: AVMediaType.video, position: .back)
        } else {
            deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: AVMediaType.video, position: .back)
        }
        
        guard let captureDevice = deviceDiscoverySession.devices.first else {
            print("ERROR: No compatible camera device found.")
            return
        }
        
        do {
            // Get an instance of the AVCaptureDeviceInput class using the previous device object.
            let input = try AVCaptureDeviceInput(device: captureDevice)
            // Set the input device on the capture session.
            captureSession.addInput(input)
            
            let captureMetadataOutput = AVCaptureMetadataOutput()
            captureSession.addOutput(captureMetadataOutput)
            
            captureMetadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            captureMetadataOutput.metadataObjectTypes = [AVMetadataObject.ObjectType.qr]
            
        } catch {
            print(error)
            return
        }
        
        // Initialize the video preview layer and add it as a sublayer to the viewPreview view's layer.
        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        videoPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        videoPreviewLayer?.frame = recalibrationView.layer.bounds
        recalibrationView.layer.addSublayer(videoPreviewLayer!)
        
        // Start video capture.
        // captureSession.startRunning()
        
        // Move the message label and top bar to the front
        self.recalibrationView.bringSubviewToFront(self.recalibrationFrame)
        self.view.bringSubviewToFront(self.recalibrationView)
        
        // Initialize QR Code Frame to highlight the QR code
        recalibrationFrameBox = UIView()
        // Initialize QR code frame size threshold for reference to enforce min. distance
        recalibrationFrameThreshold = CGSize.init(width: 100.0, height: 100.0)
        
        if let recalibrationFrameBox = recalibrationFrameBox {
            recalibrationFrameBox.layer.borderColor = UIColor.cyan.cgColor
            recalibrationFrameBox.layer.borderWidth = 2
            self.recalibrationView.addSubview(recalibrationFrameBox)
            self.recalibrationView.bringSubviewToFront(recalibrationFrameBox)
        }
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let sceneFloor = self.scene.rootNode.childNode(withName: "Floor", recursively: true)!
        sceneFloor.geometry?.firstMaterial?.diffuse.contents = AppState.getBuildingCurrentFloor().floorImage
        
        // Configuring user position
        let userMarker = self.scene.rootNode.childNode(withName: "UserMarker", recursively: true)!
        let userCoords = AppState.getNavSceneUserCoords()
        userMarker.position = SCNVector3(userCoords.x, userCoords.y, -1.6817374)
        
        // Configuring location marker position
        let pinMarker = self.scene.rootNode.childNode(withName: "LocationPinMarker", recursively: true)!
        let destCoords = AppState.getNavSceneDestCoords()
        self.shownVicinity = false
        self.shownArrived = false
        pinMarker.position = SCNVector3(destCoords.x, destCoords.y, -1.6817374)
        
        // Configuring user's / stairs marker's position
        if (AppState.isUserOnDestinationLevel()) {
            self.showPinMarker()
            self.hideStaircaseMarker()
            pinMarker.position = SCNVector3(destCoords.x, destCoords.y, -1.6817374)
            self.pinX = pinMarker.position.x
            self.pinY = pinMarker.position.y
        } else {
            let staircaseMarker = self.scene.rootNode.childNode(withName: "StaircaseMarker", recursively: true)!
            let staircaseMarkerPoint = AppState.getNearestStaircase()
            staircaseMarker.position = SCNVector3(staircaseMarkerPoint.xcoord, staircaseMarkerPoint.ycoord, -1.6817374)
            self.hidePinMarker()
            self.showStaircaseMarker()
        }
        
        self.centerCameraOnUser()
        self.panCamToTargetAndBack()
        // Start sensors after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.startSensors()
            self.enableGestureRecognizers()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.stopSensors()
        self.disableGestureRecognizers()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    /*
     ====================================================================================================
     ~ SENSORS MANAGEMENT ~
     ====================================================================================================
     */
    // Magnetometer functions
    func startCompass() {
        if CLLocationManager.headingAvailable() {
            print("Compass is now active.")
            self.compassManager.headingFilter = 0.2
            self.compassManager.delegate = self
            self.compassManager.startUpdatingHeading()
        }
    }
    func locationManagerShouldDisplayHeadingCalibration(_ manager: CLLocationManager) -> Bool {
        return true
    }
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        let userMarker = self.scene.rootNode.childNode(withName: "UserMarker", recursively: true)!
        userMarker.eulerAngles.z = -Utilities.degToRad(90 + newHeading.magneticHeading)

        if (self.cameraLockedOnUser) {
            let camera = self.navigationView.pointOfView!
            camera.eulerAngles.z = userMarker.eulerAngles.z
            print(Utilities.radToDeg(Double(camera.eulerAngles.z)))
        }
    }
    func stopCompass() {
        if CLLocationManager.headingAvailable() {
            self.compassManager.stopUpdatingHeading()
        }
    }
    
    // Altimeter functions
    func startAltimeter() {
        if (CMAltimeter.isRelativeAltitudeAvailable()) {
            print("Altimeter is now active.")
            self.altimeter.startRelativeAltitudeUpdates(to: OperationQueue.main, withHandler: { (altitudeData:CMAltitudeData?, error:Error?) in
                
                let altitude = altitudeData!.relativeAltitude.floatValue
                
                //var level = 0
                
                if (error != nil) {
                    self.stopAltimeter()
                } else {
                    
                    //self.altLabel.text = String(format: "Rel. alt.: %.02f", altitude)
                    
                    // Set information on current floor upon significant change in altitude
                    if (Double(altitude) >= AppState.getBuilding().delta) {
                        if (AppState.getBuildingCurrentFloor().floorLevel < AppState.getBuilding().floors) {
                            AppState.setBuildingCurrentFloor(AppState.getBuildingCurrentFloor().floorLevel + 1)
                            
                            let sceneFloor = self.scene.rootNode.childNode(withName: "Floor", recursively: true)!
                            sceneFloor.geometry?.firstMaterial?.diffuse.contents = AppState.getBuildingCurrentFloor().floorImage
                            
                            self.resetAltimeter()
                        }
                    } else if (Double(altitude) <= -AppState.getBuilding().delta) {
                        if (AppState.getBuildingCurrentFloor().floorLevel > 0) {
                            AppState.setBuildingCurrentFloor(AppState.getBuildingCurrentFloor().floorLevel - 1)
                            
                            let sceneFloor = self.scene.rootNode.childNode(withName: "Floor", recursively: true)!
                            sceneFloor.geometry?.firstMaterial?.diffuse.contents = AppState.getBuildingCurrentFloor().floorImage
                            
                            self.resetAltimeter()
                        }
                    }
                }
                //level = Int(altitude / 2.0)
                //self.levelLabel.text = String(format: "Level: %d", level)
                //self.destTitleLabel.text = "You are currently on the \(Utilities.ordinalize(AppState.getBuildingCurrentFloor().floorLevel)) floor. \(AppState.getDestinationTitle().title)  (\(AppState.getDestinationSubtitle().subtitle)) is on the \(Utilities.ordinalize(AppState.getDestinationLevel().level)) floor."
            })
        }
    }
    func stopAltimeter() {
        if (CMAltimeter.isRelativeAltitudeAvailable()) {
            self.altimeter.stopRelativeAltitudeUpdates()
        }
    }
    func resetAltimeter() {
        self.stopAltimeter()
        self.startAltimeter()
        
        if (AppState.isUserOnDestinationLevel()) {
            self.panCamToTargetAndBack()
            let pinMarker = self.scene.rootNode.childNode(withName: "LocationPinMarker", recursively: true)!
            let destCoords = AppState.getNavSceneDestCoords()
            self.shownVicinity = false
            self.shownArrived = false
            pinMarker.position = SCNVector3(destCoords.x, destCoords.y, -1.6817374)
            self.pinX = pinMarker.position.x
            self.pinY = pinMarker.position.y
            self.hideStaircaseMarker()
            self.showPinMarker()
        } else {
            let staircaseMarker = self.scene.rootNode.childNode(withName: "StaircaseMarker", recursively: true)!
            let staircaseMarkerPoint = AppState.getNearestStaircase()
            staircaseMarker.position = SCNVector3(staircaseMarkerPoint.xcoord, staircaseMarkerPoint.ycoord, -1.6817374)
            self.hidePinMarker()
            self.showStaircaseMarker()
        }
    }
    
    // Device Motion Manager functions
    func startDeviceMotionManager () {
        if (self.deviceMotionManager.isDeviceMotionAvailable) {
            print("Accelerometer and gyroscope are now active.")
            self.deviceMotionManager.accelerometerUpdateInterval = 1.0 / 60.0
            self.deviceMotionManager.startDeviceMotionUpdates(to: OperationQueue.main, withHandler: { (deviceMotionData:CMDeviceMotion?, error:Error?)  in
                let accVec = deviceMotionData!.userAcceleration
                let rotMat = deviceMotionData!.attitude.rotationMatrix
                let correctedAccX = accVec.x * rotMat.m11 + accVec.x * rotMat.m12 + accVec.x * rotMat.m13
                let correctedAccY = accVec.y * rotMat.m21 + accVec.y * rotMat.m22 + accVec.x * rotMat.m23
                let correctedAccZ = accVec.z * rotMat.m31 + accVec.z * rotMat.m32 + accVec.z * rotMat.m33
                var correctedAcc = CMAcceleration.init(x: correctedAccX, y: correctedAccY, z: correctedAccZ)
                
                self.filter.addAcceleration(correctedAcc)
                
                correctedAcc.x = (fabs(self.filter.xAccel) < 0.03) ? 0 : self.filter.xAccel
                correctedAcc.y = (fabs(self.filter.yAccel) < 0.03) ? 0 : self.filter.yAccel
                correctedAcc.z = (fabs(self.filter.zAccel) < 0.03) ? 0 : self.filter.zAccel
                
                // Index for acceleration values array
                self.accelCount = (self.accelCount + 1) % 4
                
                self.accelXs[self.accelCount] = correctedAcc.x
                self.accelYs[self.accelCount] = correctedAcc.y
                self.accelZs[self.accelCount] = correctedAcc.z
                
                if (self.accelCount == 3) {
                    self.prevVx += (4.0 / 8.0) * (1.0 / 60.0) * (self.accelXs[0] + 3 * self.accelXs[1] + 3 * self.accelXs[2] + self.accelXs[3])
                    self.prevVy += (4.0 / 8.0) * (1.0 / 60.0) * (self.accelYs[0] + 3 * self.accelYs[1] + 3 * self.accelYs[2] + self.accelYs[3])
                    self.prevVz += (4.0 / 8.0) * (1.0 / 60.0) * (self.accelZs[0] + 3 * self.accelZs[1] + 3 * self.accelZs[2] + self.accelZs[3])
                }
                
                
                // Synthetic forces to remove velocity once relatively stationary
                if (correctedAcc.x == 0) {
                    self.xAccelZeroCount += 1
                }
                if (correctedAcc.y == 0) {
                    self.yAccelZeroCount += 1
                }
                if (correctedAcc.z == 0) {
                    self.zAccelZeroCount += 1
                }
                if (self.xAccelZeroCount == 20 || self.yAccelZeroCount == 20 || self.zAccelZeroCount == 20) {
                    self.prevVx = 0
                    self.prevVy = 0
                    self.prevVz = 0
                    self.xAccelZeroCount = 0
                    self.yAccelZeroCount = 0
                    self.zAccelZeroCount = 0
                }
                
                if ((self.prevVy > 0.012) || (self.prevVx > 0.012)) {
                    // Calculates velocity
                    let vx = self.prevVx, vy = self.prevVy, vz = self.prevVz;
                    let lastV = sqrt(vx * vx + vy * vy + vz * vz);
                    self.pos = (lastV * (1.0/6.0)) / 10.0
                    if (self.pos >= 0.00063){
                        self.pos = 0.00063
                    }
                    //print(self.pos)
                    //self.averageV = ( self.averageV + lastV ) / Double(self.count)
                    //if (self.averageV > self.maxAve) {
                    //    self.maxAve = self.averageV
                    //}
                    //self.count += 1
                    
                    //self.averageVLabel.text = String(format: "Ave V.: %.05f", self.averageV)
                    //self.maxAveLabel.text = String(format: "Max Ave.: %.05f", self.maxAve)
                    
                    let user = self.scene.rootNode.childNode(withName: "UserMarker", recursively: true)!
                    let camera = self.navigationView.pointOfView!
                    //user.simdPosition += user.simdWorldFront * 0.0004998
                    user.simdPosition += user.simdWorldFront * (Float(self.pos))
                    camera.position = SCNVector3(user.position.x, user.position.y, camera.position.z)
                    AppState.setNavSceneUserCoords(Double(user.position.x), Double(user.position.y))
                    // <+ motion incorporating current velocity >
                    if (self.haveArrived(userX: user.position.x, userY: user.position.y) && self.shownArrived == false) {
                        //self.reachedDestLabel.text = "Reached Destination: TRUE"
                        let message = "\(AppState.getDestinationTitle().title)\n(\(AppState.getDestinationSubtitle().subtitle))"
                        let alertPrompt = UIAlertController(title: "You have arrived.", message: message, preferredStyle: .alert)
                        
                        let imageView = UIImageView(frame: CGRect(x: 25, y: 90, width: 250, height: 333))
                        let roomName = "\(AppState.getBuilding().alias)-\(AppState.getDestinationLevel().level)-\(AppState.getDestinationTitle().title)"
                        imageView.image = UIImage(named: roomName)
                        alertPrompt.view.addSubview(imageView)
                        
                        let height = NSLayoutConstraint(item: alertPrompt.view, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 473)
                        alertPrompt.view.addConstraint(height)
                        
                        let width = NSLayoutConstraint(item: alertPrompt.view, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 302)
                        alertPrompt.view.addConstraint(width)
                        
                        let cancelAction = UIAlertAction(title: "Continue", style: UIAlertAction.Style.cancel, handler: nil)
                        alertPrompt.addAction(cancelAction)
                        
                        self.present(alertPrompt, animated: true, completion: nil)
                        self.shownArrived = true
                    }
                    if (self.inVicinity(userX: user.position.x, userY: user.position.y) && self.shownVicinity == false) {
                        //self.reachedDestLabel.text = "Reached Destination: FALSE"
                        let message = "\(AppState.getDestinationTitle().title)\n(\(AppState.getDestinationSubtitle().subtitle)) is near."
                        let alertPrompt = UIAlertController(title: "You are in the vicinity.", message: message, preferredStyle: .alert)
                        
                        let imageView = UIImageView(frame: CGRect(x: 25, y: 90, width: 250, height: 333))
                        let roomName = "\(AppState.getBuilding().alias)-\(AppState.getDestinationLevel().level)-\(AppState.getDestinationTitle().title)"
                        imageView.image = UIImage(named: roomName)
                        alertPrompt.view.addSubview(imageView)
                        
                        let height = NSLayoutConstraint(item: alertPrompt.view, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 473)
                        alertPrompt.view.addConstraint(height)
                        
                        let width = NSLayoutConstraint(item: alertPrompt.view, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 302)
                        alertPrompt.view.addConstraint(width)
                        
                        let cancelAction = UIAlertAction(title: "Continue", style: UIAlertAction.Style.cancel, handler: nil)
                        alertPrompt.addAction(cancelAction)
                        
                        self.present(alertPrompt, animated: true, completion: nil)
                        self.shownVicinity = true
                    }
                }
            }
            )
        }
    }
    func stopDeviceMotionManager () {
        if (self.deviceMotionManager.isDeviceMotionAvailable) {
            self.deviceMotionManager.stopDeviceMotionUpdates()
        }
    }
    
    // Function to call sensors' start functions
    func startSensors () {
        self.startCompass()
        self.startAltimeter()
        self.startDeviceMotionManager()
    }
    // Function to call sensors' stop functions
    func stopSensors () {
        self.stopCompass()
        self.stopAltimeter()
        self.stopDeviceMotionManager()
    }
    
    /*
     ====================================================================================================
     ~ SCENE MANIPULATION ~
     ====================================================================================================
     */
    @IBAction func onShowDestinationPress(_ sender: UIButton) {
        // Stop sensors to prepare animation
        self.stopSensors()
        self.panCamToTargetAndBack()
        // Start sensors after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.startSensors()
        }
    }
    @IBAction func onLockCameraPress(_ sender: UIButton) {
        if (!self.cameraLockedOnUser) {
            self.cameraLockedOnUser = true
            sender.setTitle("Unlock Camera", for: UIControl.State.normal)
            let camera = self.navigationView.pointOfView!
            let userMarker = self.scene.rootNode.childNode(withName: "UserMarker", recursively: true)!
            camera.eulerAngles.z = userMarker.eulerAngles.z
        } else {
            self.cameraLockedOnUser = false
            sender.setTitle("Lock Camera", for: UIControl.State.normal)
            let camera = self.navigationView.pointOfView!
            camera.eulerAngles.z = 0.0
        }
    }
    
    func panCameraToUser() {
        let camera = navigationView.pointOfView!
        let userMarker = self.scene.rootNode.childNode(withName: "UserMarker", recursively: true)!
        let cameraPanAnimation = CABasicAnimation(keyPath: "position")
        cameraPanAnimation.fromValue = camera.position
        cameraPanAnimation.toValue = SCNVector3(userMarker.position.x, userMarker.position.y, camera.position.z)
        cameraPanAnimation.duration = 1.00
        cameraPanAnimation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        // cameraPanAnimation.removedOnCompletion = NO
        camera.addAnimation(cameraPanAnimation, forKey: nil)
        camera.position = SCNVector3(userMarker.position.x, userMarker.position.y, camera.position.z)
        // camera.removeAllAnimations()
    }
    
    func centerCameraOnUser() {
        let camera = navigationView.pointOfView!
        let userMarker = self.scene.rootNode.childNode(withName: "UserMarker", recursively: true)!
        camera.position = SCNVector3(userMarker.position.x, userMarker.position.y, camera.position.z)
    }
    
    func panCamToTargetAndBack() {
        let camera = navigationView.pointOfView!
        let userMarker = self.scene.rootNode.childNode(withName: "UserMarker", recursively: true)!
        let targetMarker : SCNNode!
        
        if (AppState.isUserOnDestinationLevel()) {
            targetMarker = self.scene.rootNode.childNode(withName: "LocationPinMarker", recursively: true)!
        } else {
            targetMarker = self.scene.rootNode.childNode(withName: "StaircaseMarker", recursively: true)!
        }
        
        let panFromCamToTarget = CABasicAnimation(keyPath: "position")
        panFromCamToTarget.fromValue = camera.position
        panFromCamToTarget.toValue = SCNVector3(targetMarker.position.x, targetMarker.position.y, camera.position.z)
        panFromCamToTarget.duration = 1.00
        panFromCamToTarget.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        panFromCamToTarget.beginTime = 0.00
        panFromCamToTarget.fillMode = .forwards
        
        let panFromTargetToUser = CABasicAnimation(keyPath: "position")
        panFromTargetToUser.fromValue = SCNVector3(targetMarker.position.x, targetMarker.position.y, camera.position.z)
        panFromTargetToUser.toValue = SCNVector3(userMarker.position.x, userMarker.position.y, camera.position.z)
        panFromTargetToUser.duration = 1.00
        panFromTargetToUser.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        panFromTargetToUser.beginTime = 2.00
        
        let panAnimations = CAAnimationGroup()
        panAnimations.animations = [panFromCamToTarget, panFromTargetToUser]
        panAnimations.duration = 3.00
        
        camera.addAnimation(panAnimations, forKey: nil)
        camera.position = SCNVector3(userMarker.position.x, userMarker.position.y, camera.position.z)
        
        // Shows user and destination message bubbles
        self.showBubble()
    }
    // Render the floor plan
    func renderNavScene() {
        let sceneFloor = self.scene.rootNode.childNode(withName: "Floor", recursively: true)!
        sceneFloor.geometry?.firstMaterial?.diffuse.contents = AppState.getBuildingCurrentFloor().floorImage
        
        // Configuring user position
        let userMarker = self.scene.rootNode.childNode(withName: "UserMarker", recursively: true)!
        let userCoords = AppState.getNavSceneUserCoords()
        userMarker.position = SCNVector3(userCoords.x, userCoords.y, -1.6817374)
        
        // Configuring location marker position
        let pinMarker = self.scene.rootNode.childNode(withName: "LocationPinMarker", recursively: true)!
        let destCoords = AppState.getNavSceneDestCoords()
        self.shownVicinity = false
        self.shownArrived = false
        pinMarker.position = SCNVector3(destCoords.x, destCoords.y, -1.6817374)
        
        // Configuring user's / stairs marker's position
        if (AppState.isUserOnDestinationLevel()) {
            self.showPinMarker()
            self.hideStaircaseMarker()
            // pinMarker.position = SCNVector3(destCoords.x, destCoords.y, -1.6817374)
            self.pinX = pinMarker.position.x
            self.pinY = pinMarker.position.y
        } else {
            let staircaseMarker = self.scene.rootNode.childNode(withName: "StaircaseMarker", recursively: true)!
            let staircaseMarkerPoint = AppState.getNearestStaircase()
            staircaseMarker.position = SCNVector3(staircaseMarkerPoint.xcoord, staircaseMarkerPoint.ycoord, -1.6817374)
            self.hidePinMarker()
            self.showStaircaseMarker()
        }
        self.panCamToTargetAndBack()
        
    }
    // Show the destination pin marker
    func showPinMarker () {
        let pinMarker = self.scene.rootNode.childNode(withName: "LocationPinMarker", recursively: true)!
        pinMarker.isHidden = false
    }
    // Hide the desintation pin marker
    func hidePinMarker () {
        let pinMarker = self.scene.rootNode.childNode(withName: "LocationPinMarker", recursively: true)!
        pinMarker.isHidden = true
    }
    // Show the staircase marker
    func showStaircaseMarker () {
        let staircaseMarker = self.scene.rootNode.childNode(withName: "StaircaseMarker", recursively: true)!
        staircaseMarker.isHidden = false
    }
    // Hide the staircase marker
    func hideStaircaseMarker () {
        let staircaseMarker = self.scene.rootNode.childNode(withName: "StaircaseMarker", recursively: true)!
        staircaseMarker.isHidden = true
    }
    // Show user and pin bubble
    func showBubble () {
        let show = SCNAction.fadeIn(duration: 0)
        
        let userMessageBubble = SCNNode()
        let destMessageBubble = SCNNode()
        
        // User message bubble text
        let userMessageNode = SCNNode()
        let userMessageGeometry = SCNText(string: "You", extrusionDepth: 0)
        
        userMessageGeometry.firstMaterial?.diffuse.contents = UIColor.orange
        userMessageGeometry.firstMaterial?.isDoubleSided = true
        userMessageGeometry.font = UIFont(name: "Helvetica Neue", size: CGFloat(3.0))
        userMessageGeometry.flatness = 0
        
        userMessageNode.geometry = userMessageGeometry
        
        let userCoords = AppState.getNavSceneUserCoords()
        userMessageNode.position = SCNVector3(userCoords.x, userCoords.y + 0.05, -1.679)
        userMessageNode.scale = SCNVector3Make(0.01, 0.01, 0.01)
        
        let userMax, userMin: SCNVector3
        userMax = userMessageGeometry.boundingBox.max
        userMin = userMessageGeometry.boundingBox.min
        userMessageNode.pivot = SCNMatrix4MakeTranslation(
            userMin.x + (userMax.x - userMin.x)/2,
            userMin.y + (userMax.y - userMin.y)/2,
            userMin.z + (userMax.z - userMin.z)/2
        )
        
        // User message bubble background
        let userBGNode = SCNNode()
        
        let userBGGeometry = SCNPlane(width: CGFloat((userMax.x - userMin.x) * 1.5), height: CGFloat((userMax.y - userMin.y) * 1.5))
        userBGGeometry.cornerRadius = 0.7
        let userMaterial = SCNMaterial()
        userMaterial.diffuse.contents = UIColor.blue
        userBGGeometry.materials = [userMaterial]
        
        userBGNode.geometry = userBGGeometry
        
        userBGNode.position = SCNVector3(userCoords.x, userCoords.y + 0.05, -1.682)
        userBGNode.scale = SCNVector3(0.01, 0.01, 0.01)
        
        // Destination message bubble text
        let destMessageNode = SCNNode()
        let destMessageGeometry = SCNText(string: "DESPA", extrusionDepth: 0)
        destMessageGeometry.string = AppState.getDestinationTitle().title
        
        destMessageGeometry.firstMaterial?.diffuse.contents = UIColor.orange
        destMessageGeometry.firstMaterial?.isDoubleSided = true
        destMessageGeometry.font = UIFont(name: "Helvetica Neue", size: CGFloat(3.0))
        destMessageGeometry.flatness = 0
        
        destMessageNode.geometry = destMessageGeometry
        
        let destCoords = AppState.getNavSceneDestCoords()
        destMessageNode.position = SCNVector3(destCoords.x, destCoords.y - 0.03, -1.679)
        destMessageNode.scale = SCNVector3Make(0.01, 0.01, 0.01)
        
        let destMax, destMin: SCNVector3
        destMax = destMessageGeometry.boundingBox.max
        destMin = destMessageGeometry.boundingBox.min
        destMessageNode.pivot = SCNMatrix4MakeTranslation(
            destMin.x + (destMax.x - destMin.x)/2,
            destMin.y + (destMax.y - destMin.y)/2,
            destMin.z + (destMax.z - destMin.z)/2
        )
        
        // Destination message bubble background
        let destBGNode = SCNNode()
        
        let destBGGeometry = SCNPlane(width: CGFloat((destMax.x - destMin.x) * 1.5), height: CGFloat((destMax.y - destMin.y) * 1.5))
        destBGGeometry.cornerRadius = 0.7
        let destMaterial = SCNMaterial()
        destMaterial.diffuse.contents = UIColor.blue
        destBGGeometry.materials = [destMaterial]
        
        destBGNode.geometry = destBGGeometry
        
        destBGNode.position = SCNVector3(destCoords.x, destCoords.y - 0.03, -1.682)
        destBGNode.scale = SCNVector3(0.01, 0.01, 0.01)
        
        // Loading both the user bubble and destination to the messageBubble node
        userMessageBubble.addChildNode(userMessageNode)
        userMessageBubble.addChildNode(userBGNode)
        destMessageBubble.addChildNode(destMessageNode)
        destMessageBubble.addChildNode(destBGNode)
        
        self.scene.rootNode.addChildNode(userMessageBubble)
        self.scene.rootNode.addChildNode(destMessageBubble)
        
        userMessageBubble.runAction(show)
        destMessageBubble.runAction(show)
        
        if (AppState.getBuildingCurrentFloor().floorLevel == AppState.getDestinationLevel().level) {
            destMessageBubble.isHidden = false
        }
        else {
            destMessageBubble.isHidden = true
        }
        
        let hide = SCNAction.fadeOut(duration: 0.05)
        let timer = Timer.scheduledTimer(withTimeInterval: 3.3, repeats: true) { timer in
            userMessageBubble.runAction(hide)
            destMessageBubble.runAction(hide)
            timer.invalidate()
        }
        
    }
    
    // Checks if user have arrived to its destination
    func haveArrived(userX: Float, userY: Float) -> Bool {
        var left : Float = 0
        var right : Float = 0
        var d : Float = 0
        left = (pinX - userX)*(pinX - userX)
        right = (pinY - userY)*(pinY - userY)
        d = (left + right).squareRoot()
        if (d <= 0.04 && AppState.getBuildingCurrentFloor().floorLevel == AppState.getDestinationLevel().level) {
            return true
        }
        else {
            return false
        }
    }
    
    //Checks if user is in the vicinity
    func inVicinity(userX: Float, userY: Float) -> Bool {
        var left : Float = 0
        var right : Float = 0
        var d : Float = 0
        left = (pinX - userX)*(pinX - userX)
        right = (pinY - userY)*(pinY - userY)
        d = (left + right).squareRoot()
        if (d <= 0.17 && AppState.getBuildingCurrentFloor().floorLevel == AppState.getDestinationLevel().level) {
            return true
        }
        else {
            return false
        }
    }
    
    /*
     ====================================================================================================
     ~ RECALIBRATION SUBFUNCTION ~
     ====================================================================================================
     */
    @IBAction func startCaptureSession(_ sender: UIButton) {
        if (self.recalibrationViewIsDisplayed) {
            self.stopCaptureSession()
        } else {
            self.recalibrationView.isHidden = false
            self.view.bringSubviewToFront(self.recalibrationView)
            
            // Stop sensors
            self.stopSensors()
            self.captureSession.startRunning()
            UIView.animate(withDuration: 0.3, animations: {
                self.recalibrationView.alpha = 1.0
            }, completion: { (isComplete: Bool) -> Void in
                // self.scannerView.isUserInteractionEnabled = true
                self.captureSession.startRunning()
                sender.setTitle("Cancel", for: .normal)
                self.recalibrationViewIsDisplayed = true
            })
        }
    }
    
    func stopCaptureSession() {
        self.captureSession.stopRunning()
        UIView.animate(withDuration: 0.3, animations: {
            self.recalibrationView.alpha = 0.0
        }, completion: { (isComplete: Bool) -> Void in
            self.recalibrationView.isHidden = true
            //self.view.bringSubviewToFront(self.recalibrationFrame)
            self.view.sendSubviewToBack(self.recalibrationView)
            self.recalibrateButton.setTitle("Recalibrate", for: .normal)
            self.recalibrationViewIsDisplayed = false
            
        })
    }
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if metadataObjects.count == 0 {
            recalibrationFrameBox?.frame = CGRect.zero
            return
        }
        
        // Get metadata object
        let metadataObj = metadataObjects[0] as! AVMetadataMachineReadableCodeObject
        
        if (metadataObj.type == AVMetadataObject.ObjectType.qr) {
            let barCodeObject = videoPreviewLayer?.transformedMetadataObject(for: metadataObj)
            recalibrationFrameBox?.frame = barCodeObject!.bounds
            
            if metadataObj.stringValue != nil && sizeFitsGuide((recalibrationFrameBox?.frame)!) {
                print("Size does fit guide.")
                let qrCodeURL = metadataObj.stringValue!
                var qrCodeMatches : Int = 0
                
                do {
                    try DB.write { db in
                        qrCodeMatches = try QRTag.filter(Column("url") == qrCodeURL).fetchCount(db)
                    }
                } catch {
                    print(error)
                }
                
                if (qrCodeMatches == 1) {
                    print("QR Code matched with 1 in DB.")
                    // Get building alias information from QR code
                    let qrCodeBuilding = qrCodeURL.components(separatedBy: "::")[0]
                    
                    if (qrCodeBuilding == AppState.getBuilding().alias) {
                        print("QR Code building info corresponds to current building.")
                        recalibrateNavigator(rawURL: qrCodeURL)
                    } else {
                        print("QR Code building info DOES NOT correspond to current building.")
                        let failurePrompt = UIAlertController(title: "Recalibration unsuccessful", message: "The scanned QR code belongs to another building.", preferredStyle: .alert)
                        let retryAction = UIAlertAction(title: "Retry", style: .default, handler: { (action) -> Void in
                            self.dismiss(animated: true, completion: nil)
                        })
                        let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: { (action) -> Void in
                            self.dismiss(animated: true, completion: nil)
                            self.stopCaptureSession()
                            
                            // Start sensors
                            self.startSensors()
                        })
                        failurePrompt.addAction(retryAction)
                        failurePrompt.addAction(cancelAction)
                        
                        self.present(failurePrompt, animated: true, completion: nil)
                    }
                } else {
                    print("QR Code matched none.")
                    if self.presentedViewController != nil {
                        return
                    } else {
                        let failurePrompt = UIAlertController(title: "Recalibration unsuccessful", message: "The scanned QR code could not be recognized.", preferredStyle: .alert)
                        let retryAction = UIAlertAction(title: "Retry", style: .default, handler: { (action) -> Void in
                            self.dismiss(animated: true, completion: nil)
                        })
                        let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: { (action) -> Void in
                            self.dismiss(animated: true, completion: nil)
                            self.stopCaptureSession()
                            
                            // Start sensors
                            self.startSensors()
                        })
                        failurePrompt.addAction(retryAction)
                        failurePrompt.addAction(cancelAction)
                        
                        self.present(failurePrompt, animated: true, completion: nil)
                    }
                }
            }
        }
    }
    
    func recalibrateNavigator(rawURL: String) {
        if self.presentedViewController != nil {
            print("There is currently a presented view controller")
            return
        }
        
        // Retreive components of QR code
        let qrCodeFloorLevel = Int(rawURL.components(separatedBy: "::")[1])!
//        let qrCodeBuilding = qrCodeFragments[0]
//        let qrCodeFloorLevel = Int(qrCodeFragments[1])!
        
        // Variables to store info on QR code, building, and floor
        var qrTag : QRTag?
        
        // Prompt message
        var promptMessage : String
        
        do {
            try DB.write { db in
                qrTag = try QRTag.fetchOne(db, "SELECT * FROM QRTag WHERE url = ?", arguments: [rawURL])
            }
        } catch {
            print(error)
        }
        
        // Setting the prompt message
        if (qrCodeFloorLevel == AppState.getBuildingCurrentFloor().floorLevel) {
            promptMessage = "You are still on the same floor. Your position has been fixed."
        } else {
            promptMessage = "You are currently on the \(Utilities.ordinalize(qrCodeFloorLevel)) Floor. Your position has been fixed."
        }
        
        let successPrompt = UIAlertController(title: "Recalibration successful.", message: promptMessage, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Continue", style: .default, handler: { (action) -> Void in
            self.dismiss(animated: true, completion: nil)
            
            // Set shared variables
            AppState.setNavSceneUserCoords(qrTag!.xcoord, qrTag!.ycoord)
            AppState.setBuildingCurrentFloor(qrCodeFloorLevel)
            
            // Re-render navigation scene
            self.renderNavScene()
            
            // Stop capture session and start sensors
            self.stopCaptureSession()
            self.startSensors()
        })
        successPrompt.addAction(okAction)
        
        self.present(successPrompt, animated: true, completion: nil)
    }
    
    func sizeFitsGuide(_ recalibrationFrameBox: CGRect) -> Bool {
        let guideContainsCode = self.recalibrationFrame.frame.contains(recalibrationFrameBox)
        let codeAboveThreshold = recalibrationFrameBox.size.width >= (recalibrationFrameThreshold?.width)! && recalibrationFrameBox.size.height >= (recalibrationFrameThreshold?.height)!
        return (guideContainsCode && codeAboveThreshold)
    }
    
    /*
     ====================================================================================================
     ~ GESTURE RECOGNITION ~
     ====================================================================================================
     */
    @IBAction func viewIsPanned(_ sender: UIPanGestureRecognizer) {
        var translation = sender.translation(in: self.navigationView)
        translation.x *= -1
        
        let camera = self.navigationView.pointOfView!
        let userMarker = self.scene.rootNode.childNode(withName: "UserMarker", recursively: true)!
        
        if (sender.state == .began) {
            self.stopSensors()
            //print("Pan motion has begun.")
        } else if (sender.state == .changed) {
            camera.position = SCNVector3(camera.position.x + Float(translation.x / 1000), camera.position.y + Float(translation.y / 1000), camera.position.z)
        } else if (sender.state == .ended) {
            self.startSensors()
        }
        
        sender.setTranslation(CGPoint.zero, in: self.navigationView)
    }
    
    @IBAction func viewIsPinched(_ sender: UIPinchGestureRecognizer) {
        let camera = self.navigationView.pointOfView!
        
        if (sender.velocity < 0) {
            camera.position.z += Float(sender.scale / 35)
        } else if (sender.velocity > 0) {
            camera.position.z -= Float(sender.scale / 35)
        }
        
        if (camera.position.z < -0.55) {
            camera.position.z = -0.55
        } else if (camera.position.z > 1.20) {
            camera.position.z = 1.20
        }
        
        sender.scale = 1.0
    }
    
    @IBAction func viewIsRotated(_ sender: UIRotationGestureRecognizer) {
        let camera = self.navigationView.pointOfView!
        
        camera.eulerAngles.z += Float(sender.rotation)
        sender.rotation = 0
    }
    
    func enableGestureRecognizers() {
        self.panGestureRecognizer.isEnabled = true
        self.pinchGestureRecognizer.isEnabled = true
        self.rotateGestureRecognizer.isEnabled = true
    }
    func disableGestureRecognizers() {
        self.panGestureRecognizer.isEnabled = false
        self.pinchGestureRecognizer.isEnabled = false
        self.rotateGestureRecognizer.isEnabled = false
    }
}
