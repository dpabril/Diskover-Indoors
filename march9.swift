// <NEW 1>
// in NavigationController.swift : "Recalibrate" / "Pause" button
@IBAction func onClick(_ sender: UIButton, forEvent event: UIEvent) { 
    self.stopSensors()
    captureSession.start()
}

// <NEW 2>
// in NavigationController.swift : "Recalibration" subview
// > add AVCaptureMetadataOutputObjectsDelegate parent class to NavigationController
// > replace 'view' UIViewController instance variable with 'cameraView' as defined below
// > copy metadataOutput function, rename launchNavigator -> recalibrateNavigator
// > upon successful scan, call function to dismiss UIAlertController and do captureSession.stop()
let recalibrationPrompt = UIAlertController(title: "Recalibrate position", message: "Scan a nearby QR code to recalibrate your position.", preferredStyle: .actionSheet)

let cameraView = UIView(frame: CGRect(x: 10, y: 50, width: 250, height: 230))
recalibrationPrompt.view.addSubview(imageView)

let height = NSLayoutConstraint(item: recalibrationPrompt.view, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 330)
let width = NSLayoutConstraint(item: recalibrationPrompt.view, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 250)
recalibrationPrompt.view.addConstraint(height)
recalibrationPrompt.view.addConstraint(width)

let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel, handler: { (action) -> Void in
    self.startSensors()
})
recalibrationPrompt.addAction(cancelAction)

// <NEW 3>
// in NavigationController.swift : Reposition camera (add button for this)
// > in viewWillAppear, set camera to hover over user marker
@IBAction func onRecenterPress(_ sender: UIButton, forEvent event: UIEvent) { 
    let camera = self.scene.rootNode.childNode(withName: "sceneCamera", recursively: true)!
    let userMarker = self.scene.rootNode.childNode(withName: "UserMarker", recursively: true)!
    let cameraPanAnimation = CABasicAnimation(keyPath: "position")
    cameraPanAnimation.fromValue = camera.position
    cameraPanAnimation.toValue = SCNVector3(userMarker.position.x, userMarker.position.y, camera.position.z)
    cameraPanAnimation.duration = 2.00
    cameraPanAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
    // cameraPanAnimation.removedOnCompletion = NO
    camera.addAnimation(cameraPanAnimation, forKey: nil)
    camera.position = SCNVector3(userMarker.position.x, userMarker.position.y, camera.position.z)
    // camera.removeAllAnimations()
}

// NEW 4
// in NavigationController.swift : FUNCTION > Pan camera to target and then to user
// > call function when selecting location and/or when reaching floor of selected location
let camera = self.scene.rootNode.childNode(withName: "sceneCamera", recursively: true)!
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
panFromCamToTarget.duration = 2.00
panFromCamToTarget.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
panFromCamToTarget.beginTime = 0.00

// camera.position = SCNVector3(targetMarker.position.x, targetMarker.position.y, camera.position.z)

let panFromTargetToUser = CABasicAnimation(keyPath: "position")
panFromTargetToUser.fromValue = SCNVector3(targetMarker.position.x, targetMarker.position.y, camera.position.z)
// panFromTargetToUser.fromValue = camera.position
panFromTargetToUser.toValue = SCNVector3(userMarker.position.x, userMarker.position.y, camera.position.z)
panFromTargetToUser.duration = 2.00
panFromTargetToUser.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
panFromTargetToUser.beginTime = 3.00

let panAnimations = CAAnimationGroup()
panAnimations.animations = [panFromCamToTarget, panFromTargetToUser]
panAnimations.duration = 5.00

// panAnimations.removedOnCompletion = NO
camera.addAnimation(panAnimations, forKey: nil)
camera.position = SCNVector3(userMarker.position.x, userMarker.position.y, camera.position.z)
// camera.removeAllAnimations()



// <NEW 5>
// in NavigationController.swift : Panning camera with single-touch gesture
// > work on this