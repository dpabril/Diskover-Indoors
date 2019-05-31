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
    
    @IBOutlet weak var navigationView: SCNView!
    @IBOutlet weak var cameraModeButton: UIBarButtonItem!
    @IBOutlet weak var showDesinationButton: UIBarButtonItem!
    @IBOutlet weak var calibrateButton: UIBarButtonItem!
    @IBOutlet weak var relAltLabel: UILabel!
    
    // Variables for use with recalibration
    @IBOutlet weak var recalibrationView: UIView!
    @IBOutlet weak var recalibrationFrame: UIImageView!
    var recalibrationFrameBox : UIView?
    var recalibrationFrameThreshold : CGSize?
    var captureSession : AVCaptureSession = AVCaptureSession()
    var videoPreviewLayer : AVCaptureVideoPreviewLayer?
    
    // UX Storyboard elements and logic variables
    @IBOutlet weak var changingFloorIndicator: UIView!
    @IBOutlet weak var changingFloorLabel: UILabel!
    var levelChange : LevelChange = .none
    
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
    var rotationOffset : Double = 0
    var cameraMode : CameraMode = .unlocked
    var recalibrationViewIsDisplayed = false
    
    @IBOutlet weak var userLevelLabel: UIBarButtonItem!
    @IBOutlet weak var destinationLevelLabel: UIBarButtonItem!
    
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
        
        // Modify disabled color, to emulate regular label
        self.userLevelLabel.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.black], for: .disabled)
        self.destinationLevelLabel.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.black], for: .disabled)
        
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
        
        let currentBuilding = AppState.getBuilding()
        
        self.navigationItem.title = currentBuilding.name
        
        // Configuring user and destination level labels
        self.userLevelLabel.title = Utilities.ordinalize(AppState.getBuildingCurrentFloor().floorLevel, currentBuilding.hasLGF, abbv: false)
        self.destinationLevelLabel.title = AppState.getDestinationTitle().title + ", " + Utilities.ordinalize(AppState.getDestinationLevel().level, currentBuilding.hasLGF, abbv: AppState.getDestinationTitle().title.count >= 20)
        
        // Configuring floor plane and rendered plan
        let sceneFloor = self.scene.rootNode.childNode(withName: "Floor", recursively: true)!
        sceneFloor.geometry?.firstMaterial?.diffuse.contents = AppState.getBuildingCurrentFloor().floorImage
        sceneFloor.scale.x = Float(currentBuilding.xscale)
        sceneFloor.scale.y = Float(currentBuilding.yscale)
        
        // Configuring user position
        let userMarker = self.scene.rootNode.childNode(withName: "UserMarker", recursively: true)!
        let userCoords = AppState.getNavSceneUserCoords()
        userMarker.position = SCNVector3(userCoords.x, userCoords.y, 0)
        self.rotationOffset = currentBuilding.compassOffset
        
        // Configuring location marker position
        let pinMarker = self.scene.rootNode.childNode(withName: "LocationPinMarker", recursively: true)!
        let destCoords = AppState.getNavSceneDestCoords()
        self.shownVicinity = false
        self.shownArrived = false
        pinMarker.position = SCNVector3(destCoords.x, destCoords.y, 0)
        
        // Configuring user's / stairs marker's position
        if (AppState.isUserOnDestinationLevel()) {
            self.showPinMarker()
            self.hideStaircaseMarker()
            pinMarker.position = SCNVector3(destCoords.x, destCoords.y, 0)
            self.pinX = pinMarker.position.x
            self.pinY = pinMarker.position.y
        } else {
            let staircaseMarker = self.scene.rootNode.childNode(withName: "StaircaseMarker", recursively: true)!
            let staircaseMarkerPoint = AppState.getNearestStaircase()
            staircaseMarker.position = SCNVector3(staircaseMarkerPoint.xcoord, staircaseMarkerPoint.ycoord, 0)
            if (AppState.getDestinationLevel().level < AppState.getBuildingCurrentFloor().floorLevel) {
                staircaseMarker.eulerAngles.z = .pi
            } else {
                staircaseMarker.eulerAngles.z = 0
            }
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
        if (self.recalibrationViewIsDisplayed) {
            self.stopCaptureSession()
        }
        super.viewWillDisappear(animated)
        
        self.stopSensors(withAltimeter: false)
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
            self.compassManager.headingFilter = 1.0
            self.compassManager.delegate = self
            self.compassManager.startUpdatingHeading()
        }
    }
    func locationManagerShouldDisplayHeadingCalibration(_ manager: CLLocationManager) -> Bool {
        return true
    }
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        let userMarker = self.scene.rootNode.childNode(withName: "UserMarker", recursively: true)!
        userMarker.eulerAngles.z = -Utilities.degToRad(self.rotationOffset + newHeading.magneticHeading)

        if (self.cameraMode == .rotating) {
            let camera = self.navigationView.pointOfView!
            camera.eulerAngles.z = userMarker.eulerAngles.z
        }
        
        let front = userMarker.simdWorldFront
        let userToLocVector = simd_float3(pinX - userMarker.position.x, pinY - userMarker.position.y, 1)
        let userFrontVector = simd_float3(front.x, front.y, 1)
        let normalVector = simd_float3(0, 0, 1)
        var vectorAngle = acos(simd_dot(simd_normalize(userToLocVector), simd_normalize(userFrontVector)))
        let vectorCross = simd_cross(userToLocVector, userFrontVector)
        
        if (simd_dot(normalVector, vectorCross) < 0) {
            vectorAngle *= -1
        }
        print("Angle: \(vectorAngle)")
        
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
                self.relAltLabel.text = "\(altitude)"
                
                if (error != nil) {
                    self.stopAltimeter()
                } else {
                    
                    // Determine whether or not to show loading activity indicator
                    if ((Double(altitude) >= AppState.getBuilding().delta * 0.60) && (AppState.getBuildingCurrentFloor().floorLevel < AppState.getBuilding().floors)) {
                        if (self.changingFloorIndicator.isHidden) {
                            self.changingFloorLabel.text = "Going up..."
                            self.changingFloorIndicator.isHidden = false
                            self.levelChange = .up
                            UIView.animate(withDuration: 0.3, animations: {
                                self.changingFloorIndicator.alpha = 1.0
                            })
                            self.changeFloor(1)
                        }
                    } else if ((Double(altitude) <= -AppState.getBuilding().delta * 0.60) && (AppState.getBuildingCurrentFloor().floorLevel > 1)) {
                        if (self.changingFloorIndicator.isHidden) {
                            self.changingFloorLabel.text = "Going down..."
                            self.changingFloorIndicator.isHidden = false
                            self.levelChange = .down
                            UIView.animate(withDuration: 0.3, animations: {
                                self.changingFloorIndicator.alpha = 1.0
                            })
                            self.changeFloor(-1)
                        }
                    }
                    // Determine whether to hide floor change indicator when user doesn't continue going up/down
                    if (!self.changingFloorIndicator.isHidden) {
                        if ((self.levelChange == .up) && (Double(altitude) < AppState.getBuilding().delta * 0.60)) {
                            self.changingFloorLabel.text = "Cancelling..."
                            self.levelChange = .none
                            UIView.animate(withDuration: 0.3, animations: {
                                self.changingFloorIndicator.alpha = 0.0
                            }, completion: { (isComplete: Bool) -> Void in
                                self.changingFloorIndicator.isHidden = true
                            })
                            self.changeFloor(-1)
                        } else if ((self.levelChange == .down) && (Double(altitude) > -AppState.getBuilding().delta * 0.60)) {
                            self.changingFloorLabel.text = "Cancelling..."
                            self.levelChange = .none
                            UIView.animate(withDuration: 0.3, animations: {
                                self.changingFloorIndicator.alpha = 0.0
                            }, completion: { (isComplete: Bool) -> Void in
                                self.changingFloorIndicator.isHidden = true
                            })
                            self.changeFloor(1)
                        }
                    }
                    
                    // Reset altimeter upon significant change in altitude
                    if (Double(altitude) >= AppState.getBuilding().delta) {
                        self.resetAltimeter(pan: true)
                    } else if (Double(altitude) <= -AppState.getBuilding().delta) {
                        self.resetAltimeter(pan: true)
                    }
                }
            })
        }
    }
    func changeFloor(_ direction : Int) {
        AppState.setBuildingCurrentFloor(AppState.getBuildingCurrentFloor().floorLevel + direction) // direction is either +1 or -1
            
        let sceneFloor = self.scene.rootNode.childNode(withName: "Floor", recursively: true)!
        sceneFloor.geometry?.firstMaterial?.diffuse.contents = AppState.getBuildingCurrentFloor().floorImage
        
        self.userLevelLabel.title = Utilities.ordinalize(AppState.getBuildingCurrentFloor().floorLevel, AppState.getBuilding().hasLGF, abbv: false)
        
        if (AppState.isUserOnDestinationLevel()) {
            let pinMarker = self.scene.rootNode.childNode(withName: "LocationPinMarker", recursively: true)!
            let destCoords = AppState.getNavSceneDestCoords()
            self.shownVicinity = false
            self.shownArrived = false
            pinMarker.position = SCNVector3(destCoords.x, destCoords.y, 0)
            self.pinX = pinMarker.position.x
            self.pinY = pinMarker.position.y
            self.hideStaircaseMarker()
            self.showPinMarker()
        } else {
            let staircaseMarker = self.scene.rootNode.childNode(withName: "StaircaseMarker", recursively: true)!
            let staircaseMarkerPoint = AppState.getNearestStaircase()
            staircaseMarker.position = SCNVector3(staircaseMarkerPoint.xcoord, staircaseMarkerPoint.ycoord, 0)
            if (AppState.getDestinationLevel().level < AppState.getBuildingCurrentFloor().floorLevel) {
                staircaseMarker.eulerAngles.z = .pi
            } else {
                staircaseMarker.eulerAngles.z = 0
            }
            self.hidePinMarker()
            self.showStaircaseMarker()
        }
    }
    func stopAltimeter() {
        if (CMAltimeter.isRelativeAltitudeAvailable()) {
            self.altimeter.stopRelativeAltitudeUpdates()
        }
    }
    func resetAltimeter(pan : Bool) {
        self.stopAltimeter()
        self.startAltimeter()
        
        if (pan) {
            self.panCamToTargetAndBack()
        }
        if (!self.changingFloorIndicator.isHidden) {
            self.levelChange = .none
            UIView.animate(withDuration: 0.3, animations: {
                self.changingFloorIndicator.alpha = 0.0
            }, completion: { (isComplete: Bool) -> Void in
                self.changingFloorIndicator.isHidden = true
            })
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
                if (self.xAccelZeroCount == 10 || self.yAccelZeroCount == 10 || self.zAccelZeroCount == 10) {
                    self.prevVx = 0
                    self.prevVy = 0
                    self.prevVz = 0
                    self.xAccelZeroCount = 0
                    self.yAccelZeroCount = 0
                    self.zAccelZeroCount = 0
                }
                
                if ((abs(self.prevVx) >= 0.01) || (abs(self.prevVy)) >= 0.01) {
                    // Calculates velocity
                    let vx = self.prevVx
                    let vy = self.prevVy
                    let vz = self.prevVz
                    var lastV = sqrt(vx * vx + vy * vy + vz * vz) / 10
                    
                    let user = self.scene.rootNode.childNode(withName: "UserMarker", recursively: true)!
                    let camera = self.navigationView.pointOfView!
                    //user.simdPosition += user.simdWorldFront * 0.0004998
                    if (lastV > 0.002) {
                        lastV = 0.002
                    }
                    
                    if (abs(deviceMotionData!.rotationRate.z) < 1.5) {
                        user.simdPosition += user.simdWorldFront * Float(lastV)
                    }
                    
                    
                    // Rotate camera according to current camera mode
                    if (self.cameraMode != .unlocked) {
                        camera.position = SCNVector3(user.position.x, user.position.y, camera.position.z)
                    }
                    
                    AppState.setNavSceneUserCoords(Double(user.position.x), Double(user.position.y))
                    // <+ motion incorporating current velocity >
                    
//                    if (self.haveArrived(userX: user.position.x, userY: user.position.y) && self.shownArrived == false) {
//                        //self.reachedDestLabel.text = "Reached Destination: TRUE"
//                        let message = "\(AppState.getDestinationTitle().title)\n(\(AppState.getDestinationSubtitle().subtitle))"
//                        let alertPrompt = UIAlertController(title: "You have arrived.", message: message, preferredStyle: .alert)
//
//                        let imageView = UIImageView(frame: CGRect(x: 25, y: 100, width: 250, height: 333))
//                        imageView.image = UIImage(named: "\(AppState.getBuilding().alias)/\(AppState.getDestinationLevel().level)/\(AppState.getDestinationTitle().title)")
//                        imageView.contentMode = .scaleAspectFit
//                        alertPrompt.view.addSubview(imageView)
//
//                        let height = NSLayoutConstraint(item: alertPrompt.view, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 485)
//                        alertPrompt.view.addConstraint(height)
//
//                        let width = NSLayoutConstraint(item: alertPrompt.view, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 302)
//                        alertPrompt.view.addConstraint(width)
//
//                        let cancelAction = UIAlertAction(title: "Continue", style: UIAlertAction.Style.cancel, handler: nil)
//                        alertPrompt.addAction(cancelAction)
//
//                        self.present(alertPrompt, animated: true, completion: nil)
//                        self.shownArrived = true
//                    }
                    if (self.inVicinity(userX: user.position.x, userY: user.position.y) && self.shownVicinity == false) {
                        
                        let rightOrLeft = self.leftOrRight(userX: user.position.x, userY: user.position.y, front: user.simdWorldFront)
                        
                        let message : String
                        if (AppState.getDestinationSubtitle().subtitle == "") {
                            message = "\(AppState.getDestinationTitle().title) is nearby. The destination is \(rightOrLeft). Please be guided by the image for direction, and press Done upon arrival."
                        } else {
                            message = "\(AppState.getDestinationTitle().title) (\(AppState.getDestinationSubtitle().subtitle)) is nearby. The destination is \(rightOrLeft). Please be guided by the image for direction, and press Done upon arrival."
                        }
                        let alertPrompt = UIAlertController(title: "Destination in vicinity.", message: message, preferredStyle: .alert)

                        let imageView = UIImageView(frame: CGRect(x: 25, y: 130, width: 250, height: 333))
                        imageView.image = UIImage(named: "\(AppState.getBuilding().alias)/\(AppState.getDestinationLevel().level)/\(AppState.getDestinationTitle().title)")
                        if (imageView.image == nil) {
                            imageView.image = UIImage(named: "ImgNotFound")
                        }
                        alertPrompt.view.addSubview(imageView)

                        let height = NSLayoutConstraint(item: alertPrompt.view, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 515)
                        alertPrompt.view.addConstraint(height)

                        let width = NSLayoutConstraint(item: alertPrompt.view, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 300)
                        alertPrompt.view.addConstraint(width)

                        let cancelAction = UIAlertAction(title: "Done", style: UIAlertAction.Style.cancel, handler: { (action) -> Void in
                            self.tabBarController!.tabBar.items![1].isEnabled = false
                            self.tabBarController!.selectedIndex = 2
                        })
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
        self.startDeviceMotionManager()
        self.startAltimeter()
    }
    // Function to call sensors' stop functions
    func stopSensors (withAltimeter : Bool) {
        self.stopCompass()
        self.stopDeviceMotionManager()
        if (withAltimeter) {
            self.stopAltimeter()
        }
    }
    
    /*
     ====================================================================================================
     ~ SCENE MANIPULATION ~
     ====================================================================================================
     */
    @IBAction func onDestinationLevelLabelPress(_ sender: UIBarButtonItem) {
        //self.tabBarController!.selectedIndex = 2
        let message : String
        let locationHasSubtitle = AppState.getDestinationSubtitle().subtitle.count > 0
        if (locationHasSubtitle) {
            message = "\(AppState.getDestinationTitle().title)\n(\(AppState.getDestinationSubtitle().subtitle))"
        } else {
            message = "\(AppState.getDestinationTitle().title)"
        }
        
        let alertPrompt = UIAlertController(title: "This is your destination.", message: message, preferredStyle: .alert)
        
        let imageView = UIImageView(frame: CGRect(x: 25, y: locationHasSubtitle ? 100 : 80, width: 250, height: 333))
        imageView.image = UIImage(named: "\(AppState.getBuilding().alias)/\(AppState.getDestinationLevel().level)/\(AppState.getDestinationTitle().title)")
        if (imageView.image == nil) {
            imageView.image = UIImage(named: "ImgNotFound")
        }
        alertPrompt.view.addSubview(imageView)
        
        let height = NSLayoutConstraint(item: alertPrompt.view, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: locationHasSubtitle ? 485 : 465)
        alertPrompt.view.addConstraint(height)
        
        let width = NSLayoutConstraint(item: alertPrompt.view, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 300)
        alertPrompt.view.addConstraint(width)
        
        let cancelAction = UIAlertAction(title: "Continue", style: UIAlertAction.Style.cancel, handler: {action in
            self.tabBarController!.tabBar.items![1].isEnabled = true
            self.tabBarController!.selectedIndex = 1
        })
        alertPrompt.addAction(cancelAction)
        
        self.present(alertPrompt, animated: true, completion: nil)
    }
    @IBAction func onShowDestinationPress(_ sender: UIBarButtonItem) {
        // Stop sensors to prepare animation
        //self.stopSensors(withAltimeter: false)
        self.disableGestureRecognizers()
        self.panCamToTargetAndBack()
        // Start sensors after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            //self.startSensors()
            self.enableGestureRecognizers()
        }
    }
    @IBAction func onSupportPress(_ sender: UIButton) {
        let supportPrompt = UIAlertController(title: "Diskover Indoors Support", message: "Do you have questions or concerns regarding the app? Press on one of the links below.", preferredStyle: .actionSheet)
        let contactAction = UIAlertAction(title: "Contact Us", style: .default, handler: { (action) -> Void in
            UIApplication.shared.open(URL(string: "https://dpabril.github.io/Diskover-Indoors#having-problems-while-using-the-application")!, options: [:], completionHandler: nil)
        })
        let policyAction = UIAlertAction(title: "Privacy Policy", style: .default, handler: { (action) -> Void in
            UIApplication.shared.open(URL(string: "https://dpabril.github.io/Diskover-Indoors#privacy-policy")!, options: [:], completionHandler: nil)
        })
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        supportPrompt.addAction(contactAction)
        supportPrompt.addAction(policyAction)
        supportPrompt.addAction(cancelAction)
        self.present(supportPrompt, animated: true, completion: nil)
    }
    
    func cameraUnlocked() {
        self.cameraMode = .unlocked
        self.cameraModeButton.image = UIImage(named: "CameraMode_Default")
        self.cameraModeButton.title = "Unlocked"
        self.panGestureRecognizer.isEnabled = true
        self.rotateGestureRecognizer.isEnabled = true
        self.resetCamera()
    }
    func cameraCentered() {
        self.cameraMode = .centered
        self.cameraModeButton.image = UIImage(named: "CameraMode_Centered")
        self.cameraModeButton.title = "Centered"
        self.panGestureRecognizer.isEnabled = false
        self.panCameraToUser()
    }
    func cameraRotates() {
        self.cameraMode = .rotating
        self.cameraModeButton.image = UIImage(named: "CameraMode_Rotating")
        self.cameraModeButton.title = "Rotating"
        self.panGestureRecognizer.isEnabled = false
        self.rotateGestureRecognizer.isEnabled = false
    }
    @IBAction func onCameraModePress(_ sender: UIBarButtonItem) {
        if (self.cameraMode == .unlocked) {
            self.cameraCentered()
        } else if (self.cameraMode == .centered) {
            self.cameraRotates()
        } else if (self.cameraMode == .rotating) {
            self.cameraUnlocked()
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
    
    func resetCamera() {
        let camera = self.navigationView.pointOfView!
        let userMarker = self.scene.rootNode.childNode(withName: "UserMarker", recursively: true)!
        
        let panFromCamToUser = CABasicAnimation(keyPath: "position")
        panFromCamToUser.fromValue = camera.position
        // panFromCamToUser.toValue = SCNVector3(userMarker.position.x, userMarker.position.y, -0.065)
        panFromCamToUser.toValue = SCNVector3(userMarker.position.x, userMarker.position.y, camera.position.z)
        panFromCamToUser.duration = 0.3
        panFromCamToUser.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        let rotateCamToZero = CABasicAnimation(keyPath: "eulerAngles.z")
        rotateCamToZero.fromValue = camera.eulerAngles.z
        let cameraAngle = Utilities.radToDeg(Double(camera.eulerAngles.z))
        
        if (cameraAngle <= -360.0 && cameraAngle >= -450.0) {
            rotateCamToZero.toValue = Utilities.degToRad(-360.0)
            rotateCamToZero.byValue = Utilities.degToRad(0.1)
            rotateCamToZero.duration = 0.3
        } else if (cameraAngle <= -90.0 && cameraAngle > -180.0) {
            rotateCamToZero.toValue = Utilities.degToRad(0.0)
            rotateCamToZero.byValue = Utilities.degToRad(0.1)
            rotateCamToZero.duration = 0.3
        } else if (cameraAngle <= -180.0 && cameraAngle > -360.0) {
            rotateCamToZero.toValue = Utilities.degToRad(-360.0)
            rotateCamToZero.byValue = Utilities.degToRad(-0.1)
            rotateCamToZero.duration = 0.3
        }
        rotateCamToZero.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        let camResetAnimation = CAAnimationGroup()
        camResetAnimation.animations = [panFromCamToUser, rotateCamToZero]
        camResetAnimation.duration = 0.3
        
        camera.addAnimation(camResetAnimation, forKey: nil)
        // camera.position = SCNVector3(userMarker.position.x, userMarker.position.y, -0.065)
        camera.position = SCNVector3(userMarker.position.x, userMarker.position.y, camera.position.z)
        camera.eulerAngles.z = 0.0
    }
    
    // Render the floor plan
    func renderNavScene() {
        let sceneFloor = self.scene.rootNode.childNode(withName: "Floor", recursively: true)!
        sceneFloor.geometry?.firstMaterial?.diffuse.contents = AppState.getBuildingCurrentFloor().floorImage
        
        // Configuring user position
        let userMarker = self.scene.rootNode.childNode(withName: "UserMarker", recursively: true)!
        let userCoords = AppState.getNavSceneUserCoords()
        userMarker.position = SCNVector3(userCoords.x, userCoords.y, 0)
        
        // Configuring location marker position
        let pinMarker = self.scene.rootNode.childNode(withName: "LocationPinMarker", recursively: true)!
        let destCoords = AppState.getNavSceneDestCoords()
        self.shownVicinity = false
        self.shownArrived = false
        pinMarker.position = SCNVector3(destCoords.x, destCoords.y, 0)
        
        // Configuring user's / stairs marker's position
        if (AppState.isUserOnDestinationLevel()) {
            self.showPinMarker()
            self.hideStaircaseMarker()
            // pinMarker.position = SCNVector3(destCoords.x, destCoords.y, 0)
            self.pinX = pinMarker.position.x
            self.pinY = pinMarker.position.y
        } else {
            let staircaseMarker = self.scene.rootNode.childNode(withName: "StaircaseMarker", recursively: true)!
            let staircaseMarkerPoint = AppState.getNearestStaircase()
            staircaseMarker.position = SCNVector3(staircaseMarkerPoint.xcoord, staircaseMarkerPoint.ycoord, 0)
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
        let show = SCNAction.fadeIn(duration: 0.35)
        
        let userMessageBubble = SCNNode()
        let targetMessageBubble = SCNNode()
        
        // User message bubble text
        let userMessageNode = SCNNode()
        let userMessageGeometry = SCNText(string: "You", extrusionDepth: 0)
        
        userMessageGeometry.firstMaterial?.diffuse.contents = UIColor.black
        userMessageGeometry.firstMaterial?.isDoubleSided = true
        userMessageGeometry.font = UIFont(name: "Helvetica Neue", size: CGFloat(3.0))
        userMessageGeometry.flatness = 0
        
        userMessageNode.geometry = userMessageGeometry
        
        let userCoords = AppState.getNavSceneUserCoords()
        userMessageNode.position = SCNVector3(userCoords.x, userCoords.y - 0.13, 0.011)
        userMessageNode.scale = SCNVector3Make(0.04, 0.04, 0.04)
        
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
        userMaterial.diffuse.contents = UIColor.yellow
        userBGGeometry.materials = [userMaterial]
        
        userBGNode.geometry = userBGGeometry
        
        userBGNode.position = SCNVector3(userCoords.x, userCoords.y - 0.13, 0.01)
        userBGNode.scale = SCNVector3(0.04, 0.04, 0.04)
        
        // Secondary marker message bubble
        let targetMessageNode = SCNNode()
        let targetMessageGeometry = SCNText(string: "", extrusionDepth: 0)
        let targetCoords : FloorPoint
        let targetMessageOffset : Double
        
        if (AppState.getBuildingCurrentFloor().floorLevel == AppState.getDestinationLevel().level) {
            targetMessageGeometry.string = AppState.getDestinationTitle().title
            targetCoords = AppState.getNavSceneDestCoords()
            targetMessageOffset = 0.12
        } else {
            let toFloorLevel = Utilities.ordinalize(AppState.getDestinationLevel().level, AppState.getBuilding().hasLGF, abbv: true)
            targetMessageGeometry.string = "To \(toFloorLevel)"
            
            let staircaseCoords = AppState.getNearestStaircase()
            targetCoords = FloorPoint(staircaseCoords.xcoord, staircaseCoords.ycoord)
            
            targetMessageOffset = 0.20
        }
        
        targetMessageGeometry.firstMaterial?.diffuse.contents = UIColor.black
        targetMessageGeometry.firstMaterial?.isDoubleSided = true
        targetMessageGeometry.font = UIFont(name: "Helvetica Neue", size: CGFloat(3.0))
        targetMessageGeometry.flatness = 0
        
        targetMessageNode.geometry = targetMessageGeometry
        targetMessageNode.position = SCNVector3(targetCoords.x, targetCoords.y - targetMessageOffset, 0.011)
        targetMessageNode.scale = SCNVector3Make(0.04, 0.04, 0.04)
        
        let targetMax, targetMin: SCNVector3
        targetMax = targetMessageGeometry.boundingBox.max
        targetMin = targetMessageGeometry.boundingBox.min
        targetMessageNode.pivot = SCNMatrix4MakeTranslation(
            targetMin.x + (targetMax.x - targetMin.x)/2,
            targetMin.y + (targetMax.y - targetMin.y)/2,
            targetMin.z + (targetMax.z - targetMin.z)/2
        )
        
        // Target message bubble background
        let targetBGNode = SCNNode()
        
        let targetBGGeometry = SCNPlane(width: CGFloat((targetMax.x - targetMin.x) * 1.5), height: CGFloat((targetMax.y - targetMin.y) * 1.5))
        targetBGGeometry.cornerRadius = 0.7
        let targetMaterial = SCNMaterial()
        targetMaterial.diffuse.contents = UIColor.yellow
        targetBGGeometry.materials = [targetMaterial]
        
        targetBGNode.geometry = targetBGGeometry
        
        targetBGNode.position = SCNVector3(targetCoords.x, targetCoords.y - targetMessageOffset, 0.01)
        targetBGNode.scale = SCNVector3(0.04, 0.04, 0.04)
        
        // Loading both the user bubble and destination to the messageBubble node
        userMessageBubble.addChildNode(userMessageNode)
        userMessageBubble.addChildNode(userBGNode)
        targetMessageBubble.addChildNode(targetMessageNode)
        targetMessageBubble.addChildNode(targetBGNode)
        
        self.scene.rootNode.addChildNode(userMessageBubble)
        self.scene.rootNode.addChildNode(targetMessageBubble)
        
        userMessageBubble.runAction(show)
        targetMessageBubble.runAction(show)
        
        let hide = SCNAction.fadeOut(duration: 0.25)
        let timer = Timer.scheduledTimer(withTimeInterval: 3.3, repeats: true) { timer in
            userMessageBubble.runAction(hide)
            targetMessageBubble.runAction(hide)
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
        if (d <= 0.15 && AppState.getBuildingCurrentFloor().floorLevel == AppState.getDestinationLevel().level) {
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
        if (d <= 0.66 && AppState.getBuildingCurrentFloor().floorLevel == AppState.getDestinationLevel().level) {
            return true
        }
        else {
            return false
        }
    }
    
    func leftOrRight(userX: Float, userY: Float, front: simd_float3) -> String {
        
        let userToLocVector = simd_float3(pinX - userX, pinY - userY, 1)
        let userFrontVector = simd_float3(front.x, front.y, 1)
        let normalVector = simd_float3(0, 0, 1)
        var vectorAngle = acos(simd_dot(simd_normalize(userToLocVector), simd_normalize(userFrontVector)))
        let vectorCross = simd_cross(userToLocVector, userFrontVector)
        
        if (simd_dot(normalVector, vectorCross) < 0) {
            vectorAngle *= -1
        }
        
        if (abs(vectorAngle) <= 0.30) {
            return "on your front"
        } else {
            if (vectorAngle < -0.30) {
                return "to your left"
            } else if (vectorAngle > 0.30) {
                return "to your right"
            }
        }
        return ""
    }
    
    /*
     ====================================================================================================
     ~ RECALIBRATION SUBFUNCTION ~
     ====================================================================================================
     */
    @IBAction func startCalibration(_ sender: UIBarButtonItem) {
        if (self.recalibrationViewIsDisplayed) {
            self.stopCaptureSession()
            self.startSensors()
        } else {
            self.recalibrationView.isHidden = false
            self.view.bringSubviewToFront(self.recalibrationView)
            
            // Stop sensors
            self.stopSensors(withAltimeter: false)
            self.captureSession.startRunning()
            UIView.animate(withDuration: 0.3, animations: {
                self.recalibrationView.alpha = 1.0
            }, completion: { (isComplete: Bool) -> Void in
                // self.scannerView.isUserInteractionEnabled = true
                self.captureSession.startRunning()
                sender.title = "Cancel"
                sender.image = UIImage(named: "RecalibrateCancel")
                sender.tintColor = UIColor.red
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
            self.view.sendSubviewToBack(self.recalibrationView)
            self.calibrateButton.title = "Calibrate"
            self.calibrateButton.image = UIImage(named: "Recalibrate")
            self.calibrateButton.tintColor = self.view.tintColor
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
            promptMessage = "You are currently on the \(Utilities.ordinalize(qrCodeFloorLevel, AppState.getBuilding().hasLGF, abbv: false)). Your position has been fixed."
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
            self.resetAltimeter(pan: false)
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
        
        camera.position = SCNVector3(camera.position.x + Float(translation.x / 200), camera.position.y + Float(translation.y / 200), camera.position.z)
        
        sender.setTranslation(CGPoint.zero, in: self.navigationView)
    }
    
    @IBAction func viewIsPinched(_ sender: UIPinchGestureRecognizer) {
        let camera = self.navigationView.pointOfView!
        
        if (sender.velocity < 0) {
            camera.position.z += Float(sender.scale / 35)
        } else if (sender.velocity > 0) {
            camera.position.z -= Float(sender.scale / 35)
        }
        
        if (camera.position.z < 1.05) {
            camera.position.z = 1.05
        } else if (camera.position.z > 2.00) {
            camera.position.z = 2.00
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

extension NavigationController {
    enum LevelChange {
        case up, down, none
    }
}
