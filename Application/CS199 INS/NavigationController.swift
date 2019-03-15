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
    @IBOutlet weak var altLabel: UILabel!
    @IBOutlet weak var levelLabel: UILabel!
    @IBOutlet weak var reachedDestLabel: UILabel!
    @IBOutlet weak var averageVLabel: UILabel!
    @IBOutlet weak var maxAveLabel: UILabel!
    @IBOutlet weak var destTitleLabel: UILabel!
    
    // Variables for use with recalibration
    @IBOutlet weak var recalibrationView: UIView!
    @IBOutlet weak var recalibrationFrame: UIImageView!
    var recalibrationFrameBox : UIView?
    var recalibrationFrameThreshold : CGSize?
    var captureSession : AVCaptureSession = AVCaptureSession()
    var videoPreviewLayer : AVCaptureVideoPreviewLayer?
    
    // Sensor object variables + Accelerometer noise|spike filter
    lazy var compassManager = CLLocationManager()
    lazy var altimeter = CMAltimeter()
    lazy var deviceMotionManager = CMMotionManager()
    lazy var filter = MirrorFilter(rate: 60.0, cutoff: 3.0, adaptive: false)
    
    // Variables needed to detect if user haved arrived to destination
    var pinX : Float = 0
    var pinY : Float = 0
    
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
    var averageV : Double = 0
    var count : Int = 1
    var maxAve : Double = 0
    var pos : Double = 0
    
    // Scene variables
    var scene = SCNScene(named: "SceneObjects.scnassets/NavigationScene.scn")!
    
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
        
        self.startSensors()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.stopSensors()
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
                
                var level = 0
                
                if (error != nil) {
                    self.stopAltimeter()
                } else {
                    
                    self.altLabel.text = String(format: "Rel. alt.: %.02f", altitude)
                    
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
                level = Int(altitude / 2.0)
                self.levelLabel.text = String(format: "Level: %d", level)
                self.destTitleLabel.text = "You are currently on the \(Utilities.ordinalize(AppState.getBuildingCurrentFloor().floorLevel)) floor. \(AppState.getDestinationTitle().title)  (\(AppState.getDestinationSubtitle().subtitle)) is on the \(Utilities.ordinalize(AppState.getDestinationLevel().level)) floor."
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
                    print(self.pos)
                    self.averageV = ( self.averageV + lastV ) / Double(self.count)
                    if (self.averageV > self.maxAve) {
                        self.maxAve = self.averageV
                    }
                    self.count += 1
                    
                    self.averageVLabel.text = String(format: "Ave V.: %.05f", self.averageV)
                    self.maxAveLabel.text = String(format: "Max Ave.: %.05f", self.maxAve)
                    
                    let user = self.scene.rootNode.childNode(withName: "UserMarker", recursively: true)!
                    //user.simdPosition += user.simdWorldFront * 0.0004998
                    user.simdPosition += user.simdWorldFront * (Float(self.pos))
                    AppState.setNavSceneUserCoords(Double(user.position.x), Double(user.position.y))
                    // <+ motion incorporating current velocity >
                    if (self.haveArrived(userX: user.position.x, userY: user.position.y)) {
                        self.reachedDestLabel.text = "Reached Destination: TRUE"
                        
                        let alertPrompt = UIAlertController(title: "You have arrived.", message: " ", preferredStyle: .alert)
                        
                        let imageView = UIImageView(frame: CGRect(x: 10, y: 50, width: 250, height: 230))
                        imageView.image = UIImage(named: "image")
                        alertPrompt.view.addSubview(imageView)
                        
                        let height = NSLayoutConstraint(item: alertPrompt.view, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 330)
                        alertPrompt.view.addConstraint(height)
                        
                        let width = NSLayoutConstraint(item: alertPrompt.view, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 250)
                        alertPrompt.view.addConstraint(width)
                        
                        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel, handler: nil)
                        alertPrompt.addAction(cancelAction)
                        
                        self.present(alertPrompt, animated: true, completion: nil)
                    }
                    else {
                        self.reachedDestLabel.text = "Reached Destination: FALSE"
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
    @IBAction func onRecenterPress(_ sender: UIButton) {
        self.panCameraToUser()
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
        // camera.position = SCNVector3(targetMarker.position.x, targetMarker.position.y, camera.position.z)
        
        let panFromTargetToUser = CABasicAnimation(keyPath: "position")
        panFromTargetToUser.fromValue = SCNVector3(targetMarker.position.x, targetMarker.position.y, camera.position.z)
        // panFromTargetToUser.fromValue = camera.position
        panFromTargetToUser.toValue = SCNVector3(userMarker.position.x, userMarker.position.y, camera.position.z)
        panFromTargetToUser.duration = 1.00
        panFromTargetToUser.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        panFromTargetToUser.beginTime = 2.00
        
        let panAnimations = CAAnimationGroup()
        panAnimations.animations = [panFromCamToTarget, panFromTargetToUser]
        panAnimations.duration = 3.00
        
        // panAnimations.removedOnCompletion = NO
        camera.addAnimation(panAnimations, forKey: nil)
        camera.position = SCNVector3(userMarker.position.x, userMarker.position.y, camera.position.z)
        // camera.removeAllAnimations()
        
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
        
        let userBubble = self.scene.rootNode.childNode(withName: "You", recursively: true)!
        let userCoords = AppState.getNavSceneUserCoords()
        userBubble.position = SCNVector3(userCoords.x, userCoords.y + 0.02, -1.679)
        userBubble.runAction(show)
       /*
        let userBox = self.scene.rootNode.childNode(withName: "UserBox", recursively: true) as! SCNBox
        let (min, max) = userBubble.boundingBox
        userBox.width = max.x - min.x
        userBox.height = max.y - min.y
        userBox.length = max.z - min.z
        userBox.position = SCNVector3(userBubble.position.x, userBubble.position.y, userBubble.position.z)
 
        let box = SCNBox(width: CGFloat(max.x - min.x), height: CGFloat(max.y - min.y), length: CGFloat(max.z - min.z), chamferRadius: 0.2)
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.red
        box.materials = [material]
        let boxNode = SCNNode(geometry: box)
        boxNode.position = SCNVector3(0,0,-0.5)
        scene.rootNode.addChildNode(boxNode)
        */
        
        let (min, max) = userBubble.boundingBox
        let userBox = SCNPlane(width: CGFloat(max.x - min.x), height: CGFloat(max.y - min.y))
        userBox.cornerRadius = 0.2
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.red
        userBox.materials = [material]
        let userBoxNode = SCNNode(geometry: userBox)
        userBoxNode.position = SCNVector3(userBubble.position.x, userBubble.position.y, userBubble.position.z)
        userBoxNode.scale = SCNVector3(0.03, 0.03, 0.03)
        scene.rootNode.addChildNode(userBoxNode)
        
        let destinationBubble = self.scene.rootNode.childNode(withName: "Destination", recursively: true)!
        let destCoords = AppState.getNavSceneDestCoords()
        destinationBubble.position = SCNVector3(destCoords.x, destCoords.y + 0.02, -1.679)
        destinationBubble.runAction(show)
        
        let textGeometry = destinationBubble.geometry as! SCNText
        textGeometry.string = AppState.getDestinationTitle().title
        if (AppState.getBuildingCurrentFloor().floorLevel == AppState.getDestinationLevel().level) {
            destinationBubble.isHidden = false
        }
        else {
            destinationBubble.isHidden = true
        }
        
        let hide = SCNAction.fadeOut(duration: 0.05)
        let timer = Timer.scheduledTimer(withTimeInterval: 3.3, repeats: true) { timer in
            userBubble.runAction(hide)
            destinationBubble.runAction(hide)
            userBoxNode.runAction(hide)
            timer.invalidate()
            }
        //timer.fire()
        //
        //timer.fire()
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
    
    /*
     ====================================================================================================
     ~ RECALIBRATION SUBFUNCTION ~
     ====================================================================================================
     */
    @IBAction func startCaptureSession(_ sender: Any) {
        // Stop sensors
        self.recalibrationView.isHidden = false
        self.view.bringSubviewToFront(self.recalibrationView)
        self.stopSensors()
        self.captureSession.startRunning()
        UIView.animate(withDuration: 0.3, animations: {
            self.recalibrationView.alpha = 1.0
        }, completion: { (isComplete: Bool) -> Void in
            // self.scannerView.isUserInteractionEnabled = true
            self.captureSession.startRunning()
        })
    }
    
    func stopCaptureSession() {
        self.captureSession.stopRunning()
        UIView.animate(withDuration: 0.3, animations: {
            self.recalibrationView.alpha = 0.0
        }, completion: { (isComplete: Bool) -> Void in
            self.recalibrationView.isHidden = true
            //self.view.bringSubviewToFront(self.recalibrationFrame)
            self.view.sendSubviewToBack(self.recalibrationView)
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
        let qrCodeFragments = rawURL.components(separatedBy: "::")
        let qrCodeBuilding = qrCodeFragments[0]
        let qrCodeFloorLevel = Int(qrCodeFragments[1])!
        
        // Variables to store info on QR code, building, and floor
        var qrTag : QRTag?
        var building : Building?
        var floor : Floor?
        
        // Prompt message
        var promptMessage : String
        
        do {
            try DB.write { db in
                qrTag = try QRTag.fetchOne(db, "SELECT * FROM QRTag WHERE url = ?", arguments: [rawURL])
                building = try Building.fetchOne(db, "SELECT * FROM Building WHERE alias = ?", arguments: [qrCodeBuilding])
                floor = try Floor.fetchOne(db, "SELECT * FROM Floor WHERE bldg = ? AND level = ?", arguments: [qrCodeBuilding, qrCodeFloorLevel])
            }
        } catch {
            print(error)
        }
        
        // Setting the prompt message
        if (floor!.level == AppState.getBuildingCurrentFloor().floorLevel) {
            promptMessage = "You are still on the same floor. Your position has been fixed."
        } else {
            promptMessage = "You are currently on the \(Utilities.ordinalize(floor!.level)) Floor. Your position has been fixed."
        }
        
        let successPrompt = UIAlertController(title: "Recalibration successful.", message: promptMessage, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Continue", style: .default, handler: { (action) -> Void in
            self.dismiss(animated: true, completion: nil)
            
            // Set shared variables
            AppState.setNavSceneUserCoords(qrTag!.xcoord, qrTag!.ycoord)
            AppState.setBuildingCurrentFloor(floor!.level)
            
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
}
