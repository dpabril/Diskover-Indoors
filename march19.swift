// <NEW 7>
// in NavigationController.swift : Pan gesture recognizer for single-touch camera panning

// var panGestureRecognizer = UIPanGestureRecognizer()

// override func viewDidLoad() {
//     self.panGestureRecognizer.minimumNumberOfTouches = 1
//     self.panGestureRecognizer.maximumNumberOfTouches = 1
//     self.view.addGestureRecognizer(self.panGestureRecognizer)
// }

@IBAction func viewIsPanned(_ sender: UIPanGestureRecognizer) {
    let velocity = sender.velocity(in: self.view)
    // print(velocity)
    let velocityXScaled = velocity.x / 100
    let velocityYScaled = velocity.y / 100

    let camera = self.navigationScene.pointOfView!
    let userMarker = self.scene.rootNode.childNode(withName: "UserMarker", recursively: true)!

    if (sender.state == .began) {
        // Pause sensors
        self.stopSensors()
    } elsif (sender.state == .changed) {
        camera.position = SCNVector3(camera.position.x + velocityXScaled, camera.position.y + velocityYScaled, camera.position.z)
    } elsif (sender.state == .ended) {
        let cameraPanAnimation = CABasicAnimation(keyPath: "position")
        cameraPanAnimation.fromValue = camera.position
        cameraPanAnimation.toValue = SCNVector3(userMarker.position.x, userMarker.position.y, camera.position.z)
        camera.addAnimation(cameraPanAnimation)
        camera.position = SCNVector3(userMarker.position.x, userMarker.position.y, camera.position.z)

        // Restart sensors
        self.startSensors()
    }
    sender.setTranslation(CGPoint.zero, in: self.view)
}

