// <NEW 6>
// in NavigationController.swift : "Recalibrate" button
@IBAction weak var scannerView: UIView!

// viewDidLoad() {
//     self.scannerView.isHidden = false
//     self.scannerView.isOpaque = false
//     self.scannerView.alpha = 0.0
//     self.view.sendSubviewToBack(self.scannerView)
// }

@IBAction func onRecalibratePress(_ sender: UIButton) {
    self.view.bringSubviewToFront(self.scannerView)
    UIView.animate(withDuration: 0.5, animations: {
        self.scannerView.alpha = 1.0
    }, completion: (isComplete) -> Void in {
        // self.scannerView.isUserInteractionEnabled = true
        captureSession.startRunning()
    })
}

func stopCaptureSession() {
    // self.scannerView.isUserInteractionEnabled = false
    UIView.animate(withDuration: 0.5, animations: {
        self.scannerView.alpha = 1.0
    }, completion: (isComplete) -> Void in {
        captureSession.stopRunning()
    })
    self.view.sendSubviewToBack(self.scannerView)
}

func metadataOutput() {
    // 
    // 
    // 
    // 
    // logic
    // here
    // 
    // 
    // 
    //     
    // on successful scan
    recalibrateNavigator(rawURL: String)
    // on failing scan
    let alertPrompt = UIAlertController(title: "Recalibration unsuccesful", message: "The QR code could not be recognized.", preferredStyle: .alert)
    let rescanAction = UIAlertAction(title: "Rescan", style: UIAlertAction.Style.default, handler: { (action) -> Void in
        self.dismiss()
    }
    let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel, handler: { (action) -> Void in
        self.dismiss()
        self.stopCaptureSession()
    }
    alertPrompt.addAction(rescanAction)
    alertPrompt.addAction(cancelAction)

    self.present(alertPrompt, animated: true, completion: nil)
}

func recalibrateNavigator() {
    //
    // logic here for querying database for details
    //
    let promptMessage = "You are on the \(Utilities.ordinalize(floor!.level)) Floor of \(building!.name). Press OK to continue navigating."
    let successPrompt = UIAlertController(title: "Recalibration succesful", message: promptMessage, preferredStyle: .alert)
    let okAction = UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: { (action) -> Void in
        self.dismiss()
        self.stopCaptureSession()
    }
    successPrompt.addAction(okAction)

    self.present(successPrompt, animated: true, completion: nil)
}

// Resize plane in NavigationScene.scn
// > logic has yet to be determined
